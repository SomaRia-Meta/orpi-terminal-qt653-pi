#!/bin/bash
# 从树莓派 rsync 一份根文件系统做 sysroot，并清掉系统 Qt 6.4（否则 find_package 会挑 6.4）。
# 用法: ./sdk/make-sysroot.sh raspberrypi@192.168.77.1 [输出目录]
set -euo pipefail
TARGET=${1:?用法: make-sysroot.sh user@host [outdir]}
OUT_DIR=${2:-$(cd "$(dirname "$0")/.." && pwd)/dist}
S="$OUT_DIR/pi-sysroot"
mkdir -p "$S"
rsync -a --delete \
  --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run --exclude=/tmp \
  --exclude=/home --exclude=/var --exclude=/boot --exclude=/media --exclude=/mnt \
  --exclude=/etc/ssh --exclude='*.log' \
  "$TARGET:/" "$S/"
# 清掉目标机系统 Qt 6.4，避免污染交叉编译
rm -rf "$S"/usr/lib/aarch64-linux-gnu/cmake/Qt6* "$S"/usr/lib/aarch64-linux-gnu/libQt6* \
       "$S"/usr/include/aarch64-linux-gnu/qt6 "$S"/usr/lib/aarch64-linux-gnu/qt6
# Debian 的 .so 常是绝对符号链接；改成相对，否则 CMake 会选中 .a 或跳出 sysroot
python3 - "$S" <<'PY'
import os,sys
root=sys.argv[1]; n=0
for dp,dn,fn in os.walk(root):
    for name in fn+dn:
        p=os.path.join(dp,name)
        if not os.path.islink(p): continue
        t=os.readlink(p)
        if not t.startswith('/'): continue
        rel=os.path.relpath(os.path.join(root,t.lstrip('/')), os.path.dirname(p))
        os.unlink(p); os.symlink(rel,p); n+=1
print(f"相对化符号链接: {n}")
PY
tar -C "$OUT_DIR" -c pi-sysroot | zstd -19 -T0 -o "$OUT_DIR/pi-sysroot.tar.zst" -f
sha256sum "$OUT_DIR/pi-sysroot.tar.zst" | tee "$OUT_DIR/pi-sysroot.tar.zst.sha256"
echo "产物: $OUT_DIR/pi-sysroot.tar.zst"

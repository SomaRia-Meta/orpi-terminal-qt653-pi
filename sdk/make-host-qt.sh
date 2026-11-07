#!/bin/bash
# 取得 host Qt 6.5.3 (x86_64)：优先 aqtinstall，其次重打包已有前缀。
# 交叉编译必须有 host 的 moc/rcc/uic/qmlcachegen —— 目标机 Qt 不带这些（也跑不了）。
# 用法: ./sdk/make-host-qt.sh [输出目录]
set -euo pipefail
OUT_DIR=${1:-$(cd "$(dirname "$0")/.." && pwd)/dist}
mkdir -p "$OUT_DIR"
NAME=orpi-host-qt-6.5.3-gcc_64

if command -v aqt >/dev/null 2>&1; then
  echo "使用 aqtinstall 下载官方 host Qt ..."
  aqt install-qt linux desktop 6.5.3 linux_gcc_64 -O "$OUT_DIR/aqt" --archives qtbase qtdeclarative qtdeclarative qtmultimedia qtspeech qtconnectivity qtserialport qtwebengine qtshadertools
  SRC="$OUT_DIR/aqt/6.5.3/gcc_64"
else
  SRC=${ORPI_HOST_QT:-/opt/Qt/6.5.3/gcc_64}
  echo "未找到 aqt，改为重打包 $SRC"
fi
[ -f "$SRC/bin/moc" ] || { echo "错误: $SRC/bin/moc 不存在；装 aqtinstall 或指定 ORPI_HOST_QT" >&2; exit 1; }
rm -rf "$OUT_DIR/$NAME"; mkdir -p "$OUT_DIR/$NAME"
cp -a "$SRC/." "$OUT_DIR/$NAME/"
tar -C "$OUT_DIR" -c "$NAME" | zstd -19 -T0 -o "$OUT_DIR/$NAME.tar.zst" -f
sha256sum "$OUT_DIR/$NAME.tar.zst" | tee "$OUT_DIR/$NAME.tar.zst.sha256"
echo "产物: $OUT_DIR/$NAME.tar.zst"

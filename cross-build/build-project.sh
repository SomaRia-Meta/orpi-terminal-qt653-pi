#!/bin/bash
# 用自建 Qt 6.5.3 aarch64 交叉编译 pi_terminal 项目。
set -euo pipefail
source "$(dirname "$0")/env.sh"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$REPO/src"
BUILD="$PROJ/pi_terminal/build-pi653"
JOBS="${JOBS:-12}"

cmake -S "$PROJ/pi_terminal" -B "$BUILD" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$(dirname "$0")/toolchain-pi653.cmake" \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DTERMINAL_REPAIR_AUDIT=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
  -DVLC_ROOT="$ORPI_SYSROOT/usr" -DSQLCIPHER_ROOT="$ORPI_SYSROOT/usr" \
  -DMBEDTLS_ROOT="$ORPI_SYSROOT/usr" -DOPENSSL_ROOT_DIR="$ORPI_SYSROOT/usr" \
  -DCMAKE_PREFIX_PATH="$ORPI_QT_PREFIX;$ORPI_SYSROOT/usr;$ORPI_SYSROOT/usr/lib/aarch64-linux-gnu/cmake" \
  -DQT_HOST_PATH="$ORPI_HOST_QT"

cmake --build "$BUILD" --parallel "$JOBS"

# DESTDIR 安装
rm -rf "$PROJ/pi-stage653"
DESTDIR="$PROJ/pi-stage653" cmake --install "$BUILD" --prefix /usr
echo "项目安装到：$PROJ/pi-stage653"

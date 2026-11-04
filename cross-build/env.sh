#!/bin/bash
# 交叉编译环境变量。按需修改下面几个路径。
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ORPI_HANDOVER_ROOT="${ORPI_HANDOVER_ROOT:-$(dirname "$REPO_ROOT")}"
export ORPI_SYSROOT="${ORPI_SYSROOT:-$ORPI_HANDOVER_ROOT/work/pi-sysroot}"
export ORPI_QT_PREFIX="${ORPI_QT_PREFIX:-$ORPI_HANDOVER_ROOT/work/qt653-arm64}"
export ORPI_HOST_QT="${ORPI_HOST_QT:-/opt/Qt/6.5.3/gcc_64}"
export ORPI_CROSS_PREFIX="${ORPI_CROSS_PREFIX:-/home/yuanzingo/pi-toolchain/aarch64-linux-gnu-}"
export ORPI_STUB="${ORPI_STUB:-$REPO_ROOT/cross-build/build/isoc23_compat.o}"
export PYTHONPATH="$REPO_ROOT/tools/pyshim:${PYTHONPATH:-}"
export PKG_CONFIG_SYSROOT_DIR="$ORPI_SYSROOT"
export PKG_CONFIG_LIBDIR="$ORPI_SYSROOT/usr/lib/pkgconfig:$ORPI_SYSROOT/usr/share/pkgconfig"
export PATH="$ORPI_HOST_QT/bin:$PATH"

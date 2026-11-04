# ORPI Terminal — Qt 6.5.3 aarch64 交叉编译与 Pi 部署

把 **Multi-Function-ESP32-Pi-Terminal** 的终端程序，从源码交叉编译到
**Raspberry Pi 3 / Debian 12 aarch64**，使用自建的 **Qt 6.5.3**（含 QtWebEngine），
并附完整的踩坑记录、构建脚本与可直接安装的交付包。

> 为什么不用 Pi 自带的 Qt 6.4.2：项目验证版本是 6.5.3，而 6.4.2 上主程序会崩在
> `QQuickLayouts`（`QGridLayoutItem::stretchFactor`）。Qt 官方 `linux_arm64`
> 在线仓库没有 6.5.3，所以走源码交叉编译。

## 仓库结构

```
├── src/                 项目源码（pi_terminal + third_party + module-devkit）
├── firmware/            ESP32 模块固件包（module-devkit、示例、烧录技能）
├── cross-build/         交叉编译链
│   ├── build-qt653.sh           Qt 6.5.3 配置+构建+安装
│   ├── build-project.sh         项目交叉编译
│   ├── make-deliverable.sh      生成 Pi 交付包
│   ├── patch-qt-build.py        GLIBC 2.36 兼容补丁注入（幂等）
│   ├── isoc23_compat.c          __isoc23_* 符号兼容桩
│   ├── toolchain-pi653.cmake    CMake 工具链
│   └── env.sh                   环境变量
├── deploy/              Pi 端 systemd/自启配置
├── docs/                部署说明、工作记录、问题与修复、Qt 源码改动
├── tools/pyshim/        Python 3.12 的 imp 垫片（Chromium 脚本需要）
└── artifacts/           预编译交付包（分卷，见其 README）
```

## 快速开始

### 构建（在 x86_64 Ubuntu 24.04 上）

```bash
# 0) 依赖与 sysroot 准备见 cross-build/README.md
export ORPI_SYSROOT=/path/to/pi-sysroot
export ORPI_HOST_QT=/opt/Qt/6.5.3/gcc_64
export ORPI_QT_PREFIX=/path/to/qt653-arm64
export ORPI_CROSS_PREFIX=/usr/bin/aarch64-linux-gnu-
export QT_SRC=/path/to/qt-everywhere-src-6.5.3

./cross-build/build-qt653.sh        # Qt 6.5.3（含 WebEngine）
./cross-build/build-project.sh      # 项目
./cross-build/make-deliverable.sh   # 出 dist/orpi-qt653-pi3.tar.zst
```

### 部署（Pi 上）

```bash
sudo tar -xf orpi-qt653-pi3.tar.zst -C /tmp
sudo bash /tmp/orpi-qt653-pi3/deploy-pi.sh          # 装 Qt 到 /opt/qt653-arm64 + 项目到 /usr
# 自启与全屏：见 deploy/README.md
```

## 已验证

- Pi 3B / Debian 12 / glibc 2.36 / 1024x600
- 窗口全屏 `1024x600+0+0`，QML 预缓存 `STARTUP_READY cacheReady=true`
- 所有 ELF 最高 GLIBC 需求 ≤ 2.35（项目二进制 2.34）
- 开机自启（`systemctl --user` + XDG autostart），重启后 51 秒内主程序已运行
- WebEngine Chromium 沙箱开启（无 `--no-sandbox`），systemd 沙箱属性全部生效

## 关键坑（详见 docs/问题与修复.md）

1. 符号链接 + `..` 路径穿越 → 改用 **bind mount**
2. 宿主 glibc 2.39 头/库优先 → **`__isoc23_*` 桩 + sysroot `-L`**，否则 Pi 上 `GLIBC_2.38 not found`
3. sysroot 缺 xcb 开发文件 → `FEATURE_xcb=OFF`，需补包并单独构建 qtbase
4. 旧 `libQt6Gui` 缺 `QX11Application` typeinfo → 用启用 xcb 的 Gui 替换（符号差集 0）
5. 缺 `libqxcb-egl-integration.so` → OpenGL 上下文创建失败、窗口不显示

## 许可

`src/` 与 `firmware/` 沿用原项目许可；本仓库新增的脚本与文档为 MIT。
`artifacts/` 内的二进制包由上述源码构建而来。

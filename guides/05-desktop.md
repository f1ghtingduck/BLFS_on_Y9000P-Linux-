# 阶段⑤：Xfce 桌面环境搭建

基于 Alpine 3.21 + Xorg + Xfce 4.18。

## 架构概览

```
Xfce 桌面 (xfdesktop + xfce4-panel)     ← 壁纸、面板、右键菜单
Xfce 窗口管理器 (xfwm4)                  ← 窗口边框、Alt+Tab、工作区
Xfce 会话管理 (xfce4-session)            ← 启动/保存会话
────────────────────────────────
GTK3 + 依赖 (glib/pango/cairo/atk)       ← GUI 零件库 (~80MB)
────────────────────────────────
Xorg (X11 显示服务)                      ← 屏幕、键盘、鼠标、显卡
────────────────────────────────
Linux 内核 (DRM/i915 驱动)               ← 硬件操作
```

## 安装步骤

### 1. 确认内核 DRM/显卡驱动

```bash
# 内核必须内置
zgrep -E 'CONFIG_DRM=|CONFIG_DRM_I915=|CONFIG_FB=' /proc/config.gz
# 实体机验证
ls /dev/dri/card0 /dev/dri/renderD128
```

必须输出两个设备节点。缺一 → 桌面无硬件加速。

### 2. 安装 Xorg（显示服务）

```bash
apk add xorg-server xinit xf86-input-libinput
apk add xf86-video-modesetting
```

> xf86-video-modesetting 是通用 KMS/DRM 驱动，兼容所有现代 GPU。
> 不装 xf86-video-intel（已废弃，与 modesetting 冲突）。

### 3. 安装 Xfce 桌面

```bash
# 核心三件（最小可启动）
apk add xfwm4 xfdesktop xfce4-panel xfce4-session

# 常用组件
apk add xfce4-terminal thunar xfce4-settings

# 字体和图标（关键！）
apk add ttf-dejavu adwaita-icon-theme

# 设备热插拔
apk add eudev
```

### 4. 创建启动配置

**~/.xinitrc**（Xorg 启动时读取）：

```sh
#!/bin/sh
dbus-daemon --system
exec xfce4-session
```

**/etc/X11/xorg.conf**（指定 modesetting 驱动）：

```
Section "Device"
    Identifier  "GPU"
    Driver      "modesetting"
EndSection
```

> 不加此配置 Xorg 可能选 fbdev（慢、无加速）。

### 5. Alpine rcS 配置

```sh
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts && mount -t devpts devpts /dev/pts
echo "nameserver 223.5.5.5" > /etc/resolv.conf

# 启动 udev 热插拔
/sbin/udevd &
sleep 1
/sbin/udevadm trigger 2>/dev/null
```

### 6. 启动桌面

```bash
startxfce4
# 或
startx
```

## 完整包清单

```bash
apk add \
  xorg-server xinit \
  xf86-input-libinput \
  xf86-video-modesetting \
  xfce4 xfce4-terminal xfce4-session \
  xfwm4 xfdesktop xfce4-panel thunar \
  ttf-dejavu adwaita-icon-theme \
  eudev dbus \
  mesa-dri-gallium \
  linux-firmware-i915
```

预计下载 ~150MB，安装后 ~400MB。

## 启动链

```
startxfce4
  → startx
    → xinit 读 ~/.xinitrc
      → Xorg 启动 (读 xorg.conf → modesetting_drv.so → DRM → /dev/dri/card0)
        → dbus-daemon --system
          → xfce4-session
            → xfwm4 (窗口管理器)
            → xfdesktop (桌面)
            → xfce4-panel (面板)
```

## QEMU 图形测试

```bash
qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
    -drive file=rootfs.img,if=virtio,format=raw \
    -m 1G -vga std -usb -device usb-tablet \
    -append "root=/dev/vda rw"
```

进 shell 后 `startxfce4`。

## ⚠️ 踩坑提醒

### 1. 键鼠完全不动
- 根因：缺 `xf86-input-libinput`
- 修复：`apk add xf86-input-libinput`

### 2. Xfce 卡死 / 文字不显示
- 根因：缺矢量字体（只有 Xorg 点阵字体）
- 修复：`apk add ttf-dejavu`

### 3. 图标无法显示
- 根因：缺图标主题
- 修复：`apk add adwaita-icon-theme`

### 4. 终端秒关闭
- 根因：`/dev/pts` 未挂载
- 修复：`mkdir -p /dev/pts && mount -t devpts devpts /dev/pts`

### 5. eudev 报 ENOSYS
- 根因：`CONFIG_INOTIFY_USER=n`
- 修复：开启 `CONFIG_INOTIFY_USER=y`

### 6. GPU wedged / 桌面渲染一半
- 根因 A：固件缺失（GuC/DMC）
- 修复 A：`apk add linux-firmware-i915`
- 根因 B：固件 .zst 内核无法解压
- 修复 B：`CONFIG_FW_LOADER_COMPRESS_ZSTD=y`
- 根因 C：`CONFIG_X86_PAT=n` → eDP-1 泄漏
- 修复 C：`CONFIG_MTRR=y` + `CONFIG_X86_PAT=y`

### 7. GLX extension missing
- 根因：缺 Mesa DRI 驱动
- 修复：`apk add mesa-dri-gallium`
- 注意：QEMU 中 GLX 不可用属正常——虚拟机无 GPU 加速

### 8. startx 黑屏 / No screens found
- 根因：xorg.conf 缺或指定错误驱动
- 修复：创建 `/etc/X11/xorg.conf` 指定 `modesetting`

### 9. dbus 未启动导致组件通信失败
- 根因：~/.xinitrc 缺 `dbus-daemon --system`
- 症状：面板、桌面、窗口管理器各自启动但互相不可见
- 修复：在 xinitrc 第一行加 `dbus-daemon --system`

### 10. 系统启动后屏幕卡在 logo 但键盘有响应
- 根因：`CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER=n` + i915 modeset 清屏
- 修复：开启该选项，同时 `CONFIG_X86_PAT=y`
- 详见 guides/07-gpu-fix.md

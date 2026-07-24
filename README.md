# MyLinux — 从零构建个人 Linux 操作系统

基于 Alpine Linux 3.21、Linux Kernel 7.2.0-rc3+、Xfce 桌面，
从内核编译到 U 盘启动，完整可复现的个人 Linux 构建工程。

## 硬件配置

| 组件 | 型号 |
|------|------|
| CPU | Intel Core i9-13900HX (13th Gen Raptor Lake) |
| GPU | Intel UHD (i915) + NVIDIA GeForce RTX 4060 Laptop |
| 内存 | 16GB DDR5 5600MT/s |
| 磁盘 | Samsung 1TB NVMe SSD |
| 网卡 | Intel Wi-Fi / 以太网 |
| 声卡 | Nahimic |
| 显示器 | 16.1" 2560x1600 (eDP-1) |

## 项目结构

```
linux-build/
├── README.md              # 项目总览（当前文件）
├── guides/                # 分步骤构建指南
│   ├── 01-initramfs.md    # 阶段①：initramfs + busybox
│   ├── 02-kernel.md       # 阶段②：内核配置与编译
│   ├── 03-rootfs.md       # 阶段③：Alpine rootfs + 包管理
│   ├── 04-network.md      # 阶段④：网络栈（USB 共享）
│   ├── 05-desktop.md      # 阶段⑤：Xfce 桌面环境
│   ├── 06-usb-boot.md     # 阶段⑥：U 盘启动 + GRUB
│   └── 07-gpu-fix.md      # 阶段⑦：GPU 显示修复
├── docs/                  # 参考文档
│   ├── hardware.md        # 硬件配置详情
│   ├── boot-chain.md      # 启动链完整说明
│   └── faq.md             # 常见问题
├── config/                # 核心配置文件
│   ├── kernel.config      # 当前内核 .config
│   ├── kernel-config.txt  # 内核编译选项详解
│   ├── dependency.txt     # 依赖关系全表
│   ├── grub.cfg           # GRUB 引导配置
│   └── initramfs-init     # initramfs /init 脚本
├── scripts/               # 部署脚本
│   ├── rebuild-grub.sh    # 重建 BOOTX64.EFI
│   └── deploy-usb.sh      # 一键部署到 U 盘
└── backup/                # 备份文件引用
    └── README.md          # 备份说明
```

## 构建指南（分步骤）

| 阶段 | 文件 | 内容 |
|------|------|------|
| ① initramfs | [01-initramfs.md](guides/01-initramfs.md) | busybox 编译 + /init 脚本 + cpio 打包 |
| ② 内核 | [02-kernel.md](guides/02-kernel.md) | 内核配置 + 编译 + QEMU 测试 |
| ③ rootfs | [03-rootfs.md](guides/03-rootfs.md) | Alpine minirootfs + apk 包管理 |
| ④ 网络 | [04-network.md](guides/04-network.md) | USB 手机共享网 + QEMU 网络 |
| ⑤ 桌面 | [05-desktop.md](guides/05-desktop.md) | Xfce 安装 + 配置 + 踩坑 10 条 |
| ⑥ U 盘 | [06-usb-boot.md](guides/06-usb-boot.md) | FAT32+ext4 分区 + GRUB UEFI |
| ⑦ GPU | [07-gpu-fix.md](guides/07-gpu-fix.md) | i915 显示修复 + PAT + 固件 |

每个指南末尾附 ⚠️ 踩坑提醒。

## 系统组件

| 组件 | 选择 | 说明 |
|------|------|------|
| C 库 | musl | Alpine 原生，轻量 |
| Shell | busybox ash | 内置 initramfs |
| Init 系统 | busybox init + Alpine rcS | 极简 |
| 设备管理 | eudev | 热插拔 |
| 网络 | USB RNDIS/CDC | 手机共享网 |
| 包管理 | apk (Alpine) | mirrors.aliyun.com |
| 桌面 | Xfce 4.18 | 轻量完整 |
| 显示 | Xorg + modesetting | i915 DRM |
| 引导 | GRUB2 UEFI | 内嵌配置 |

## 快速开始

### 构建内核

```bash
cd linux/
cp ../config/kernel.config .config
make olddefconfig && make -j$(nproc)
```

### QEMU 测试

```bash
qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
    -drive file=rootfs.img,if=virtio,format=raw \
    -m 1G -nographic -append "console=ttyS0 root=/dev/vda rw"
```

### 部署到 U 盘

```bash
sudo mount /dev/sdX1 /mnt/fat
sudo mount /dev/sdX2 /mnt/ext
sudo cp arch/x86/boot/bzImage /mnt/ext/boot/vmlinuz
scripts/rebuild-grub.sh
```

## 关键内核配置（#86）

CONFIG_X86_PAT + CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER
CONFIG_DRM_I915=y（内建）+ 固件 .bin 在 initramfs
CONFIG_MODULES=n（全内置）

详见 [config/kernel-config.txt](config/kernel-config.txt)

## 启动链

```
UEFI → FAT32:BOOTX64.EFI(GRUB) → search UUID → ext4:/boot/vmlinuz
     → 内核内嵌 initramfs → /init → findfs PARTUUID → mount ext4
     → switch_root → Alpine /sbin/init → rcS → tty shell
```

## 致谢

- Alpine Linux
- Linux From Scratch / BLFS
- Busybox
- Linux Kernel

## ⚠️ Disclaimer

The kernel configurations in this project are deeply customized for the Lenovo Legion Y9000P (2023).
For other laptop models, these configs should only be used as a reference.
Always review and adjust kernel options based on your specific hardware.

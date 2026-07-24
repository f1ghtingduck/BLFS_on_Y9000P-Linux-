# 启动链完整说明

```
UEFI 固件
  ↓ 扫描 ESP FAT32 找 EFI/BOOT/BOOTX64.EFI
GRUB (BOOTX64.EFI, 内嵌 grub.cfg)
  ↓ search -u <ext4_UUID> -s root → 定位 ext4 分区
  ↓ linux /boot/vmlinuz console=tty0 rw → 加载内核
内核 (vmlinuz = bzImage + 内嵌 cpio)
  ↓ 解包 cpio → 执行 /init
/init (busybox sh)
  ↓ mount dev/proc/sys → findfs PARTUUID=80dfe0da → mount ext4
  ↓ flush() 覆写 rcS/inittab/repos/net/xorg → sync → switch_root
Alpine /sbin/init (busybox init)
  ↓ 读 /etc/inittab → 执行 /etc/init.d/rcS
rcS
  ↓ mount dev/proc/sys/devpts → start udev → modprobe i915
tty shell (/bin/sh on tty1, tty2, ttyS0)
```

## UUID 区分

| 类型 | 值 | 位置 | 用途 |
|------|-----|------|------|
| ext4 UUID | e2f64443-... | mkfs 生成 | GRUB search |
| PARTUUID | 80dfe0da-... | GPT 分区表 | initramfs findfs |

## 关键参数传递

| 阶段 | 传递方式 | 值 |
|------|---------|-----|
| UEFI→GRUB | BOOTX64.EFI 内嵌 | grub.cfg |
| GRUB→Kernel | linux 命令行 | console=tty0 rw |
| Kernel→init | 内核内嵌 cpio | /init 脚本 |
| init→rootfs | switch_root | /sbin/init |

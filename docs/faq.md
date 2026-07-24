# 常见问题

## Q: Y9000P 开机卡在 Lenovo logo？

A: 系统实际在运行（可盲打 poweroff）。根因：CONFIG_X86_PAT 未开启导致 i915 eDP-1 泄漏。
   fix：开启 CONFIG_MTRR + CONFIG_X86_PAT + CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER。

## Q: kernel panic "找不到 init"？

A: initramfs cpio 缺 /bin/sh 符号链接。重建 busybox symlinks。

## Q: modprobe i915 失败？

A: 当前方案 CONFIG_MODULES=n，i915 内建不需要 modprobe。

## Q: 内核编译后 Y9000P 进不去？

A: 可能 cpio 没更新。确保：find | cpio → rm usr/initramfs_data.* → make。

## Q: ext4 I/O 错误？

A: 双挂载导致。QEMU 和宿主机不要同时访问 rootfs.img 或 U 盘 ext4。

## Q: GRUB 找不到 /boot/vmlinuz？

A: search UUID 可能旧了（mkfs 后变了）。blkid 查当前 UUID 更新 grub.cfg。

## Q: 启动到 GRUB 命令行不掉？

A: BOOTX64.EFI 没内嵌 grub.cfg 或 config 语法错误。重建 EFI。

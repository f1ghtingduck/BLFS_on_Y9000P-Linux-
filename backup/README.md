# 备份

完整备份文件：`mylinux_backup_20260722.tar.gz`（295MB）

## 内容

- vmlinuz: 内核 #86 (4.6M, PAT + DEFERRED_TAKEOVER)
- kernel.config: 完整内核配置
- initramfs/: 含 busybox + 固件 + init 脚本
- rootfs.img: 2GB, Alpine 3.21 + Xfce + 322 包
- grub.cfg: GRUB 配置
- rebuild_grub.sh: EFI 重建脚本
- USB_STRUCTURE.txt: 分区 UUID

## 恢复

```bash
tar xzf mylinux_backup_20260722.tar.gz
cd mylinux_backup_20260722
# 内核部署到 U 盘
sudo mount /dev/sdX2 /mnt/ext
sudo cp vmlinuz /mnt/ext/boot/
# rootfs
sudo mount rootfs.img /mnt/src && sudo rsync -a /mnt/src/ /mnt/ext/
```

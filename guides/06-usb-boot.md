# 阶段⑥：U 盘启动 + GRUB

## U 盘分区

```
/dev/sdX
├── sdX1 FAT32 300MB  EFI 分区
└── sdX2 ext4  117GB  根分区
```

## 格式化

```bash
sudo mkfs.vfat -F32 /dev/sdX1
sudo mkfs.ext4 -F /dev/sdX2
```

## 写入 rootfs

```bash
sudo mount /dev/sdX2 /mnt/ext
sudo rsync -aq rootfs/ /mnt/ext/
sudo mkdir -p /mnt/ext/boot
sudo cp arch/x86/boot/bzImage /mnt/ext/boot/vmlinuz
```

## GRUB 安装

```bash
sudo mount /dev/sdX1 /mnt/fat
sudo mkdir -p /mnt/fat/EFI/BOOT

cat > /tmp/grub.cfg << 'EOF'
search -u <EXT4_UUID> -s root
linux /boot/vmlinuz console=tty0 rw
boot
EOF

sudo grub-mkimage -O x86_64-efi -p /EFI/BOOT \
    -c /tmp/grub.cfg -o /mnt/fat/EFI/BOOT/BOOTX64.EFI \
    part_gpt fat ext2 normal search search_label search_fs_uuid \
    linux configfile all_video boot chain

sync && sudo umount /mnt/fat /mnt/ext
```

## GRUB 参数说明

| 参数 | 含义 |
|------|------|
| search -u UUID -s root | 找 ext4 分区，设为 GRUB root |
| linux /boot/vmlinuz | 加载 ext4 上的内核 |
| console=tty0 | fbcon 输出到显示 |
| rw | 根文件系统读写挂载 |
| (不传 root=) | 由 initramfs /init 自己找 |

## GRUB 模块说明

| 模块 | 提供 |
|------|------|
| part_gpt | GPT 分区表 |
| fat, ext2 | FAT32/ext4 文件系统 |
| search_fs_uuid | search -u 命令 |
| linux | 加载内核 |
| configfile | 加载外部 grub.cfg |
| boot | 启动 |
| chain | 链式引导 |

## ⚠️ 踩坑提醒

1. **UUID 会随 mkfs 变化** — 格盘后必须更新 grub.cfg
2. **部署三步验证**：mount 确认路径 → cp → md5sum 校验
3. **不要双挂载 ext4** — QEMU 和宿主机同时访问会损坏 fs
4. **sync 后再拔 U 盘** — 否则数据丢失
5. **PARTUUID 格式化不变** — initramfs 用它找分区

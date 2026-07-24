#!/bin/sh
# 在 FAT32 挂载到 /mnt/fat 后运行
cat > /tmp/grub.cfg << 'EOF'
search -u e2f64443-cd7a-44d3-8957-95b52283a4c2 -s root
linux /boot/vmlinuz console=tty0 rw
boot
EOF
sudo grub-mkimage -O x86_64-efi -p /EFI/BOOT -c /tmp/grub.cfg -o /mnt/fat/EFI/BOOT/BOOTX64.EFI part_gpt fat ext2 normal search search_label search_fs_uuid linux configfile all_video boot chain

# 硬件配置

## 宿主机（开发环境）

| 组件 | 配置 |
|------|------|
| 类型 | VMware 虚拟机 |
| OS | Ubuntu 24.04 LTS |
| CPU | QEMU Virtual 2.5+ |
| 内存 | 8GB |
| 磁盘 | 40GB |

## 目标机（实体机）

| 组件 | 型号 |
|------|------|
| 型号 | Lenovo Legion Y9000P (2023) |
| CPU | Intel Core i9-13900HX (13th Gen Raptor Lake-S) |
| iGPU | Intel UHD Graphics (i915, device ID a788) |
| dGPU | NVIDIA GeForce RTX 4060 Laptop 8GB |
| 内存 | 16GB DDR5 5600MT/s |
| 磁盘 | Samsung 1TB NVMe SSD (PCIe 4.0) |
| 显示器 | 16.1" 2560x1600 eDP-1 |
| 网卡 | Intel Wi-Fi 6E + 2.5GbE 以太网 |
| 声卡 | Nahimic |
| 电池 | 80Wh |
| U 盘 | Lenovo thinkplus 128GB (USB-A) |

## U 盘分区

```
/dev/sdX (117GB)
├── sdb1 FAT32 300MB (EFI 分区)
│   └── EFI/BOOT/BOOTX64.EFI (GRUB)
└── sdb2 ext4 116.9GB (根分区)
    ├── /boot/vmlinuz (内核)
    └── /lib/firmware/i915/ (固件)
```

UUID/PARTUUID:
- ext4 UUID: e2f64443-cd7a-44d3-8957-95b52283a4c2
- ext4 PARTUUID: 80dfe0da-e6fe-41e4-9b79-3ced2dce3994
- FAT32 UUID: (如有)

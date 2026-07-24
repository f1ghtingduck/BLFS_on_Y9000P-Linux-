# 阶段①：initramfs 搭建

构建最小 initramfs，包含 busybox + /init 脚本。

## busybox 编译

```bash
git clone https://git.busybox.net/busybox
cd busybox && git checkout 1_36_1
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make -j$(nproc)
```

## initramfs 目录结构

```
initramfs/
├── init                      # /init 入口脚本
├── bin/busybox               # 静态编译的 busybox
├── bin/sh -> busybox         # shell（必须！）
├── sbin/init -> ../bin/busybox
├── dev/ proc/ sys/           # 挂载点
└── etc/                      # 配置文件
```

## /init 脚本

```sh
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /new_root

# QEMU
mount -t ext4 /dev/vda /new_root 2>/dev/null && exec switch_root /new_root /sbin/init
# 实体机
sleep 5
ROOTDEV=$(findfs PARTUUID=80dfe0da-e6fe-41e4-9b79-3ced2dce3994 2>/dev/null)
[ -n "$ROOTDEV" ] && mount -t ext4 $ROOTDEV /new_root && exec switch_root /new_root /sbin/init
# fallback
for dev in sdc2 sdb2 sda2 sdd2; do
    mount -t ext4 /dev/$dev /new_root && exec switch_root /new_root /sbin/init
done
exec /bin/sh
```

## 打包 + 嵌入内核

```bash
cd initramfs && find . | cpio -o -H newc > ../initramfs.cpio
# 设置 CONFIG_INITRAMFS_SOURCE="/path/to/initramfs.cpio"
```

## ⚠️ 踩坑提醒

1. **busybox symlink 必须存在** — `bin/sh -> busybox`，否则 `#!/bin/sh` 失败
2. **每次改 init 后必须**：重建 cpio → 删 .o → 重编内核
3. **cpio 路径要绝对路径** — CONFIG_INITRAMFS_SOURCE 用绝对路径
4. **不要在 /tmp 下建 cpio** — 会被清理
5. **devtmpfs 必须先挂** — mount/findfs 依赖 /dev 节点

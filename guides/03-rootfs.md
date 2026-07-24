# 阶段③：Alpine RootFS + 包管理

使用 Alpine Linux 3.21 minirootfs 作为根文件系统基础。

## Alpine minirootfs 获取

```bash
wget https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-minirootfs-3.21.0-x86_64.tar.gz
```

## 创建 rootfs 镜像

```bash
truncate -s 2G rootfs.img
mkfs.ext4 -F rootfs.img
sudo mount rootfs.img /mnt
sudo tar xzf alpine-minirootfs-3.21.0-x86_64.tar.gz -C /mnt
```

## 基础配置

### /etc/inittab
```
::sysinit:/etc/init.d/rcS
tty1::respawn:/bin/sh
tty2::respawn:/bin/sh
ttyS0::respawn:/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::restart:/sbin/init
```

### /etc/init.d/rcS
```sh
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts && mount -t devpts devpts /dev/pts
echo "nameserver 223.5.5.5" > /etc/resolv.conf
```

### /etc/apk/repositories
```
https://mirrors.aliyun.com/alpine/v3.21/main
https://mirrors.aliyun.com/alpine/v3.21/community
```

## 包管理

```bash
apk update                # 刷新索引
apk add <pkg>             # 安装
apk search <keyword>       # 搜索
apk info <pkg>             # 查看包信息
```

QEMU 中联网：`ip link set eth0 up && udhcpc -i eth0`

## QEMU 测试

```bash
qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
    -drive file=rootfs.img,if=virtio,format=raw \
    -m 1G -nographic -nic user,model=e1000 \
    -append "console=ttyS0 root=/dev/vda rw"
```

## ⚠️ 踩坑提醒

1. **Alpine minirootfs 缺 /etc/init.d 目录** — 需手动 mkdir 创建
2. **apk 数据库损坏** — /etc/apk/world 断链导致 "No such file"。rm 重建
3. **源用 mirrors.aliyun.com** — dl-cdn 在部分网络 DNS 阻断
4. **ping 不通但 apk 能下** — QEMU 用户模式网络不转发 ICMP，正常
5. **不要在宿主机和 QEMU 同时挂载 rootfs.img** — ext4 必损坏

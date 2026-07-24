# 阶段④：网络栈（USB 手机共享）

## 内核配置

```
CONFIG_NET=y → CONFIG_INET=y → CONFIG_PACKET=y → CONFIG_UNIX=y
CONFIG_USB_USBNET=y → CONFIG_USB_NET_RNDIS_HOST=y (Android)
                    → CONFIG_USB_NET_CDCETHER=y   (iPhone)
                    → CONFIG_USB_NET_CDC_NCM=y
CONFIG_E1000=y  (QEMU 虚拟网卡)
```

## USB 手机共享（Y9000P 实体机）

### 固定参数

```
接口: usb0
本机: 192.168.42.172/24
网关: 192.168.42.129
DNS:  223.5.5.5（阿里 DNS）
```

### 手动配网

```bash
ip addr add 192.168.42.172/24 dev usb0
ip link set usb0 up
ip route add default via 192.168.42.129
echo "nameserver 223.5.5.5" > /etc/resolv.conf
```

### 网络启动脚本 `/etc/init.d/net`

```sh
#!/bin/sh
ip addr add 192.168.42.172/24 dev usb0
ip link set usb0 up
ip route add default via 192.168.42.129
echo "nameserver 223.5.5.5" > /etc/resolv.conf
```

开机后执行 `/etc/init.d/net` 即联网。

## QEMU 网络

```bash
# QEMU 参数
-nic user,model=e1000

# 虚拟机内
ip link set eth0 up && udhcpc -i eth0
# IP: 10.0.2.15, 网关: 10.0.2.2
```

## ⚠️ 踩坑提醒

1. **busybox ifconfig 报 "bad address"** — 改用 `ip addr add`
2. **busybox route 不支持 gw 关键字** — 改用 `ip route add default via`
3. **dl-cdn.alpinelinux.org NXDOMAIN** — 手机 DNS 阻断，换 223.5.5.5
4. **usb0 不出现** — 检查 CONFIG_USB_USBNET 和相关子选项全 =y
5. **busybox wget 被镜像反爬** — 加 `-U "a"` 伪装 User-Agent

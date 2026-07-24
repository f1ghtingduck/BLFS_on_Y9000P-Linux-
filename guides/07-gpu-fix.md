# 阶段⑦：GPU 显示修复

## 问题

i915 初始化后屏幕卡在 Lenovo logo，fbcon 不输出。

## 根因

三连：
1. CONFIG_X86_PAT=n → i915 内存分配失败 → eDP-1 connector leaked
2. CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER=n → fbcon 抢在 i915 前绑定
3. 固件缺失 → GPU wedged

## 修复

### 1. 内核配置

```
CONFIG_MTRR=y
CONFIG_X86_PAT=y
CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER=y
```

### 2. 固件放入 initramfs

```bash
cd initramfs
mkdir -p lib/firmware/i915
wget -O lib/firmware/i915/tgl_guc_70.bin https://git.kernel.org/.../i915/tgl_guc_70.bin
wget -O lib/firmware/i915/adls_dmc_ver2_01.bin https://git.kernel.org/.../i915/adls_dmc_ver2_01.bin
```

### 3. GRUB 最小参数

```grub
linux /boot/vmlinuz console=tty0 rw
```

不需要 video=efifb:off, fbcon=nodefer, i915.fastboot 等参数。

## ⚠️ 踩坑提醒

1. **X86_PAT 依赖 MTRR** — 必须两个都开
2. **固件文件名要精确** — 13代 Raptor Lake 用 adls_dmc + tgl_guc
3. **initramfs 放固件后内核变大** — 4.5M→4.6M，正常
4. **GuC log buffer -19 不影响显示** — 可以忽略
5. **DMC 成功但 HuC 失败不影响** — HuC 是视频编解码

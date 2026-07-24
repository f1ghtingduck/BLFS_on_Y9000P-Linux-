# 阶段②：内核配置与编译

基于 Linux 7.2.0-rc3+ 主线内核。

## 源码获取

```bash
cd /home/millard
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
```

## 配置内核

参考 `config/kernel.config`（完整 .config）或 `config/kernel-config.txt`（关键项）。

### 一键配置

```bash
# 从项目配置恢复
cp ../config/kernel.config .config
make olddefconfig

# 或用 scripts/config 逐项设置
./scripts/config --enable CONFIG_EXT4_FS
./scripts/config --enable CONFIG_DRM_I915
# ... 更多见 config/kernel-config.txt
```

## 编译

```bash
# 每次改 initramfs 后：
cd initramfs && find . | cpio -o -H newc > ../initramfs.cpio
cd linux && rm -f usr/initramfs_data.cpio usr/initramfs_data.o
make -j$(nproc)
```

## QEMU 测试

```bash
qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
    -drive file=rootfs.img,if=virtio,format=raw \
    -m 1G -nographic -append "console=ttyS0 root=/dev/vda rw"
```

## ⚠️ 踩坑提醒

1. **改 initramfs 后必须删 .o** — 否则嵌旧 cpio
2. **BLK_DEV_SD 必须 =y** — SCSI 识别 USB 磁盘但不创建 /dev/sd*
3. **FW_LOADER_COMPRESS_ZSTD 必须 =y** — Alpine 固件 .zst
4. **INOTIFY_USER 必须 =y** — eudev 需要
5. **X86_PAT 依赖 MTRR** — 必须同时开启，否则 eDP-1 泄漏
6. **cpio 太大可能失败** — 固件 .bin 建议放 ext4 非 initramfs
7. **不要 make clean 后直接 make** — 可能丢 arch/x86/boot/compressed/

mkdir -p /home/jaokhun/Projects/Depth/boot
ISO_STAGING=/tmp/depth_iso_staging
rm -rf "$ISO_STAGING"
mkdir -p "$ISO_STAGING"/isolinux "$ISO_STAGING"/boot

cp -f /boot/vmlinuz-linux "$ISO_STAGING"/boot/vmlinuz
cp -f /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img "$ISO_STAGING"/boot/initrd.img

cp -f /home/jaokhun/Projects/Depth/boot/isolinux/isolinux.bin "$ISO_STAGING"/isolinux/
cp -f /home/jaokhun/Projects/Depth/boot/isolinux/ldlinux.c32 "$ISO_STAGING"/isolinux/
cp -f /home/jaokhun/Projects/Depth/boot/isolinux/libcom32.c32 "$ISO_STAGING"/isolinux/
cp -f /home/jaokhun/Projects/Depth/boot/isolinux/libutil.c32 "$ISO_STAGING"/isolinux/

cat << 'EOF' > "$ISO_STAGING"/isolinux/isolinux.cfg
DEFAULT depth
PROMPT 0
TIMEOUT 10

LABEL depth
  LINUX /boot/vmlinuz
  INITRD /boot/initrd.img
  APPEND console=ttyS0 console=tty0 loglevel=7 ignore_loglevel net.ifnames=0 biosdevname=0 panic=1 rdinit=/init
EOF

genisoimage -rational-rock -volid "DEPTH_HINUX" \
  -cache-inodes -joliet -full-iso9660-filenames \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -o /home/jaokhun/Projects/Depth/boot/depth-hinux.iso "$ISO_STAGING"

rm -rf "$ISO_STAGING"

python3 - << 'PYEOF'
import os, struct

iso_path = "/home/jaokhun/Projects/Depth/boot/depth-hinux.iso"
mbr_path = "/home/jaokhun/Projects/Depth/boot/depth-boot.bin"

if os.path.exists(iso_path) and os.path.exists(mbr_path):
    size = os.path.getsize(iso_path)
    total_sectors = size // 512
    with open(mbr_path, "rb") as f:
        mbr = bytearray(f.read()[:512])
    if len(mbr) < 512:
        mbr.extend(b"\x00" * (512 - len(mbr)))
    mbr[446] = 0x80
    mbr[447:450] = b"\x00\x01\x00"
    mbr[450] = 0x17
    mbr[451:454] = b"\xff\xff\xff"
    struct.pack_into("<I", mbr, 454, 0)
    struct.pack_into("<I", mbr, 458, total_sectors)
    mbr[510] = 0x55
    mbr[511] = 0xAA
    with open(iso_path, "r+b") as f:
        f.seek(0)
        f.write(mbr)
PYEOF

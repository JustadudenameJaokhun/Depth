BOOT_ARCH="${BOOT_ARCH:-gpt}"
mkdir -p /home/jaokhun/Projects/Depth/boot
ISO_STAGING=/tmp/depth_iso_staging
rm -rf "$ISO_STAGING"
mkdir -p "$ISO_STAGING"/boot

cp -f /boot/vmlinuz-linux "$ISO_STAGING"/boot/vmlinuz
cp -f /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img "$ISO_STAGING"/boot/initrd.img

if [ "$BOOT_ARCH" = "mbr" ]; then
    cp -f /home/jaokhun/Projects/Depth/boot/depth-boot.bin "$ISO_STAGING"/boot/depth-boot.bin

    genisoimage -rational-rock -volid "DEPTH_HINUX" \
      -cache-inodes -joliet -full-iso9660-filenames \
      -b boot/depth-boot.bin -c boot/boot.cat \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      -o /home/jaokhun/Projects/Depth/boot/depth-hinux.iso "$ISO_STAGING"

    rm -rf "$ISO_STAGING"

    python3 - << 'PYEOF'
import os, struct

iso_path = "/home/jaokhun/Projects/Depth/boot/depth-hinux.iso"
mbr_path = "/home/jaokhun/Projects/Depth/boot/depth-boot.bin"

if os.path.exists(iso_path) and os.path.exists(mbr_path):
    with open(iso_path, "r+b") as f:
        f.seek(16 * 2048)
        pvd = f.read(2048)
        root_rec = pvd[156:156+34]
        root_lba = struct.unpack_from('<I', root_rec, 2)[0]
        root_size = struct.unpack_from('<I', root_rec, 10)[0]
        f.seek(root_lba * 2048)
        rdir = f.read(root_size)
        boot_lba = 0
        pos = 0
        while pos < len(rdir):
            rlen = rdir[pos]
            if rlen == 0: pos += 1; continue
            rec = rdir[pos:pos+rlen]
            flba = struct.unpack_from('<I', rec, 2)[0]
            namelen = rec[32]
            name = rec[33:33+namelen].decode('ascii', 'ignore')
            if name == 'BOOT': boot_lba = flba; break
            pos += rlen
        
        f.seek(boot_lba * 2048)
        bdir = f.read(2048)
        pos = 0
        k_lba = 0; k_size = 0; i_lba = 0; i_size = 0; b_lba = 0
        while pos < len(bdir):
            rlen = bdir[pos]
            if rlen == 0: pos += 1; continue
            rec = bdir[pos:pos+rlen]
            flba = struct.unpack_from('<I', rec, 2)[0]
            fsize = struct.unpack_from('<I', rec, 10)[0]
            namelen = rec[32]
            name = rec[33:33+namelen].decode('ascii', 'ignore')
            if 'VMLINUZ' in name: k_lba = flba; k_size = fsize
            elif 'INITRD' in name: i_lba = flba; i_size = fsize
            elif 'DEPTH-BOOT' in name or 'DEPTH_BO' in name: b_lba = flba
            pos += rlen

        k_sec = (k_size + 2047) // 2048
        i_sec = (i_size + 2047) // 2048

        f.seek(b_lba * 2048 + 64)
        patch = struct.pack('<IIIIII', k_lba, k_sec, k_size, i_lba, i_sec, i_size)
        f.write(patch)

        size = os.path.getsize(iso_path)
        total_sectors = size // 512
        with open(mbr_path, "rb") as mf:
            mbr = bytearray(mf.read()[:512])
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
        f.seek(0)
        f.write(mbr)
PYEOF

else
    EFI_IMG=/home/jaokhun/Projects/Depth/boot/efiboot.img
    rm -f "$EFI_IMG"
    INITRD_SZ=$(stat -c%s /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img 2>/dev/null || echo 60000000)
    KERN_SZ=$(stat -c%s /boot/vmlinuz-linux 2>/dev/null || echo 20000000)
    REQ_MB=$(( (INITRD_SZ + KERN_SZ) / 1048576 + 64 ))
    dd if=/dev/zero of="$EFI_IMG" bs=1M count="$REQ_MB" 2>/dev/null
    mkfs.vfat -F 32 -n "DEPTH_EFI" "$EFI_IMG" >/dev/null 2>&1
    mmd -i "$EFI_IMG" ::EFI
    mmd -i "$EFI_IMG" ::EFI/BOOT
    mmd -i "$EFI_IMG" ::loader
    mmd -i "$EFI_IMG" ::loader/entries
    mmd -i "$EFI_IMG" ::boot

    mcopy -i "$EFI_IMG" /usr/lib/systemd/boot/efi/systemd-bootx64.efi ::EFI/BOOT/BOOTX64.EFI
    mcopy -i "$EFI_IMG" /boot/vmlinuz-linux ::boot/vmlinuz
    mcopy -i "$EFI_IMG" /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img ::boot/initrd.img

    python3 - << 'PYEOF'
loader_conf = "default depth.conf\ntimeout 1\nconsole-mode max\n"
depth_conf = "title Depth Hinux (UEFI GPT)\nlinux /boot/vmlinuz\ninitrd /boot/initrd.img\noptions console=ttyS0 console=tty0 loglevel=7 ignore_loglevel net.ifnames=0 biosdevname=0 panic=1 rdinit=/init\n"
with open("/tmp/depth_loader.conf", "w") as f:
    f.write(loader_conf)
with open("/tmp/depth_entry.conf", "w") as f:
    f.write(depth_conf)
PYEOF

    mcopy -i "$EFI_IMG" /tmp/depth_loader.conf ::loader/loader.conf
    mcopy -i "$EFI_IMG" /tmp/depth_entry.conf ::loader/entries/depth.conf

    mkdir -p "$ISO_STAGING"/EFI/BOOT "$ISO_STAGING"/loader/entries
    cp -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi "$ISO_STAGING"/EFI/BOOT/BOOTX64.EFI
    cp -f /tmp/depth_loader.conf "$ISO_STAGING"/loader/loader.conf
    cp -f /tmp/depth_entry.conf "$ISO_STAGING"/loader/entries/depth.conf

    rm -f /tmp/depth_loader.conf /tmp/depth_entry.conf

    cp -f "$EFI_IMG" "$ISO_STAGING"/boot/efiboot.img

    genisoimage -rational-rock -volid "DEPTH_HINUX" \
      -cache-inodes -joliet -full-iso9660-filenames \
      -c boot/boot.cat \
      -eltorito-platform 0xEF -b boot/efiboot.img \
      -no-emul-boot \
      -o /home/jaokhun/Projects/Depth/boot/depth-hinux.iso "$ISO_STAGING"

    rm -rf "$ISO_STAGING"

    python3 - << 'PYEOF'
import os, struct, uuid, zlib

iso_path = "/home/jaokhun/Projects/Depth/boot/depth-hinux.iso"
if os.path.exists(iso_path):
    with open(iso_path, "r+b") as f:
        f.seek(16 * 2048)
        pvd = f.read(2048)
        root_rec = pvd[156:156+34]
        root_lba = struct.unpack_from('<I', root_rec, 2)[0]
        root_size = struct.unpack_from('<I', root_rec, 10)[0]
        f.seek(root_lba * 2048)
        rdir = f.read(root_size)
        boot_lba = 0
        pos = 0
        while pos < len(rdir):
            rlen = rdir[pos]
            if rlen == 0: pos += 1; continue
            rec = rdir[pos:pos+rlen]
            flba = struct.unpack_from('<I', rec, 2)[0]
            namelen = rec[32]
            name = rec[33:33+namelen].decode('ascii', 'ignore')
            if name == 'BOOT': boot_lba = flba; break
            pos += rlen
        
        f.seek(boot_lba * 2048)
        bdir = f.read(2048)
        pos = 0
        e_lba = 0; e_size = 0
        while pos < len(bdir):
            rlen = bdir[pos]
            if rlen == 0: pos += 1; continue
            rec = bdir[pos:pos+rlen]
            flba = struct.unpack_from('<I', rec, 2)[0]
            fsize = struct.unpack_from('<I', rec, 10)[0]
            namelen = rec[32]
            name = rec[33:33+namelen].decode('ascii', 'ignore')
            if 'EFIBOOT' in name: e_lba = flba; e_size = fsize; break
            pos += rlen

        total_size = os.path.getsize(iso_path)
        total_sectors = total_size // 512
        esp_start = e_lba * 4
        esp_count = (e_size + 511) // 512
        esp_end = esp_start + esp_count - 1

        pmbr = bytearray(512)
        pmbr[446] = 0x00
        pmbr[447:450] = b"\x00\x02\x00"
        pmbr[450] = 0xEE
        pmbr[451:454] = b"\xff\xff\xff"
        struct.pack_into("<I", pmbr, 454, 1)
        struct.pack_into("<I", pmbr, 458, total_sectors - 1)
        pmbr[510] = 0x55
        pmbr[511] = 0xAA

        gpt_entries = bytearray(128 * 128)
        esp_guid = uuid.UUID('c12a7328-f81f-11d2-ba4b-00a0c93ec93b').bytes_le
        part_guid = uuid.UUID('21544a0b-1934-4b53-9d07-293673e1c651').bytes_le
        name = 'EFI System Partition'.encode('utf-16le').ljust(72, b'\x00')
        entry = struct.pack('<16s16sQQQ72s', esp_guid, part_guid, esp_start, esp_end, 0, name)
        gpt_entries[0:128] = entry
        entries_crc = zlib.crc32(gpt_entries) & 0xffffffff

        disk_guid = uuid.UUID('7b38d388-e04a-4a8d-b08e-5bca86049a4e').bytes_le
        hdr = bytearray(92)
        struct.pack_into('<8sIIIIQQQQ16sQIII',
            hdr, 0,
            b'EFI PART',
            0x00010000,
            92,
            0,
            0,
            1,
            total_sectors - 1,
            34,
            total_sectors - 34,
            disk_guid,
            2,
            128,
            128,
            entries_crc
        )
        hdr_crc = zlib.crc32(hdr) & 0xffffffff
        struct.pack_into('<I', hdr, 16, hdr_crc)

        f.seek(0)
        f.write(pmbr)
        f.seek(512)
        f.write(hdr)
        f.seek(1024)
        f.write(gpt_entries)
PYEOF

fi

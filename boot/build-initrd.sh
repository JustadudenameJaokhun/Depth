mkdir -p /home/jaokhun/Projects/Depth/boot
STAGING=/tmp/depth_initrd_staging
rm -rf "$STAGING"
mkdir -p "$STAGING"/bin "$STAGING"/sbin "$STAGING"/usr/bin "$STAGING"/dev "$STAGING"/proc "$STAGING"/sys "$STAGING"/root "$STAGING"/tmp "$STAGING"/var/lib/dive "$STAGING"/var/cache/dive/packages "$STAGING"/etc/fastfetch "$STAGING"/etc/dive

cp -f /home/jaokhun/Projects/Depth/sys/init/init "$STAGING"/init
chmod +x "$STAGING"/init

for b in /home/jaokhun/Projects/Depth/sys/bin/*; do
    cp -f "$b" "$STAGING"/bin/
    chmod +x "$STAGING"/bin/"$(basename "$b")"
done

cp -f /home/jaokhun/Projects/Depth/installer/depth-install "$STAGING"/bin/depthinstall
cp -f /home/jaokhun/Projects/Depth/installer/depth-install "$STAGING"/usr/bin/depthinstall
chmod +x "$STAGING"/bin/depthinstall "$STAGING"/usr/bin/depthinstall

ln -sf /bin/shutdown "$STAGING"/sbin/shutdown
ln -sf /bin/shutdown "$STAGING"/bin/poweroff
ln -sf /bin/glare "$STAGING"/bin/cinnamon
ln -sf /bin/glare "$STAGING"/bin/cinnamon-session
ln -sf /bin/glare "$STAGING"/bin/desktop
ln -sf /bin/glare "$STAGING"/bin/startx

cp -f /home/jaokhun/Projects/Depth/pkg/dive "$STAGING"/bin/dive
cp -f /home/jaokhun/Projects/Depth/pkg/dive "$STAGING"/usr/bin/dive
chmod +x "$STAGING"/bin/dive "$STAGING"/usr/bin/dive

cp -f /usr/bin/sh "$STAGING"/bin/sh
cp -f /usr/bin/fastfetch "$STAGING"/bin/fastfetch
cp -f /usr/bin/ip "$STAGING"/bin/ip 2>/dev/null || true
cp -f /usr/bin/tar "$STAGING"/bin/tar 2>/dev/null || true
cp -f /usr/bin/gzip "$STAGING"/bin/gzip 2>/dev/null || true
chmod +x "$STAGING"/bin/fastfetch "$STAGING"/bin/sh "$STAGING"/bin/ip "$STAGING"/bin/tar "$STAGING"/bin/gzip

cp -f /home/jaokhun/Projects/Depth/pkg/repo/recipes/fastfetch.json "$STAGING"/etc/fastfetch/config.jsonc
cp -f /home/jaokhun/Projects/Depth/pkg/repo/recipes/depth_logo.txt "$STAGING"/etc/fastfetch/depth_logo.txt

cp -rf /home/jaokhun/Projects/Depth/pkg/repo/packages/* "$STAGING"/var/cache/dive/packages/ 2>/dev/null || true
cp -f /home/jaokhun/Projects/Depth/pkg/repo/repo.json "$STAGING"/etc/dive/repo.json 2>/dev/null || true

printf "dimensions\n" > "$STAGING"/etc/hostname
printf "nameserver 10.0.2.3\nnameserver 1.1.1.1\nnameserver 8.8.8.8\n" > "$STAGING"/etc/resolv.conf
printf "root:x:0:0:root:/bin/sh\n" > "$STAGING"/etc/passwd
printf "root:\$6\$W/s2mWJtU2KDanVG\$AxeYjt/g9d/qubvOm3eYCQikRlC2zaNLCF6RGeFiXkqiNGZhD8.H6FuUVox8V9aIbaBW9vUdUtVcfUfN8bi4/0:19800:0:99999:7:::\n" > "$STAGING"/etc/shadow

MODE_VAL="${MODE:-bare}"
printf "%s\n" "$MODE_VAL" > "$STAGING"/etc/depth-mode

if [ "$MODE_VAL" = "glare" ]; then
    tar -xzf /home/jaokhun/Projects/Depth/pkg/repo/packages/cinnamon.dpk -C "$STAGING" 2>/dev/null || true
fi

mkdir -p "$STAGING"/lib/modules
cp -f /home/jaokhun/Projects/Depth/boot/modules/e1000.ko "$STAGING"/lib/modules/ 2>/dev/null || true

mkdir -p "$STAGING"/lib "$STAGING"/lib64 "$STAGING"/usr/lib "$STAGING"/usr/lib64

for lib in $(ldd /usr/bin/sh /usr/bin/fastfetch /usr/bin/ip /usr/bin/tar /usr/bin/gzip /home/jaokhun/Projects/Depth/sys/bin/glare 2>/dev/null | grep -o '/[^ ]*' | sort -u); do
    if [ -f "$lib" ]; then
        target_dir="$STAGING"$(dirname "$lib")
        mkdir -p "$target_dir"
        cp -f "$lib" "$target_dir"/ 2>/dev/null || true
    fi
done

cd "$STAGING"
find . -print0 | cpio --null --create --format=newc | gzip -9 > /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img
rm -rf "$STAGING"

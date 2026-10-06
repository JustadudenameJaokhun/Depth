mkdir -p /home/jaokhun/Projects/Depth/boot
STAGING=/tmp/depth_initrd_staging
rm -rf "$STAGING"
mkdir -p "$STAGING"/bin "$STAGING"/sbin "$STAGING"/usr/bin "$STAGING"/usr/lib "$STAGING"/dev "$STAGING"/proc "$STAGING"/sys "$STAGING"/root "$STAGING"/tmp "$STAGING"/var/lib/dive "$STAGING"/var/cache/dive/packages "$STAGING"/etc/fastfetch "$STAGING"/etc/dive
ln -sf usr/lib "$STAGING"/lib
ln -sf usr/lib "$STAGING"/lib64
ln -sf lib "$STAGING"/usr/lib64

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
ln -sf /bin/glare "$STAGING"/bin/desktop
ln -sf /bin/glare "$STAGING"/bin/startx

cp -f /home/jaokhun/Projects/Depth/pkg/dive "$STAGING"/bin/dive
cp -f /home/jaokhun/Projects/Depth/pkg/dive "$STAGING"/usr/bin/dive
chmod +x "$STAGING"/bin/dive "$STAGING"/usr/bin/dive

cp -f /usr/bin/bash "$STAGING"/bin/bash
ln -sf /bin/bash "$STAGING"/bin/sh
ln -sf /bin/bash "$STAGING"/usr/bin/bash
ln -sf /bin/bash "$STAGING"/usr/bin/sh
cp -f /usr/bin/fastfetch "$STAGING"/bin/fastfetch
cp -f /usr/bin/ip "$STAGING"/bin/ip 2>/dev/null || true
cp -f /usr/bin/tar "$STAGING"/bin/tar 2>/dev/null || true
cp -f /usr/bin/gzip "$STAGING"/bin/gzip 2>/dev/null || true
chmod +x "$STAGING"/bin/fastfetch "$STAGING"/bin/bash "$STAGING"/bin/ip "$STAGING"/bin/tar "$STAGING"/bin/gzip

cp -f /home/jaokhun/Projects/Depth/pkg/repo/recipes/fastfetch.json "$STAGING"/etc/fastfetch/config.jsonc
cp -f /home/jaokhun/Projects/Depth/pkg/repo/recipes/depth_logo.txt "$STAGING"/etc/fastfetch/depth_logo.txt

cp -rf /home/jaokhun/Projects/Depth/pkg/repo/packages/* "$STAGING"/var/cache/dive/packages/ 2>/dev/null || true
cp -f /home/jaokhun/Projects/Depth/pkg/repo/repo.json "$STAGING"/etc/dive/repo.json 2>/dev/null || true

printf "dimensions\n" > "$STAGING"/etc/hostname
printf "nameserver 10.0.2.3\nnameserver 1.1.1.1\nnameserver 8.8.8.8\n" > "$STAGING"/etc/resolv.conf
printf "root:x:0:0:root:/root:/bin/sh\ndbus:x:81:81:System Message Bus:/:/usr/bin/nologin\npolkitd:x:102:102:PolicyKit Daemon:/:/usr/bin/nologin\navahi:x:84:84:Avahi:/:/usr/bin/nologin\ncolord:x:124:124:Colord:/:/usr/bin/nologin\nsystemd-network:x:192:192:systemd:/:/usr/bin/nologin\nsystemd-oom:x:999:999:systemd:/:/usr/bin/nologin\nsystemd-resolve:x:193:193:systemd:/:/usr/bin/nologin\nsystemd-timesync:x:194:194:systemd:/:/usr/bin/nologin\n" > "$STAGING"/etc/passwd
printf "root:x:0:\ndbus:x:81:\npolkitd:x:102:\navahi:x:84:\ncolord:x:124:\nnetwork:x:90:\n" > "$STAGING"/etc/group
printf "root:\$6\$W/s2mWJtU2KDanVG\$AxeYjt/g9d/qubvOm3eYCQikRlC2zaNLCF6RGeFiXkqiNGZhD8.H6FuUVox8V9aIbaBW9vUdUtVcfUfN8bi4/0:19800:0:99999:7:::\n" > "$STAGING"/etc/shadow

MODE_VAL="${MODE:-bare}"
printf "%s\n" "$MODE_VAL" > "$STAGING"/etc/depth-mode

if [ "$MODE_VAL" = "glare" ]; then
    for b in /usr/bin/bwrap /usr/lib/Xorg /usr/bin/Xorg /usr/bin/xkbcomp /usr/bin/cinnamon /usr/bin/cinnamon2d /usr/bin/cinnamon-session /usr/bin/cinnamon-session-cinnamon /usr/bin/cinnamon-session-quit /usr/bin/cinnamon-settings /usr/bin/cinnamon-launcher /usr/bin/cinnamon-killer-daemon /usr/bin/muffin /usr/bin/nemo /usr/bin/nemo-desktop /usr/bin/dbus-daemon /usr/bin/dbus-launch /usr/bin/dbus-uuidgen /usr/bin/python3 /usr/bin/gnome-terminal /usr/bin/cjs /usr/bin/cjs-console /usr/bin/pkill /usr/bin/killall /usr/bin/setxkbmap /usr/bin/xmodmap /usr/bin/xrdb /usr/bin/cinnamon-subprocess-wrapper /usr/lib/libEGL_mesa.so.0 /usr/lib/libGLX_mesa.so.0 /usr/lib/libEGL.so.1 /usr/lib/libGL.so.1 /usr/lib/libGLdispatch.so.0 /usr/lib/gnome-terminal-server /usr/lib/cinnamon-settings-daemon/csd-xsettings /usr/lib/cinnamon-settings-daemon/csd-background; do
        if [ -f "$b" ]; then
            td="$STAGING"$(dirname "$b")
            mkdir -p "$td"
            cp -f "$b" "$td"/
            chmod +x "$td"/"$(basename "$b")"
        fi
    done
    mkdir -p "$STAGING"/usr/lib/cinnamon-session
    cp -af /usr/lib/cinnamon-session/* "$STAGING"/usr/lib/cinnamon-session/ 2>/dev/null || true
    for d in /usr/lib/xorg/modules /usr/lib/dri /usr/lib/gbm /usr/share/glvnd /usr/share/xkeyboard-config-2 /usr/share/cinnamon /usr/share/cinnamon-session /usr/share/glib-2.0/schemas /usr/lib/cinnamon /usr/lib/cinnamon-settings-daemon /usr/lib/muffin /usr/lib/cjs /usr/lib/gtk-3.0 /usr/lib/xapps /usr/lib/glycin-loaders /usr/share/glycin-loaders /usr/lib/python3.14 /etc/dbus-1 /usr/share/dbus-1 /usr/lib/girepository-1.0 /usr/share/icons/hicolor /usr/share/icons/Adwaita /usr/share/icons/AdwaitaLegacy /usr/share/icons/default /usr/share/applications /usr/share/xsessions /etc/xdg /usr/share/xml/iso-codes /usr/share/mime; do
        if [ -d "$d" ]; then
            td="$STAGING"$(dirname "$d")
            mkdir -p "$td"
            cp -a "$d" "$td"/ 2>/dev/null || true
        fi
    done
    mkdir -p "$STAGING"/usr/share/X11
    ln -sf /usr/share/xkeyboard-config-2 "$STAGING"/usr/share/X11/xkb
    cp -a /etc/fonts "$STAGING"/etc/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/fonts
    cp -a /usr/share/fonts/liberation "$STAGING"/usr/share/fonts/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/themes
    cp -a /usr/share/themes/Adwaita /usr/share/themes/Adwaita-dark /usr/share/themes/Default "$STAGING"/usr/share/themes/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/backgrounds "$STAGING"/usr/share/icons "$STAGING"/usr/share/icons/hicolor/scalable/apps "$STAGING"/usr/share/icons/Adwaita/scalable/apps
    python3 - << 'PYEOF'
import os
from PIL import Image, ImageDraw

staging = "/tmp/depth_initrd_staging"
bg_dir = os.path.join(staging, "usr/share/backgrounds")
os.makedirs(bg_dir, exist_ok=True)
icon_dir = os.path.join(staging, "usr/share/icons")
os.makedirs(icon_dir, exist_ok=True)

w, h = 1024, 768
r_start, g_start, b_start = 220, 20, 20
r_end, g_end, b_end = 8, 8, 12
buf = bytearray(w * h * 3)
idx = 0
for y in range(h):
    y_r = y / (h - 1)
    for x in range(w):
        t = (x / (w - 1) + y_r) * 0.5
        buf[idx] = int((1.0 - t) * r_start + t * r_end)
        buf[idx + 1] = int((1.0 - t) * g_start + t * g_end)
        buf[idx + 2] = int((1.0 - t) * b_start + t * b_end)
        idx += 3
img = Image.frombytes('RGB', (w, h), bytes(buf))
img.save(os.path.join(bg_dir, "depth-wallpaper.png"), optimize=True)

tri_svg = '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><polygon points="48,8 88,86 8,86" fill="rgb(230,25,25)"/></svg>\n'
with open(os.path.join(icon_dir, "depth-triangle.svg"), "w") as f:
    f.write(tri_svg)

tri_img = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
draw = ImageDraw.Draw(tri_img)
draw.polygon([(48, 8), (88, 86), (8, 86)], fill=(230, 25, 25, 255))
tri_img.save(os.path.join(icon_dir, "depth-triangle.png"))
PYEOF

    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/cinnamon/theme/menu-symbolic.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/cinnamon-symbolic.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/depth-triangle.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/Adwaita/scalable/apps/depth-triangle.svg 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/backgrounds/gnome
    cp -f "$STAGING"/usr/share/backgrounds/depth-wallpaper.png "$STAGING"/usr/share/backgrounds/gnome/adwaita-l.jxl 2>/dev/null || true
    cp -f "$STAGING"/usr/share/backgrounds/depth-wallpaper.png "$STAGING"/usr/share/backgrounds/gnome/adwaita-d.jxl 2>/dev/null || true
    printf "[org.nemo.preferences]\ntreat-root-as-normal=true\nshow-desktop-icons=true\n\n[org.nemo.desktop]\nshow-desktop-icons=true\nbackground-fade=false\n\n[org.gnome.desktop.background]\npicture-options='zoom'\npicture-uri='file:///usr/share/backgrounds/depth-wallpaper.png'\npicture-uri-dark='file:///usr/share/backgrounds/depth-wallpaper.png'\nprimary-color='#d32f2f'\nsecondary-color='#08080c'\ncolor-shading-type='solid'\n\n[org.cinnamon.desktop.background]\npicture-options='zoom'\npicture-uri='file:///usr/share/backgrounds/depth-wallpaper.png'\npicture-uri-dark='file:///usr/share/backgrounds/depth-wallpaper.png'\nprimary-color='#d32f2f'\nsecondary-color='#08080c'\ncolor-shading-type='solid'\n\n[org.cinnamon.desktop.interface]\nicon-theme='Adwaita'\ngtk-theme='Adwaita-dark'\nfont-name='Liberation Sans 10'\n\n[org.cinnamon]\ndesktop-effects=true\ndesktop-effects-on-menus=false\nwindow-effect-speed=2\nstartup-animation=false\nalttab-switcher-delay=0\napp-menu-label='Depth'\napp-menu-icon-name='/usr/share/icons/depth-triangle.svg'\n\n[org.cinnamon.muffin]\nunredirect-fullscreen-windows=true\nattach-modal-dialogs=true\n\n[org.cinnamon.theme]\nname='Default'\n" > "$STAGING"/usr/share/glib-2.0/schemas/99_depth.gschema.override
    glib-compile-schemas "$STAGING"/usr/share/glib-2.0/schemas/ 2>/dev/null || true
    mkdir -p "$STAGING"/root/.config/cinnamon/spices/menu@cinnamon.org
    printf '{"menu-custom":{"type":"switch","default":false,"value":true},"menu-label":{"type":"entry","default":"Menu","value":"Depth"},"menu-icon":{"type":"iconfilechooser","default":"cinnamon-symbolic","value":"/usr/share/icons/depth-triangle.svg"},"menu-icon-size":{"type":"spinbutton","default":32,"value":32.0}}\n' > "$STAGING"/root/.config/cinnamon/spices/menu@cinnamon.org/0.json
    mkdir -p "$STAGING"/tmp/.X11-unix "$STAGING"/run/user/0 "$STAGING"/var/run/dbus "$STAGING"/var/lib/dbus "$STAGING"/etc/X11
    chmod 1777 "$STAGING"/tmp/.X11-unix
    printf "d3b07384d113edec49eaa6238ad5ff00\n" > "$STAGING"/etc/machine-id
    ln -sf /etc/machine-id "$STAGING"/var/lib/dbus/machine-id
    ln -sf /usr/bin/cinnamon "$STAGING"/bin/cinnamon
    ln -sf /usr/bin/cinnamon-session "$STAGING"/bin/cinnamon-session
    ln -sf /usr/bin/cinnamon2d "$STAGING"/bin/cinnamon2d
    ln -sf /usr/bin/muffin "$STAGING"/bin/muffin
    ln -sf /usr/bin/nemo "$STAGING"/bin/nemo
    cat << 'EOF' > "$STAGING"/etc/X11/xorg.conf
Section "Device"
    Identifier "Card0"
    Driver "modesetting"
    Option "AccelMethod" "none"
    Option "ShadowFB" "true"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1024x768"
    EndSubSection
EndSection
EOF
fi

mkdir -p "$STAGING"/usr/lib/modules
cp -f /home/jaokhun/Projects/Depth/boot/modules/e1000.ko "$STAGING"/usr/lib/modules/ 2>/dev/null || true
cp -f /home/jaokhun/Projects/Depth/boot/modules/bochs.ko "$STAGING"/usr/lib/modules/ 2>/dev/null || true

python3 - << 'PYEOF'
import os, glob, subprocess, re

staging = "/tmp/depth_initrd_staging"
cinnamon_libs = [
    "libibus-1.0.so.5", "libaccountsservice.so.1", "libxapp.so.1",
    "libgcr-base-3.so.1", "libgcr-ui-3.so.1", "libnotify.so.4",
    "libpolkit-agent-1.so.0", "libpolkit-gobject-1.so.0", "libupower-glib.so.3",
    "libnm.so.0", "libnma.so.0", "libtimezonemap.so.1"
]
for l in cinnamon_libs:
    src = os.path.join("/usr/lib", l)
    if os.path.isfile(src):
        dst = os.path.join(staging, "usr/lib", l)
        if not os.path.exists(dst):
            subprocess.call(["cp", "-f", src, dst])

scanned = set()
while True:
    new_libs = set()
    for root, dirs, files in os.walk(staging):
        for f in files:
            p = os.path.join(root, f)
            if p in scanned or os.path.islink(p):
                continue
            if not (os.access(p, os.X_OK) or f.endswith(".so") or ".so." in f):
                continue
            scanned.add(p)
            try:
                out = subprocess.check_output(["ldd", p], stderr=subprocess.DEVNULL).decode()
                for line in out.splitlines():
                    if "=>" in line:
                        target = line.split("=>")[1].strip().split(" ")[0]
                        if target.startswith("/") and os.path.isfile(target):
                            new_libs.add(target)
                    elif line.strip().startswith("/"):
                        target = line.strip().split(" ")[0]
                        if os.path.isfile(target):
                            new_libs.add(target)
            except:
                pass
    to_copy = [lib for lib in new_libs if not os.path.exists(os.path.join(staging, lib.lstrip("/")))]
    if not to_copy:
        break
    for lib in to_copy:
        dest = os.path.join(staging, lib.lstrip("/"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        subprocess.call(["cp", "-f", lib, dest])

for src_ld in ["/lib64/ld-linux-x86-64.so.2", "/usr/lib/ld-linux-x86-64.so.2"]:
    if os.path.exists(src_ld):
        dest = os.path.join(staging, "usr/lib/ld-linux-x86-64.so.2")
        subprocess.call(["cp", "-f", src_ld, dest])
        break
PYEOF

printf "/usr/lib\n/usr/lib64\n/lib\n/lib64\n/usr/lib/cinnamon\n/usr/lib/muffin\n/usr/lib/cjs\n" > "$STAGING"/etc/ld.so.conf
ldconfig -r "$STAGING" 2>/dev/null || true

cd "$STAGING"
find . -print0 | cpio --null --create --format=newc | gzip -1 > /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img
rm -rf "$STAGING"

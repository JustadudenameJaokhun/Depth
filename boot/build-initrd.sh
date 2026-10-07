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
if [ -f /usr/bin/nano ]; then
    cp -f /usr/bin/nano "$STAGING"/bin/nano
    ln -sf /bin/nano "$STAGING"/usr/bin/nano
    chmod +x "$STAGING"/bin/nano
fi
mkdir -p "$STAGING"/usr/share/terminfo/l "$STAGING"/usr/share/terminfo/x
cp -f /usr/share/terminfo/l/linux "$STAGING"/usr/share/terminfo/l/ 2>/dev/null || true
cp -f /usr/share/terminfo/x/xterm* "$STAGING"/usr/share/terminfo/x/ 2>/dev/null || true
ln -sf /bin/depth-part "$STAGING"/bin/depthpart
ln -sf /bin/depth-part "$STAGING"/bin/part
ln -sf /bin/depth-part "$STAGING"/usr/bin/depth-part
ln -sf /bin/depth-part "$STAGING"/usr/bin/depthpart
ln -sf /bin/hinux-driverd "$STAGING"/usr/bin/hinux-driverd
ln -sf /bin/rac "$STAGING"/usr/bin/rac
chmod 4755 "$STAGING"/bin/rac 2>/dev/null || true
chmod 4755 "$STAGING"/usr/bin/rac 2>/dev/null || true
ln -sf /bin/mkfs.x1 "$STAGING"/sbin/mkfs.x1
ln -sf /bin/mkfs.x1 "$STAGING"/usr/bin/mkfs.x1
ln -sf /bin/mkfs.x1 "$STAGING"/bin/x1-format
ln -sf /bin/mkfs.x1 "$STAGING"/bin/x1fs
ln -sf /bin/mount.x1 "$STAGING"/bin/x1-mount
ln -sf /bin/mount.x1 "$STAGING"/sbin/mount.x1
ln -sf /bin/mount.x1 "$STAGING"/usr/bin/mount.x1
ln -sf /bin/depth-bgd "$STAGING"/usr/bin/depth-bgd
ln -sf /bin/depth-xsettings "$STAGING"/usr/bin/depth-xsettings
for nss in /usr/lib/libnss_files* /usr/lib/libnss_dns* /usr/lib/libresolv*; do
    cp -af "$nss" "$STAGING"/usr/lib/ 2>/dev/null || true
done
cp -f /usr/bin/fastfetch "$STAGING"/bin/fastfetch
cp -f /usr/bin/ip "$STAGING"/bin/ip 2>/dev/null || true
cp -f /usr/bin/tar "$STAGING"/bin/tar 2>/dev/null || true
cp -f /usr/bin/gzip "$STAGING"/bin/gzip 2>/dev/null || true
chmod +x "$STAGING"/bin/fastfetch "$STAGING"/bin/bash "$STAGING"/bin/ip "$STAGING"/bin/tar "$STAGING"/bin/gzip

cp -f /home/jaokhun/Projects/Depth/pkg/repo/recipes/fastfetch.json "$STAGING"/etc/fastfetch/config.jsonc
cp -f /home/jaokhun/Projects/Depth/pkg/repo/recipes/depth_logo.txt "$STAGING"/etc/fastfetch/depth_logo.txt

mkdir -p "$STAGING"/var/cache/dive/packages
cp -f /home/jaokhun/Projects/Depth/pkg/repo/repo.json "$STAGING"/etc/dive/repo.json 2>/dev/null || true

printf "dimensions\n" > "$STAGING"/etc/hostname
printf "127.0.0.1\tlocalhost dimensions\n::1\tlocalhost ip6-localhost ip6-loopback\n" > "$STAGING"/etc/hosts
printf "passwd: files\ngroup: files\nshadow: files\nhosts: files dns\nnetworks: files\nprotocols: files\nservices: files\nethers: files\nrpc: files\n" > "$STAGING"/etc/nsswitch.conf
printf "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 10.0.2.3\n" > "$STAGING"/etc/resolv.conf
printf "export PS1=\"\\[\\033[1;31m\\]depth-hinux \\[\\033[0;31m\\]\\w\\[\\033[1;31m\\] # \\[\\033[0m\\] \"\nalias sudo=\"rac\"\n" > "$STAGING"/etc/bash.bashrc
printf "export PS1=\"\\[\\033[1;31m\\]depth-hinux \\[\\033[0;31m\\]\\w\\[\\033[1;31m\\] # \\[\\033[0m\\] \"\nalias sudo=\"rac\"\n" > "$STAGING"/root/.bashrc
printf "root:x:0:0:root:/root:/bin/sh\ndbus:x:81:81:System Message Bus:/:/usr/bin/nologin\npolkitd:x:102:102:PolicyKit Daemon:/:/usr/bin/nologin\navahi:x:84:84:Avahi:/:/usr/bin/nologin\ncolord:x:124:124:Colord:/:/usr/bin/nologin\nsystemd-network:x:192:192:systemd:/:/usr/bin/nologin\nsystemd-oom:x:999:999:systemd:/:/usr/bin/nologin\nsystemd-resolve:x:193:193:systemd:/:/usr/bin/nologin\nsystemd-timesync:x:194:194:systemd:/:/usr/bin/nologin\n" > "$STAGING"/etc/passwd
printf "root:x:0:\ndbus:x:81:\npolkitd:x:102:\navahi:x:84:\ncolord:x:124:\nnetwork:x:90:\n" > "$STAGING"/etc/group
printf "root:\$6\$W/s2mWJtU2KDanVG\$AxeYjt/g9d/qubvOm3eYCQikRlC2zaNLCF6RGeFiXkqiNGZhD8.H6FuUVox8V9aIbaBW9vUdUtVcfUfN8bi4/0:19800:0:99999:7:::\n" > "$STAGING"/etc/shadow

MODE_VAL="${MODE:-bare}"
printf "%s\n" "$MODE_VAL" > "$STAGING"/etc/depth-mode

if [ "$MODE_VAL" = "glare" ]; then
    for b in /usr/bin/bwrap /usr/lib/Xorg /usr/bin/Xorg /usr/bin/xkbcomp /usr/bin/cinnamon /usr/bin/cinnamon2d /usr/bin/cinnamon-session /usr/bin/cinnamon-session-cinnamon /usr/bin/cinnamon-session-quit /usr/bin/cinnamon-settings /usr/bin/cinnamon-launcher /usr/bin/cinnamon-killer-daemon /usr/bin/muffin /usr/bin/nemo /usr/bin/nemo-desktop /usr/bin/dbus-daemon /usr/bin/dbus-launch /usr/bin/dbus-uuidgen /usr/bin/python3 /usr/bin/gnome-terminal /usr/bin/cjs /usr/bin/cjs-console /usr/bin/pkill /usr/bin/killall /usr/bin/setxkbmap /usr/bin/xmodmap /usr/bin/xrdb /usr/bin/cinnamon-subprocess-wrapper /usr/lib/libEGL_mesa.so.0 /usr/lib/libGLX_mesa.so.0 /usr/lib/libEGL.so.1 /usr/lib/libGL.so.1 /usr/lib/libGLdispatch.so.0 /usr/lib/gnome-terminal-server /usr/lib/gio-launch-desktop /usr/bin/firefox /usr/lib/dconf-service /usr/lib/gvfsd /usr/lib/cinnamon-settings-daemon/csd-xsettings /usr/lib/cinnamon-settings-daemon/csd-background /usr/lib/systemd/systemd-udevd /usr/bin/udevadm; do
        if [ -f "$b" ]; then
            td="$STAGING"$(dirname "$b")
            mkdir -p "$td"
            cp -f "$b" "$td"/
            chmod +x "$td"/"$(basename "$b")"
        fi
    done
    mkdir -p "$STAGING"/usr/lib/firefox
    cp -af /usr/lib/firefox/* "$STAGING"/usr/lib/firefox/ 2>/dev/null || true
    for rem in crashreporter crashhelper pingsender gfxtest; do
        rm -f "$STAGING"/usr/lib/firefox/"$rem"
    done
    cp -f /usr/bin/firefox "$STAGING"/bin/firefox 2>/dev/null || true
    cp -f /usr/bin/firefox "$STAGING"/usr/bin/firefox 2>/dev/null || true
    chmod +x "$STAGING"/bin/firefox "$STAGING"/usr/bin/firefox 2>/dev/null || true
    mkdir -p "$STAGING"/root/.mozilla/firefox/default
    cat << 'EOF' > "$STAGING"/root/.mozilla/firefox/profiles.ini
[Profile0]
Name=default
IsRelative=1
Path=default
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF
    cat << 'EOF' > "$STAGING"/root/.mozilla/firefox/installs.ini
[4F96D1932A9F858E]
Default=default
Locked=1
EOF
    printf 'user_pref("toolkit.telemetry.enabled", false);\nuser_pref("browser.shell.checkDefaultBrowser", false);\nuser_pref("browser.startup.homepage", "about:home");\nuser_pref("browser.offline", false);\nuser_pref("network.dns.disableIPv6", true);\nuser_pref("network.proxy.type", 0);\nuser_pref("media.rdd-ffmpeg.enabled", true);\nuser_pref("media.ffmpeg.vaapi.enabled", false);\nuser_pref("media.hardware-video-decoding.enabled", false);\nuser_pref("security.cert_pinning.enforcement_level", 1);\nuser_pref("security.nocertdb", false);\n' > "$STAGING"/root/.mozilla/firefox/default/user.js
    if [ -f "$STAGING"/usr/lib/firefox/firefox ]; then
        mv "$STAGING"/usr/lib/firefox/firefox "$STAGING"/usr/lib/firefox/firefox.real
        printf '#!/bin/sh\n' > "$STAGING"/usr/lib/firefox/firefox
        cat << 'EOF' >> "$STAGING"/usr/lib/firefox/firefox
mkdir -p /root/.mozilla/firefox/default
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs
/bin/ip link set lo up 2>/dev/null || true
chown -R 0:0 /root 2>/dev/null || true
rm -f /root/.mozilla/firefox/*/.parentlock /root/.mozilla/firefox/*/lock 2>/dev/null || true
ARGS=""
for a in "$@"; do
    case "$a" in
        %u|%U) ;;
        *) ARGS="$ARGS $a" ;;
    esac
done
exec /usr/lib/firefox/firefox.real --profile /root/.mozilla/firefox/default --new-instance $ARGS
EOF
        chmod +x "$STAGING"/usr/lib/firefox/firefox
        cp -f "$STAGING"/usr/lib/firefox/firefox "$STAGING"/usr/bin/firefox
        cp -f "$STAGING"/usr/lib/firefox/firefox "$STAGING"/bin/firefox
    fi
    mkdir -p "$STAGING"/etc/ca-certificates/extracted
    if [ -f /etc/ca-certificates/extracted/tls-ca-bundle.pem ]; then
        cp -f /etc/ca-certificates/extracted/tls-ca-bundle.pem "$STAGING"/etc/ca-certificates/extracted/tls-ca-bundle.pem
    fi
    mkdir -p "$STAGING"/etc/ssl/certs
    if [ -f /etc/ca-certificates/extracted/tls-ca-bundle.pem ]; then
        cp -f /etc/ca-certificates/extracted/tls-ca-bundle.pem "$STAGING"/etc/ssl/certs/ca-certificates.crt
        cp -f /etc/ca-certificates/extracted/tls-ca-bundle.pem "$STAGING"/etc/ssl/cert.pem
    fi
    mkdir -p "$STAGING"/etc "$STAGING"/var/lib/dbus
    printf "9b8f2a1e0d3c4b5a6978123456789abc\n" > "$STAGING"/etc/machine-id
    printf "9b8f2a1e0d3c4b5a6978123456789abc\n" > "$STAGING"/var/lib/dbus/machine-id
    if [ -f "$STAGING"/usr/share/dbus-1/services/org.gnome.Terminal.service ]; then
        sed -i '/SystemdService=/d' "$STAGING"/usr/share/dbus-1/services/org.gnome.Terminal.service
    fi
    mkdir -p "$STAGING"/usr/lib/cinnamon-session
    cp -af /usr/lib/cinnamon-session/* "$STAGING"/usr/lib/cinnamon-session/ 2>/dev/null || true
    for d in /usr/lib/locale /usr/lib/gio/modules /etc/ssl/certs /usr/share/ca-certificates /usr/lib/xorg/modules /usr/lib/dri /usr/lib/gbm /usr/share/glvnd /usr/share/xkeyboard-config-2 /usr/share/cinnamon /usr/share/cinnamon-session /usr/share/glib-2.0/schemas /usr/lib/cinnamon /usr/lib/cinnamon-settings-daemon /usr/lib/muffin /usr/lib/cjs /usr/lib/gtk-3.0 /usr/lib/xapps /usr/lib/glycin-loaders /usr/share/glycin-loaders /usr/lib/python3.14 /etc/dbus-1 /usr/share/dbus-1 /usr/lib/girepository-1.0 /usr/share/icons/hicolor /usr/share/icons/Adwaita /usr/share/icons/AdwaitaLegacy /usr/share/icons/default /usr/share/xsessions /etc/xdg /usr/share/xml/iso-codes /usr/share/mime /usr/lib/udev/rules.d /usr/share/libinput; do
        if [ -d "$d" ]; then
            td="$STAGING"$(dirname "$d")
            mkdir -p "$td"
            cp -a "$d" "$td"/ 2>/dev/null || true
        fi
    done
    if [ -x /usr/bin/gio-querymodules ]; then
        gio-querymodules "$STAGING"/usr/lib/gio/modules 2>/dev/null || true
    fi
    mkdir -p "$STAGING"/usr/share/applications
    rm -rf "$STAGING"/usr/share/applications/*
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-terminal.desktop
[Desktop Entry]
Type=Application
Name=Depth Terminal
Comment=Command Line Terminal
Exec=gnome-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;Utility;TerminalEmulator;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/firefox.desktop
[Desktop Entry]
Type=Application
Name=Firefox Web Browser
Comment=Browse the World Wide Web
Exec=firefox %u
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/nemo.desktop
[Desktop Entry]
Type=Application
Name=Nemo File Manager
Comment=Manage files and folders
Exec=nemo %U
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;Utility;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-install.desktop
[Desktop Entry]
Type=Application
Name=Depth OS Installer
Comment=Install Depth Hinux to storage
Exec=gnome-terminal -- /bin/depthinstall
Icon=depth-triangle
Terminal=false
Categories=System;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-part.desktop
[Desktop Entry]
Type=Application
Name=Drive Partitioner
Comment=Manage drive partitions and format with X1
Exec=gnome-terminal -- /bin/depthpart
Icon=depth-triangle
Terminal=false
Categories=System;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-network.desktop
[Desktop Entry]
Type=Application
Name=Network Manager
Comment=Manage network connections
Exec=gnome-terminal -- /bin/network
Icon=network-wireless-symbolic
Terminal=false
Categories=System;Network;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-dive.desktop
[Desktop Entry]
Type=Application
Name=Dive Package Manager
Comment=Install and update software packages
Exec=gnome-terminal -- /bin/bash -c "dive help; exec /bin/bash"
Icon=depth-triangle
Terminal=false
Categories=System;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-sysinfo.desktop
[Desktop Entry]
Type=Application
Name=System Information
Comment=Display Depth Hinux system details
Exec=gnome-terminal -- /bin/bash -c "fastfetch; echo; echo 'Press Enter to exit...'; read -r; exit"
Icon=depth-triangle
Terminal=false
Categories=System;Utility;
EOF
    cat << 'EOF' > "$STAGING"/usr/share/applications/depth-text.desktop
[Desktop Entry]
Type=Application
Name=Nano Text Editor
Comment=Edit text documents
Exec=gnome-terminal -- /bin/nano
Icon=text-editor
Terminal=false
Categories=Utility;TextEditor;
EOF
    mkdir -p "$STAGING"/etc/gtk-3.0 "$STAGING"/root/.config/gtk-3.0 "$STAGING"/etc/gtk-4.0 "$STAGING"/root/.config/gtk-4.0
    cat << 'EOF' > "$STAGING"/etc/gtk-3.0/settings.ini
[Settings]
gtk-theme-name = Adwaita-dark
gtk-icon-theme-name = Flat-Remix-Red-Dark
gtk-application-prefer-dark-theme = 1
gtk-font-name = Liberation Sans 10
gtk-cursor-theme-name = Adwaita
EOF
    cp -f "$STAGING"/etc/gtk-3.0/settings.ini "$STAGING"/root/.config/gtk-3.0/settings.ini
    cp -f "$STAGING"/etc/gtk-3.0/settings.ini "$STAGING"/etc/gtk-4.0/settings.ini
    cp -f "$STAGING"/etc/gtk-3.0/settings.ini "$STAGING"/root/.config/gtk-4.0/settings.ini
    cat << 'EOF' > "$STAGING"/root/.config/gtk-3.0/gtk.css
window, .background {
    background-color: #101114;
    color: #f0f0f0;
}
vte-terminal, terminal-window {
    background-color: #0a0b0d;
    color: #f0f0f0;
}
EOF
    printf "GTK_THEME=Adwaita:dark\n" >> "$STAGING"/etc/environment
    mkdir -p "$STAGING"/usr/share/X11/xorg.conf.d
    cat << 'EOF' > "$STAGING"/usr/share/X11/xorg.conf.d/40-libinput.conf
Section "InputClass"
    Identifier "libinput pointer catchall"
    MatchIsPointer "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
Section "InputClass"
    Identifier "libinput keyboard catchall"
    MatchIsKeyboard "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
Section "InputClass"
    Identifier "libinput touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
Section "InputClass"
    Identifier "libinput tablet catchall"
    MatchIsTablet "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
EOF
    mkdir -p "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/places/scalable
    cp -f /usr/share/icons/Flat-Remix-Red-Dark/index.theme "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/ 2>/dev/null || true
    for ic in system-file-manager.svg nemo.svg utilities-terminal.svg org.gnome.Terminal.svg firefox.svg preferences-system.svg text-editor.svg org.gnome.TextEditor.svg; do
        p="/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/$ic"
        if [ -f "$p" ]; then cp -f "$p" "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/; fi
    done
    for pl in folder.svg user-home.svg user-desktop.svg; do
        p="/usr/share/icons/Flat-Remix-Red-Dark/places/scalable/$pl"
        if [ -f "$p" ]; then cp -f "$p" "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/places/scalable/; fi
    done
    cp -af /usr/share/icons/Flat-Remix-Red-Dark/panel "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/ 2>/dev/null || true
    cp -af /usr/share/icons/Flat-Remix-Red-Dark/status "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/X11
    ln -sf /usr/share/xkeyboard-config-2 "$STAGING"/usr/share/X11/xkb
    cp -a /etc/fonts "$STAGING"/etc/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/fonts
    cp -a /usr/share/fonts/liberation "$STAGING"/usr/share/fonts/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/themes
    cp -a /usr/share/themes/Adwaita /usr/share/themes/Adwaita-dark /usr/share/themes/Default "$STAGING"/usr/share/themes/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/backgrounds "$STAGING"/usr/share/icons "$STAGING"/usr/share/icons/hicolor/scalable/apps "$STAGING"/usr/share/icons/Adwaita/scalable/apps
    python3 - << 'PYEOF'
import os, subprocess
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
    y_r = (h - 1 - y) / (h - 1)
    for x in range(w):
        t = (x / (w - 1) + y_r) * 0.5
        buf[idx] = int((1.0 - t) * r_start + t * r_end)
        buf[idx + 1] = int((1.0 - t) * g_start + t * g_end)
        buf[idx + 2] = int((1.0 - t) * b_start + t * b_end)
        idx += 3
img = Image.frombytes('RGB', (w, h), bytes(buf))
img.save(os.path.join(bg_dir, "depth-wallpaper.png"), optimize=True)

tri_svg = '''<svg width="256" height="256" viewBox="0 0 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="ds" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#000000" flood-opacity="0.65"/>
      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#ff1a1a" flood-opacity="0.35"/>
    </filter>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ff4d4d"/>
      <stop offset="35%" stop-color="#b80c0c"/>
      <stop offset="70%" stop-color="#5e0000"/>
      <stop offset="100%" stop-color="#240003"/>
    </linearGradient>
    <linearGradient id="lf" x1="20%" y1="0%" x2="80%" y2="100%">
      <stop offset="0%" stop-color="#ff3b3b"/>
      <stop offset="30%" stop-color="#e61010"/>
      <stop offset="75%" stop-color="#990000"/>
      <stop offset="100%" stop-color="#570000"/>
    </linearGradient>
    <linearGradient id="rf" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#c41010"/>
      <stop offset="40%" stop-color="#800404"/>
      <stop offset="85%" stop-color="#420002"/>
      <stop offset="100%" stop-color="#1f0002"/>
    </linearGradient>
    <linearGradient id="bf" x1="50%" y1="0%" x2="50%" y2="100%">
      <stop offset="0%" stop-color="#ff2626"/>
      <stop offset="50%" stop-color="#a80505"/>
      <stop offset="100%" stop-color="#3d0003"/>
    </linearGradient>
    <linearGradient id="ic" x1="50%" y1="100%" x2="50%" y2="0%">
      <stop offset="0%" stop-color="#140003"/>
      <stop offset="50%" stop-color="#400007"/>
      <stop offset="100%" stop-color="#8a000d"/>
    </linearGradient>
    <radialGradient id="as" cx="50%" cy="15%" r="35%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.85"/>
      <stop offset="25%" stop-color="#ff8080" stop-opacity="0.5"/>
      <stop offset="60%" stop-color="#ff1a1a" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#ff0000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="ir" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ff6666"/>
      <stop offset="50%" stop-color="#b30000"/>
      <stop offset="100%" stop-color="#ff3333"/>
    </linearGradient>
  </defs>
  <g filter="url(#ds)">
    <path d="M 128,18 C 133,18 138,25 142,32 L 237,196 C 242,204 242,214 236,222 C 231,230 221,234 212,234 L 44,234 C 35,234 25,230 20,222 C 14,214 14,204 19,196 L 114,32 C 118,25 123,18 128,18 Z" fill="url(#bg)" stroke="#ff6666" stroke-width="1.5" stroke-opacity="0.4"/>
    <path d="M 128,26 L 128,162 L 36,218 C 30,214 26,206 28,198 L 118,36 C 121,30 124,26 128,26 Z" fill="url(#lf)"/>
    <path d="M 128,26 C 132,26 135,30 138,36 L 228,198 C 230,206 226,214 220,218 L 128,162 Z" fill="url(#rf)"/>
    <path d="M 128,162 L 220,218 C 215,224 207,226 200,226 L 56,226 C 49,226 41,224 36,218 Z" fill="url(#bf)"/>
    <path d="M 128,88 L 174,170 L 82,170 Z" fill="url(#ic)" stroke="url(#ir)" stroke-width="2.5" stroke-linejoin="round"/>
    <polygon points="128,104 154,152 102,152" fill="#080002" opacity="0.8"/>
    <polygon points="128,112 144,142 112,142" fill="#ff1f1f" opacity="0.45"/>
    <path d="M 128,22 C 130,22 133,26 135,30 L 42,192 C 38,198 34,196 32,192 L 122,28 C 124,24 126,22 128,22 Z" fill="#ffffff" opacity="0.32"/>
    <circle cx="128" cy="38" r="28" fill="url(#as)"/>
  </g>
</svg>'''
with open(os.path.join(icon_dir, "depth-triangle.svg"), "w") as f:
    f.write(tri_svg)

term_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <defs>
    <filter id="ds_term" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="7" stdDeviation="6" flood-color="#000000" flood-opacity="0.6"/>
    </filter>
    <linearGradient id="body_term" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#2a2e36"/>
      <stop offset="100%" stop-color="#14161a"/>
    </linearGradient>
    <linearGradient id="border_term" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#444b59"/>
      <stop offset="100%" stop-color="#101114"/>
    </linearGradient>
    <linearGradient id="screen_term" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#111317"/>
      <stop offset="100%" stop-color="#0a0b0d"/>
    </linearGradient>
    <linearGradient id="prompt_term" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ff4444"/>
      <stop offset="100%" stop-color="#ff1a1a"/>
    </linearGradient>
    <filter id="glow_term" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="0" stdDeviation="2.5" flood-color="#ff2222" flood-opacity="0.8"/>
    </filter>
  </defs>
  <rect x="12" y="14" width="104" height="100" rx="20" ry="20" fill="url(#border_term)" filter="url(#ds_term)"/>
  <rect x="13" y="15" width="102" height="98" rx="19" ry="19" fill="url(#body_term)"/>
  <rect x="13" y="15" width="102" height="22" rx="19" ry="19" fill="#1e2127"/>
  <rect x="13" y="25" width="102" height="12" fill="#1e2127"/>
  <line x1="13" y1="37" x2="115" y2="37" stroke="#121316" stroke-width="1"/>
  <circle cx="27" cy="26" r="4.5" fill="#ff5f56"/>
  <circle cx="39" cy="26" r="4.5" fill="#ffbd2e"/>
  <circle cx="51" cy="26" r="4.5" fill="#27c93f"/>
  <rect x="18" y="42" width="92" height="66" rx="10" ry="10" fill="url(#screen_term)" stroke="#1a1c22" stroke-width="1"/>
  <path d="M 30 55 L 42 66 L 30 77" fill="none" stroke="url(#prompt_term)" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round" filter="url(#glow_term)"/>
  <line x1="48" y1="76" x2="64" y2="76" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round"/>
</svg>'''
with open(os.path.join(icon_dir, "utilities-terminal.svg"), "w") as f:
    f.write(term_svg)

nemo_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <defs>
    <filter id="ds_nemo" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="7" stdDeviation="6" flood-color="#000000" flood-opacity="0.55"/>
    </filter>
    <linearGradient id="back_nemo" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#b71c1c"/>
      <stop offset="100%" stop-color="#4a0000"/>
    </linearGradient>
    <linearGradient id="front_nemo" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ff3b3b"/>
      <stop offset="100%" stop-color="#c62828"/>
    </linearGradient>
    <linearGradient id="paper_nemo" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#e4e8f0"/>
    </linearGradient>
    <linearGradient id="spec_nemo" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.0"/>
    </linearGradient>
  </defs>
  <path d="M 18 34 C 18 26, 26 24, 32 24 L 52 24 C 58 24, 62 30, 68 34 L 108 34 C 114 34, 118 38, 118 46 L 118 96 C 118 104, 112 110, 104 110 L 24 110 C 16 110, 18 104, 18 96 Z" fill="url(#back_nemo)" filter="url(#ds_nemo)"/>
  <rect x="28" y="32" width="72" height="40" rx="6" ry="6" fill="url(#paper_nemo)" opacity="0.95"/>
  <line x1="38" y1="42" x2="70" y2="42" stroke="#ccb0b0" stroke-width="3" stroke-linecap="round"/>
  <line x1="38" y1="50" x2="86" y2="50" stroke="#d9c2c2" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M 14 48 C 14 42, 20 40, 26 40 L 102 40 C 108 40, 114 42, 114 48 L 114 96 C 114 104, 108 110, 100 110 L 28 110 C 20 110, 14 104, 14 96 Z" fill="url(#front_nemo)"/>
  <path d="M 14 48 C 14 42, 20 40, 26 40 L 102 40 C 108 40, 114 42, 114 48 L 114 54 C 114 48, 108 46, 102 46 L 26 46 C 20 46, 14 48, 14 54 Z" fill="url(#spec_nemo)"/>
  <path d="M 64 68 L 74 85 L 54 85 Z" fill="#ffffff" opacity="0.3"/>
</svg>'''
with open(os.path.join(icon_dir, "system-file-manager.svg"), "w") as f:
    f.write(nemo_svg)

fld_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <defs>
    <filter id="ds_fld" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="5" flood-color="#000000" flood-opacity="0.55"/>
    </filter>
    <linearGradient id="back_fld" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#990000"/>
      <stop offset="100%" stop-color="#420000"/>
    </linearGradient>
    <linearGradient id="front_fld" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#e52d27"/>
      <stop offset="100%" stop-color="#b31217"/>
    </linearGradient>
    <linearGradient id="paper_fld" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#e0e0e0"/>
    </linearGradient>
  </defs>
  <path d="M 18 34 C 18 26, 26 24, 32 24 L 52 24 C 58 24, 62 30, 68 34 L 108 34 C 114 34, 118 38, 118 46 L 118 96 C 118 104, 112 110, 104 110 L 24 110 C 16 110, 18 104, 18 96 Z" fill="url(#back_fld)" filter="url(#ds_fld)"/>
  <rect x="28" y="32" width="72" height="40" rx="5" ry="5" fill="url(#paper_fld)" opacity="0.95"/>
  <line x1="38" y1="42" x2="70" y2="42" stroke="#ccb0b0" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="38" y1="50" x2="86" y2="50" stroke="#d9c2c2" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M 14 48 C 14 42, 20 40, 26 40 L 102 40 C 108 40, 114 42, 114 48 L 114 96 C 114 104, 108 110, 100 110 L 28 110 C 20 110, 14 104, 14 96 Z" fill="url(#front_fld)"/>
  <polygon points="64,68 76,88 52,88" fill="#ffffff" opacity="0.85"/>
  <polygon points="64,74 72,86 56,86" fill="#b31217" opacity="0.9"/>
</svg>'''
with open(os.path.join(icon_dir, "depth-folder.svg"), "w") as f:
    f.write(fld_svg)

subprocess.call(["rsvg-convert", "-w", "96", "-h", "96", os.path.join(icon_dir, "depth-triangle.svg"), "-o", os.path.join(icon_dir, "depth-triangle.png")])
PYEOF

    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/cinnamon/theme/menu-symbolic.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/cinnamon-symbolic.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/depth-triangle.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/Adwaita/scalable/apps/depth-triangle.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/depth-triangle.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/depth-triangle.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/panel/depth-triangle.svg 2>/dev/null || true

    cp -f "$STAGING"/usr/share/icons/system-file-manager.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/system-file-manager.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/system-file-manager.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/nemo.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/system-file-manager.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/nemo.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/system-file-manager.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/system-file-manager.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/system-file-manager.svg "$STAGING"/usr/share/icons/Adwaita/scalable/apps/system-file-manager.svg 2>/dev/null || true

    mkdir -p "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/places/scalable "$STAGING"/usr/share/icons/Adwaita/scalable/places "$STAGING"/usr/share/icons/hicolor/scalable/places
    for pl in folder.svg inode-directory.svg user-home.svg user-desktop.svg folder-documents.svg folder-download.svg folder-music.svg folder-pictures.svg folder-videos.svg folder-remote.svg; do
        cp -f "$STAGING"/usr/share/icons/depth-folder.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/places/scalable/"$pl" 2>/dev/null || true
        cp -f "$STAGING"/usr/share/icons/depth-folder.svg "$STAGING"/usr/share/icons/Adwaita/scalable/places/"$pl" 2>/dev/null || true
        cp -f "$STAGING"/usr/share/icons/depth-folder.svg "$STAGING"/usr/share/icons/hicolor/scalable/places/"$pl" 2>/dev/null || true
    done

    cp -f "$STAGING"/usr/share/icons/utilities-terminal.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/utilities-terminal.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/utilities-terminal.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/org.gnome.Terminal.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/utilities-terminal.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/org.gnome.Terminal.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/utilities-terminal.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/utilities-terminal.svg 2>/dev/null || true
    cp -f "$STAGING"/usr/share/icons/utilities-terminal.svg "$STAGING"/usr/share/icons/Adwaita/scalable/apps/org.gnome.Terminal.svg 2>/dev/null || true

    if [ -f /usr/share/icons/Papirus/64x64/apps/firefox.svg ]; then
        cp -f /usr/share/icons/Papirus/64x64/apps/firefox.svg "$STAGING"/usr/share/icons/Flat-Remix-Red-Dark/apps/scalable/firefox.svg 2>/dev/null || true
        cp -f /usr/share/icons/Papirus/64x64/apps/firefox.svg "$STAGING"/usr/share/icons/hicolor/scalable/apps/firefox.svg 2>/dev/null || true
        cp -f /usr/share/icons/Papirus/64x64/apps/firefox.svg "$STAGING"/usr/share/icons/Adwaita/scalable/apps/firefox.svg 2>/dev/null || true
    fi

    mkdir -p "$STAGING"/usr/share/backgrounds/gnome
    cp -f "$STAGING"/usr/share/backgrounds/depth-wallpaper.png "$STAGING"/usr/share/backgrounds/gnome/adwaita-l.jxl 2>/dev/null || true
    cp -f "$STAGING"/usr/share/backgrounds/depth-wallpaper.png "$STAGING"/usr/share/backgrounds/gnome/adwaita-d.jxl 2>/dev/null || true
    printf "[org.nemo.preferences]\ntreat-root-as-normal=true\nshow-desktop-icons=true\n\n[org.nemo.desktop]\nshow-desktop-icons=true\nbackground-fade=false\n\n[org.gnome.desktop.background]\npicture-options='zoom'\npicture-uri='file:///usr/share/backgrounds/depth-wallpaper.png'\npicture-uri-dark='file:///usr/share/backgrounds/depth-wallpaper.png'\nprimary-color='#08080c'\nsecondary-color='#d32f2f'\ncolor-shading-type='solid'\n\n[org.gnome.desktop.interface]\nicon-theme='Flat-Remix-Red-Dark'\ngtk-theme='Adwaita-dark'\ncolor-scheme='prefer-dark'\nfont-name='Liberation Sans 10'\n\n[org.cinnamon.desktop.background]\npicture-options='zoom'\npicture-uri='file:///usr/share/backgrounds/depth-wallpaper.png'\npicture-uri-dark='file:///usr/share/backgrounds/depth-wallpaper.png'\nprimary-color='#08080c'\nsecondary-color='#d32f2f'\ncolor-shading-type='solid'\n\n[org.cinnamon.desktop.interface]\nicon-theme='Flat-Remix-Red-Dark'\ngtk-theme='Adwaita-dark'\ncolor-scheme='prefer-dark'\nfont-name='Liberation Sans 10'\n\n[org.cinnamon.desktop.default-applications.terminal]\nexec='gnome-terminal'\nexec-arg='--'\n\n[org.gnome.Terminal.Legacy.Settings]\ntheme-variant='dark'\nheaderbar=false\n\n[org.gnome.Terminal.ProfilesList]\ndefault='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'\nlist=['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']\n\n[org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/]\nvisible-name='Depth'\nbackground-color='#0a0b0d'\nforeground-color='#f0f0f0'\nuse-theme-colors=false\nbold-color-same-as-fg=true\ncursor-colors-set=true\ncursor-background-color='#ff3333'\ncursor-foreground-color='#ffffff'\ndefault-size-columns=80\ndefault-size-rows=24\n\n[org.cinnamon]\npanels-enabled=['1:0:top']\nfavorite-apps=['depth-terminal.desktop', 'firefox.desktop', 'nemo.desktop']\ndesktop-effects=true\ndesktop-effects-on-menus=false\nwindow-effect-speed=2\nstartup-animation=false\nalttab-switcher-delay=0\napp-menu-label='Depth'\napp-menu-icon-name='/usr/share/icons/depth-triangle.svg'\nenabled-applets=['panel1:left:0:menu@cinnamon.org', 'panel1:left:1:separator@cinnamon.org', 'panel1:left:2:grouped-window-list@cinnamon.org', 'panel1:right:0:systray@cinnamon.org', 'panel1:right:1:notifications@cinnamon.org', 'panel1:right:2:depth-network@depth.org', 'panel1:right:3:depth-power@depth.org', 'panel1:right:4:sound@cinnamon.org', 'panel1:right:5:calendar@cinnamon.org', 'panel1:right:6:cornerbar@cinnamon.org']\n\n[org.cinnamon.muffin]\nunredirect-fullscreen-windows=true\nattach-modal-dialogs=true\n\n[org.cinnamon.theme]\nname='Default'\n" > "$STAGING"/usr/share/glib-2.0/schemas/99_depth.gschema.override
    glib-compile-schemas "$STAGING"/usr/share/glib-2.0/schemas/ 2>/dev/null || true
    mkdir -p "$STAGING"/usr/share/cinnamon/applets/depth-network@depth.org
    cp -rf /home/jaokhun/Projects/Depth/sys/glare/applets/depth-network@depth.org/* "$STAGING"/usr/share/cinnamon/applets/depth-network@depth.org/
    mkdir -p "$STAGING"/usr/share/cinnamon/applets/depth-power@depth.org
    cp -rf /home/jaokhun/Projects/Depth/sys/glare/applets/depth-power@depth.org/* "$STAGING"/usr/share/cinnamon/applets/depth-power@depth.org/
    rm -rf "$STAGING"/usr/share/cinnamon/applets/printers@cinnamon.org
    mkdir -p "$STAGING"/root/.config/cinnamon/spices/menu@cinnamon.org
    printf '{"menu-custom":{"type":"switch","default":false,"value":true},"menu-label":{"type":"entry","default":"Menu","value":"Depth"},"menu-icon":{"type":"iconfilechooser","default":"cinnamon-symbolic","value":"/usr/share/icons/depth-triangle.svg"},"menu-icon-size":{"type":"spinbutton","default":32,"value":32.0}}\n' > "$STAGING"/root/.config/cinnamon/spices/menu@cinnamon.org/0.json
    mkdir -p "$STAGING"/root/.cinnamon/configs/grouped-window-list@cinnamon.org
    printf '{"pinned-apps":{"type":"generic","value":["depth-terminal.desktop","firefox.desktop","nemo.desktop"]},"enable-app-button-dragging":{"type":"checkbox","value":true},"group-apps":{"type":"checkbox","value":true},"title-display":{"type":"combobox","value":1}}\n' > "$STAGING"/root/.cinnamon/configs/grouped-window-list@cinnamon.org/2.json
    mkdir -p "$STAGING"/tmp/.X11-unix "$STAGING"/run/user/0 "$STAGING"/var/lib/dbus "$STAGING"/etc/X11
    rm -rf "$STAGING"/var/run
    ln -sf /run "$STAGING"/var/run
    chmod 1777 "$STAGING"/tmp/.X11-unix
    printf "d3b07384d113edec49eaa6238ad5ff00\n" > "$STAGING"/etc/machine-id
    ln -sf /etc/machine-id "$STAGING"/var/lib/dbus/machine-id
    ln -sf /usr/bin/cinnamon "$STAGING"/bin/cinnamon
    ln -sf /usr/bin/cinnamon-session "$STAGING"/bin/cinnamon-session
    ln -sf /usr/bin/cinnamon2d "$STAGING"/bin/cinnamon2d
    ln -sf /usr/bin/muffin "$STAGING"/bin/muffin
    ln -sf /usr/bin/nemo "$STAGING"/bin/nemo
    ln -sf /bin/cinnamon-killer-daemon "$STAGING"/usr/bin/cinnamon-killer-daemon
    ln -sf /bin/depth-powerd "$STAGING"/usr/bin/depth-powerd
    ln -sf /bin/glare-launcher "$STAGING"/usr/bin/glare-launcher
    ln -sf /bin/cinnamon-autostart "$STAGING"/usr/bin/cinnamon-autostart
    ln -sf /bin/dpk-verify "$STAGING"/usr/bin/dpk-verify
    ln -sf /bin/hinux-driverd "$STAGING"/usr/bin/hinux-driverd
    ln -sf /bin/depth-part "$STAGING"/usr/bin/depthpart
    ln -sf /bin/depth-part "$STAGING"/usr/bin/part
    ln -sf /bin/rac "$STAGING"/usr/bin/rac
    ln -sf /bin/mkfs.x1 "$STAGING"/usr/bin/mkfs.x1
    ln -sf /bin/mkfs.x1 "$STAGING"/bin/x1-format
    ln -sf /bin/depth-bgd "$STAGING"/usr/bin/depth-bgd
    ln -sf /bin/depth-xsettings "$STAGING"/usr/bin/depth-xsettings
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
        Modes "1920x1080" "1024x768"
    EndSubSection
EndSection

Section "ServerFlags"
    Option "AutoAddDevices" "true"
    Option "AutoEnableDevices" "true"
EndSection

Section "InputClass"
    Identifier "libinput catchall fallback"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
EOF
fi

mkdir -p "$STAGING"/usr/lib/modules
cp -f /home/jaokhun/Projects/Depth/boot/modules/e1000.ko "$STAGING"/usr/lib/modules/ 2>/dev/null || true
cp -f /home/jaokhun/Projects/Depth/boot/modules/bochs.ko "$STAGING"/usr/lib/modules/ 2>/dev/null || true
cp -f /home/jaokhun/Projects/Depth/boot/modules/snd-hda-*.ko "$STAGING"/usr/lib/modules/ 2>/dev/null || true
for mlib in /usr/lib/libavcodec* /usr/lib/libavformat* /usr/lib/libavutil* /usr/lib/libswresample* /usr/lib/libasound* /usr/lib/libpulse*; do
    cp -af "$mlib" "$STAGING"/usr/lib/ 2>/dev/null || true
done

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

py_dir = os.path.join(staging, "usr/lib/python3.14")
if os.path.isdir(py_dir):
    prune_dirs = [
        "site-packages/mesonbuild", "site-packages/pygments", "site-packages/vapoursynth",
        "site-packages/pyverbs", "site-packages/lxml", "site-packages/setuptools",
        "site-packages/blueman", "site-packages/PIL", "site-packages/urllib3",
        "site-packages/mako", "site-packages/markdown", "site-packages/wheel",
        "config-3.14-x86_64-linux-gnu", "idlelib", "ensurepip",
        "tkinter", "test", "unittest", "pydoc_data", "turtledemo"
    ]
    for pd in prune_dirs:
        full_pd = os.path.join(py_dir, pd)
        if os.path.isdir(full_pd):
            subprocess.call(["rm", "-rf", full_pd])
    for root, dirs, files in os.walk(py_dir):
        if "__pycache__" in dirs:
            subprocess.call(["rm", "-rf", os.path.join(root, "__pycache__")])

for idir in ["usr/share/icons/Adwaita", "usr/share/icons/hicolor"]:
    full_idir = os.path.join(staging, idir)
    if os.path.isdir(full_idir):
        for item in ["64x64", "96x96", "128x128", "256x256", "512x512", "cursors"]:
            tgt = os.path.join(full_idir, item)
            if os.path.exists(tgt):
                subprocess.call(["rm", "-rf", tgt])

ff_dir = os.path.join(staging, "usr/lib/firefox")
if os.path.isdir(ff_dir):
    for rem in ["gmp-clearkey", "libmozinference.so"]:
        tgt = os.path.join(ff_dir, rem)
        if os.path.exists(tgt):
            subprocess.call(["rm", "-rf", tgt])

for root, dirs, files in os.walk(staging):
    for f in files:
        p = os.path.join(root, f)
        if os.path.islink(p):
            continue
        if p.endswith(".so") or ".so." in f or os.access(p, os.X_OK):
            subprocess.call(["strip", "--strip-unneeded", p], stderr=subprocess.DEVNULL)
PYEOF

printf "/usr/lib\n/usr/lib64\n/lib\n/lib64\n/usr/lib/cinnamon\n/usr/lib/muffin\n/usr/lib/cjs\n/usr/lib/firefox\n" > "$STAGING"/etc/ld.so.conf
ldconfig -r "$STAGING" 2>/dev/null || true

cd "$STAGING"
find . -print0 | cpio --null --create --format=newc --owner 0:0 | gzip -9 > /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img
cd /home/jaokhun/Projects/Depth
chmod -R u+w "$STAGING" 2>/dev/null || true
rm -rf "$STAGING"

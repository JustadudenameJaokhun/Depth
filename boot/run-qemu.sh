KVM_OPTS=""
[ -w /dev/kvm ] && KVM_OPTS="-enable-kvm -cpu host"
exec qemu-system-x86_64 \
  $KVM_OPTS \
  -kernel /boot/vmlinuz-linux \
  -initrd /home/jaokhun/Projects/Depth/boot/depth-bare-initrd.img \
  -append "console=ttyS0 loglevel=7 ignore_loglevel panic=1 rdinit=/init" \
  -nographic \
  -no-reboot \
  -m 512M


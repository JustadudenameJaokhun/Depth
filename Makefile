KVM_OPTS := $(shell [ -w /dev/kvm ] && echo "-enable-kvm -cpu host")

all: build iso

build:
	$(MAKE) -C sys
	gcc -static -O2 -s -o pkg/dive pkg/dive.c
	gcc -static -O2 -s -o sys/init/init sys/init/init.c
	gcc -O2 -s -o installer/depth-install installer/depth-install.c
	sh boot/build-initrd.sh

iso: build
	sh boot/build-iso.sh

run:
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-kernel /boot/vmlinuz-linux \
		-initrd boot/depth-bare-initrd.img \
		-append "console=ttyS0 console=tty0 loglevel=7 ignore_loglevel net.ifnames=0 biosdevname=0 panic=1 rdinit=/init" \
		-netdev user,id=net0 \
		-device e1000,netdev=net0 \
		-vga std \
		-m 512M \
		-no-reboot

run-iso: iso
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-cdrom boot/depth-hinux.iso \
		-boot d \
		-netdev user,id=net0 \
		-device e1000,netdev=net0 \
		-vga std \
		-m 512M \
		-no-reboot

run-cli:
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-kernel /boot/vmlinuz-linux \
		-initrd boot/depth-bare-initrd.img \
		-append "console=ttyS0 loglevel=7 ignore_loglevel net.ifnames=0 biosdevname=0 panic=1 rdinit=/init" \
		-netdev user,id=net0 \
		-device e1000,netdev=net0 \
		-nographic \
		-m 512M \
		-no-reboot

clean:
	$(MAKE) -C sys clean
	rm -f pkg/dive sys/init/init installer/depth-install boot/depth-bare-initrd.img boot/depth-hinux.iso

.PHONY: all build iso run run-iso run-cli clean

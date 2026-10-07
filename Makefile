KVM_OPTS := $(shell [ -w /dev/kvm ] && echo "-enable-kvm -cpu host")

all: build iso kernel

kernel:
	$(MAKE) -C sys/kernel

bare:
	$(MAKE) build-target MODE=bare

glare:
	$(MAKE) build-target MODE=glare

build:
	@if [ -t 0 ] && [ -z "$(MODE)" ]; then \
		printf "Compile Depth Hinux target mode:\n  [1] bare  (Bedrock minimal CLI)\n  [2] glare (Cinnamon Desktop Environment)\nSelect [1/2, default 1]: "; \
		read -r ans; \
		if [ "$$ans" = "2" ] || [ "$$ans" = "glare" ]; then \
			$(MAKE) build-target MODE=glare; \
		else \
			$(MAKE) build-target MODE=bare; \
		fi; \
	else \
		$(MAKE) build-target MODE=$(if $(MODE),$(MODE),bare); \
	fi

build-target:
	$(MAKE) -C sys
	$(MAKE) -C sys/kernel
	gcc -O2 -s -o sys/bin/glare sys/glare/glare.c -lX11
	gcc -static -O2 -s -o pkg/dive pkg/dive.c
	gcc -static -O2 -s -o sys/init/init sys/init/init.c
	gcc -O2 -s -o installer/depth-install installer/depth-install.c
	cp -f installer/depth-install sys/bin/depthinstall
	./pkg/dive repo-index pkg/repo/packages
	MODE=$(MODE) sh boot/build-initrd.sh

iso: build
	sh boot/build-iso.sh

run-kernel: kernel
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-kernel sys/kernel/hinux-kernel.bin \
		-vga std \
		-serial stdio \
		-m 1024M \
		-no-reboot

run:
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-kernel /boot/vmlinuz-linux \
		-initrd boot/depth-bare-initrd.img \
		-append "console=ttyS0 console=tty0 loglevel=7 ignore_loglevel net.ifnames=0 biosdevname=0 panic=1 rdinit=/init" \
		-netdev user,id=net0 \
		-device e1000,netdev=net0 \
		-usb \
		-device usb-tablet \
		-vga std \
		-m 3072M \
		-no-reboot

run-iso: iso
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-cdrom boot/depth-hinux.iso \
		-boot d \
		-netdev user,id=net0 \
		-device e1000,netdev=net0 \
		-usb \
		-device usb-tablet \
		-vga std \
		-m 3072M \
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
		-m 3072M \
		-no-reboot

clean:
	$(MAKE) -C sys clean
	$(MAKE) -C sys/kernel clean
	rm -f pkg/dive sys/init/init installer/depth-install sys/bin/depthinstall sys/bin/glare boot/depth-bare-initrd.img boot/depth-hinux.iso

.PHONY: all bare glare build build-target iso kernel run-kernel run run-iso run-cli clean

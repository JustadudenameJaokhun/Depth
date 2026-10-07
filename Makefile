KVM_OPTS := $(shell [ -w /dev/kvm ] && echo "-enable-kvm -cpu host")

all: build kernel

kernel:
	$(MAKE) -C sys/kernel

bare:
	@target_arch="$(BOOT_ARCH)"; \
	if [ -z "$$target_arch" ]; then \
		printf "Select bootloader architecture:\n  [1] UEFI (GPT 64-bit Bootloader)\n  [2] Legacy BIOS (MBR / CSM Bootloader)\nSelect [1/2, default 1]: "; \
		read -r arch_ans; \
		if [ "$$arch_ans" = "2" ] || [ "$$arch_ans" = "legacy" ] || [ "$$arch_ans" = "bios" ] || [ "$$arch_ans" = "mbr" ]; then \
			target_arch="mbr"; \
		else \
			target_arch="gpt"; \
		fi; \
	fi; \
	$(MAKE) build-target MODE=bare BOOT_ARCH="$$target_arch"

glare:
	@target_arch="$(BOOT_ARCH)"; \
	if [ -z "$$target_arch" ]; then \
		printf "Select bootloader architecture:\n  [1] UEFI (GPT 64-bit Bootloader)\n  [2] Legacy BIOS (MBR / CSM Bootloader)\nSelect [1/2, default 1]: "; \
		read -r arch_ans; \
		if [ "$$arch_ans" = "2" ] || [ "$$arch_ans" = "legacy" ] || [ "$$arch_ans" = "bios" ] || [ "$$arch_ans" = "mbr" ]; then \
			target_arch="mbr"; \
		else \
			target_arch="gpt"; \
		fi; \
	fi; \
	$(MAKE) build-target MODE=glare BOOT_ARCH="$$target_arch"

build:
	@target_mode="$(MODE)"; \
	target_arch="$(BOOT_ARCH)"; \
	if [ -z "$$target_mode" ]; then \
		printf "Select Depth Hinux edition:\n  [1] Glare (Cinnamon Desktop Environment)\n  [2] Bare  (Bedrock minimal CLI)\nSelect [1/2, default 1]: "; \
		read -r mode_ans; \
		if [ "$$mode_ans" = "2" ] || [ "$$mode_ans" = "bare" ]; then \
			target_mode="bare"; \
		else \
			target_mode="glare"; \
		fi; \
	fi; \
	if [ -z "$$target_arch" ]; then \
		printf "Select bootloader architecture:\n  [1] UEFI (GPT 64-bit Bootloader)\n  [2] Legacy BIOS (MBR / CSM Bootloader)\nSelect [1/2, default 1]: "; \
		read -r arch_ans; \
		if [ "$$arch_ans" = "2" ] || [ "$$arch_ans" = "legacy" ] || [ "$$arch_ans" = "bios" ] || [ "$$arch_ans" = "mbr" ]; then \
			target_arch="mbr"; \
		else \
			target_arch="gpt"; \
		fi; \
	fi; \
	$(MAKE) build-target MODE="$$target_mode" BOOT_ARCH="$$target_arch"

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
	BOOT_ARCH=$(BOOT_ARCH) sh boot/build-iso.sh

iso: build

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
		-netdev user,id=net0,dns=1.1.1.1 \
		-device e1000,netdev=net0 \
		-audiodev pa,id=snd0 \
		-device intel-hda \
		-device hda-duplex,audiodev=snd0 \
		-usb \
		-device usb-tablet \
		-device VGA,edid=on,xres=1920,yres=1080 \
		-m 3072M \
		-no-reboot

run-iso: iso
	@if head -c 1024 boot/depth-hinux.iso 2>/dev/null | grep -q "EFI PART" || [ "$(BOOT_ARCH)" = "gpt" ] || [ "$(BOOT_ARCH)" = "uefi" ]; then \
		qemu-system-x86_64 \
			$(KVM_OPTS) \
			-bios /usr/share/edk2/x64/OVMF.4m.fd \
			-drive file=boot/depth-hinux.iso,format=raw,media=disk \
			-boot c \
			-netdev user,id=net0,dns=1.1.1.1 \
			-device e1000,netdev=net0 \
			-audiodev pa,id=snd0 \
			-device intel-hda \
			-device hda-duplex,audiodev=snd0 \
			-usb \
			-device usb-tablet \
			-device VGA,edid=on,xres=1920,yres=1080 \
			-m 3072M \
			-no-reboot; \
	else \
		qemu-system-x86_64 \
			$(KVM_OPTS) \
			-cdrom boot/depth-hinux.iso \
			-boot d \
			-netdev user,id=net0,dns=1.1.1.1 \
			-device e1000,netdev=net0 \
			-audiodev pa,id=snd0 \
			-device intel-hda \
			-device hda-duplex,audiodev=snd0 \
			-usb \
			-device usb-tablet \
			-device VGA,edid=on,xres=1920,yres=1080 \
			-m 3072M \
			-no-reboot; \
	fi

run-uefi:
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-bios /usr/share/edk2/x64/OVMF.4m.fd \
		-drive file=boot/depth-hinux.iso,format=raw,media=disk \
		-boot c \
		-netdev user,id=net0,dns=1.1.1.1 \
		-device e1000,netdev=net0 \
		-audiodev pa,id=snd0 \
		-device intel-hda \
		-device hda-duplex,audiodev=snd0 \
		-usb \
		-device usb-tablet \
		-device VGA,edid=on,xres=1920,yres=1080 \
		-m 3072M \
		-no-reboot

run-mbr:
	qemu-system-x86_64 \
		$(KVM_OPTS) \
		-cdrom boot/depth-hinux.iso \
		-boot d \
		-netdev user,id=net0,dns=1.1.1.1 \
		-device e1000,netdev=net0 \
		-audiodev pa,id=snd0 \
		-device intel-hda \
		-device hda-duplex,audiodev=snd0 \
		-usb \
		-device usb-tablet \
		-device VGA,edid=on,xres=1920,yres=1080 \
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
	rm -f pkg/dive sys/init/init installer/depth-install sys/bin/depthinstall sys/bin/glare boot/depth-bare-initrd.img boot/depth-hinux.iso boot/efiboot.img

.PHONY: all bare glare build build-target iso kernel run-kernel run run-iso run-uefi run-mbr run-cli clean

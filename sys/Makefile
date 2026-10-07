NASM = nasm
NASMFLAGS = -f elf64 -I asm/
LD = ld
LDFLAGS = -m elf_x86_64 -s

BIN_DIR = bin
BUILD_DIR = build

COREUTILS = $(BIN_DIR)/echo $(BIN_DIR)/cat $(BIN_DIR)/ls $(BIN_DIR)/cp \
            $(BIN_DIR)/mkdir $(BIN_DIR)/rm $(BIN_DIR)/pwd $(BIN_DIR)/uname \
            $(BIN_DIR)/clear $(BIN_DIR)/touch $(BIN_DIR)/whoami $(BIN_DIR)/true \
            $(BIN_DIR)/false $(BIN_DIR)/sleep $(BIN_DIR)/wc $(BIN_DIR)/head \
            $(BIN_DIR)/env $(BIN_DIR)/yes $(BIN_DIR)/basename $(BIN_DIR)/dirname \
            $(BIN_DIR)/kill $(BIN_DIR)/sync $(BIN_DIR)/seq $(BIN_DIR)/chmod \
            $(BIN_DIR)/tr $(BIN_DIR)/uniq $(BIN_DIR)/sort $(BIN_DIR)/network $(BIN_DIR)/net \
            $(BIN_DIR)/shutdown $(BIN_DIR)/which $(BIN_DIR)/file $(BIN_DIR)/hostname \
            $(BIN_DIR)/uptime $(BIN_DIR)/free $(BIN_DIR)/ps $(BIN_DIR)/cal \
            $(BIN_DIR)/tail $(BIN_DIR)/df $(BIN_DIR)/cut $(BIN_DIR)/grep \
            $(BIN_DIR)/cinnamon-watchdog $(BIN_DIR)/glare-launcher \
            $(BIN_DIR)/cinnamon-autostart $(BIN_DIR)/dpk-verify \
            $(BIN_DIR)/depth-part $(BIN_DIR)/depthpart $(BIN_DIR)/part \
            $(BIN_DIR)/hinux-driverd $(BIN_DIR)/rac \
            $(BIN_DIR)/mkfs.x1 $(BIN_DIR)/x1-format $(BIN_DIR)/x1fs \
            $(BIN_DIR)/mount.x1 $(BIN_DIR)/x1-mount \
            $(BIN_DIR)/depth-bgd $(BIN_DIR)/depth-xsettings \
            $(BIN_DIR)/cinnamon-killer-daemon $(BIN_DIR)/depth-powerd \
            $(BIN_DIR)/depth-boot.bin

ASM_OBJS = $(BUILD_DIR)/string.o $(BUILD_DIR)/mem.o $(BUILD_DIR)/io.o \
           $(BUILD_DIR)/avx2_mem.o $(BUILD_DIR)/string_simd.o $(BUILD_DIR)/hinux.o \
           $(BUILD_DIR)/fmt.o $(BUILD_DIR)/vfs.o $(BUILD_DIR)/elf_loader.o \
           $(BUILD_DIR)/crypt.o $(BUILD_DIR)/net.o $(BUILD_DIR)/term.o \
           $(BUILD_DIR)/hinux_math.o $(BUILD_DIR)/ipc.o $(BUILD_DIR)/hinux_sched.o \
           $(BUILD_DIR)/hinux_signal.o $(BUILD_DIR)/glare_font.o $(BUILD_DIR)/glare_mouse.o \
           $(BUILD_DIR)/glare_render.o $(BUILD_DIR)/vga_font.o $(BUILD_DIR)/net_tcp.o \
           $(BUILD_DIR)/glare_compositor.o $(BUILD_DIR)/glare_font_tables.o \
           $(BUILD_DIR)/glare_raster.o $(BUILD_DIR)/glare_events.o \
           $(BUILD_DIR)/glare_widgets.o $(BUILD_DIR)/vfs_ext.o \
           $(BUILD_DIR)/glare_theme.o $(BUILD_DIR)/glare_draw_fast.o \
           $(BUILD_DIR)/glare_fx.o $(BUILD_DIR)/glare_terminal.o $(BUILD_DIR)/glare_layout.o \
           $(BUILD_DIR)/cinnamon_theme.o $(BUILD_DIR)/cinnamon_panel.o

all: $(BIN_DIR) $(BUILD_DIR) $(COREUTILS) $(ASM_OBJS)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: asm/%.asm
	$(NASM) $(NASMFLAGS) $< -o $@

$(BUILD_DIR)/%.o: coreutils/%.asm
	$(NASM) $(NASMFLAGS) $< -o $@

$(BIN_DIR)/%: $(BUILD_DIR)/%.o
	$(LD) $(LDFLAGS) $< -o $@

$(BIN_DIR)/net: $(BIN_DIR)/network
	cp -f $< $@

$(BIN_DIR)/depthpart: $(BIN_DIR)/depth-part
	cp -f $< $@

$(BIN_DIR)/part: $(BIN_DIR)/depth-part
	cp -f $< $@

$(BIN_DIR)/mkfs.x1: $(BUILD_DIR)/x1-format.o
	$(LD) $(LDFLAGS) $< -o $@

$(BIN_DIR)/x1-format: $(BIN_DIR)/mkfs.x1
	cp -f $< $@

$(BIN_DIR)/x1fs: $(BIN_DIR)/mkfs.x1
	cp -f $< $@

$(BIN_DIR)/mount.x1: $(BUILD_DIR)/x1-mount.o
	$(LD) $(LDFLAGS) $< -o $@

$(BIN_DIR)/x1-mount: $(BIN_DIR)/mount.x1
	cp -f $< $@

$(BIN_DIR)/depth-boot.bin: bootloader/depth-boot.asm
	nasm -f bin $< -o $(BUILD_DIR)/depth-boot.raw
	python3 -c "raw=open('$(BUILD_DIR)/depth-boot.raw','rb').read(); d=bytearray(raw + b'\x00'*(2048-len(raw))); d[510]=0x55; d[511]=0xaa; open('$@','wb').write(d)"
	cp -f $@ ../boot/depth-boot.bin

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

.PHONY: all clean

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
            $(BIN_DIR)/uptime $(BIN_DIR)/free $(BIN_DIR)/ps

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
           $(BUILD_DIR)/glare_theme.o

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

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

.PHONY: all clean

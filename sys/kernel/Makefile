NASM = nasm
NASMFLAGS = -f elf64
LD = ld
LDFLAGS = -n -T kernel.ld

OBJS = boot.o console.o idt.o mm.o sched.o syscall.o main.o
TARGET = hinux-kernel.elf
BOOTABLE = hinux-kernel.bin

all: $(TARGET) $(BOOTABLE)

%.o: %.asm
	$(NASM) $(NASMFLAGS) $< -o $@

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@

$(BOOTABLE): $(TARGET)
	objcopy -O elf32-i386 $< $@

clean:
	rm -f $(OBJS) $(TARGET) $(BOOTABLE)

.PHONY: all clean

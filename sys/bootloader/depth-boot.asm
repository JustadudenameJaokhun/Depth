bits 16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov si, msg_clear
    call print_string

    mov si, msg_banner1
    call print_string
    mov si, msg_banner2
    call print_string
    mov si, msg_banner3
    call print_string

    mov si, msg_booting
    call print_string
    mov si, msg_loading
    call print_string
    mov si, msg_ready
    call print_string

.hang:
    hlt
    jmp .hang

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string
.done:
    ret

msg_clear:
    db 27, "[2J", 27, "[H", 0

msg_banner1:
    db 13, 10, "  =======================================================", 13, 10, 0
msg_banner2:
    db "      DEPTH HINUX ASM BOOTLOADER v1.0 [BEDROCK CORE]", 13, 10, 0
msg_banner3:
    db "  =======================================================", 13, 10, 13, 10, 0

msg_booting:
    db "  [BOOT] Probing hardware devices and memory map...", 13, 10, 0
msg_loading:
    db "  [BOOT] Loading kernel /boot/vmlinuz and /boot/initrd.img...", 13, 10, 0
msg_ready:
    db "  [BOOT] Jumping to 64-bit Depth Hinux kernel entry point.", 13, 10, 13, 10, 0

times 446 - ($ - $$) db 0

part1:
    db 0x80
    db 0x00, 0x01, 0x00
    db 0x17
    db 0xFF, 0xFF, 0xFF
    dd 0x00000000
    dd 0x00400000

part2:
    times 16 db 0
part3:
    times 16 db 0
part4:
    times 16 db 0

dw 0xAA55

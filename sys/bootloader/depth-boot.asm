bits 16
org 0x7C00

entry:
    cli
    jmp 0x0000:main
    nop
    nop

bi_pvd:     dd 0
bi_file:    dd 0
bi_length:  dd 0
bi_csum:    dd 0
bi_reserved: times 40 db 0

kernel_lba:     dd 0
kernel_sectors: dd 0
kernel_bytes:   dd 0
initrd_lba:     dd 0
initrd_sectors: dd 0
initrd_bytes:   dd 0

main:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    in al, 0x92
    or al, 2
    and al, 0xFE
    out 0x92, al

    cli
    push ds
    lgdt [gdt_desc]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp $+2
    mov bx, 0x08
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    and al, 0xFE
    mov cr0, eax
    jmp $+2
    pop ds
    sti

    mov si, msg_banner1
    call print_str
    mov si, msg_banner2
    call print_str
    mov si, msg_banner3
    call print_str

    mov si, msg_load_kern
    call print_str

    mov eax, [kernel_lba]
    mov [dap_lba_low], eax
    mov dword [dap_lba_high], 0
    mov word [dap_count], 1
    mov word [dap_buf_off], 0x0000
    mov word [dap_buf_seg], 0x2000
    call read_sectors

    mov esi, 0x000201F1
    mov al, [fs:esi]
    test al, al
    jnz .has_setup
    mov al, 4
.has_setup:
    inc al
    movzx ecx, al
    shl ecx, 9
    mov [setup_size], ecx

    mov eax, [kernel_lba]
    mov edx, [kernel_sectors]
    mov edi, 0x00100000
    call load_file_to_high

    mov esi, 0x00100000
    mov edi, 0x00090000
    mov ecx, [setup_size]
    shr ecx, 2
    inc ecx
.cpy_setup:
    mov eax, [fs:esi]
    mov [fs:edi], eax
    add esi, 4
    add edi, 4
    dec ecx
    jnz .cpy_setup

    mov esi, 0x00100000
    add esi, [setup_size]
    mov edi, 0x00100000
    mov ecx, [kernel_bytes]
    sub ecx, [setup_size]
    shr ecx, 2
    inc ecx
.cpy_prot:
    mov eax, [fs:esi]
    mov [fs:edi], eax
    add esi, 4
    add edi, 4
    dec ecx
    jnz .cpy_prot

    mov si, msg_load_initrd
    call print_str

    mov eax, [initrd_lba]
    mov edx, [initrd_sectors]
    mov edi, 0x08000000
    call load_file_to_high

    mov si, msg_booting
    call print_str

    mov edi, 0x00090210
    mov byte [fs:edi], 0xFF
    mov edi, 0x00090211
    mov al, [fs:edi]
    or al, 0x21
    mov [fs:edi], al
    mov edi, 0x00090224
    mov word [fs:edi], 0xDE00
    mov edi, 0x00090218
    mov dword [fs:edi], 0x08000000
    mov edi, 0x0009021C
    mov eax, [initrd_bytes]
    mov dword [fs:edi], eax

    mov esi, cmdline
    mov edi, 0x00098000
.cpy_cmd:
    lodsb
    mov [fs:edi], al
    inc edi
    test al, al
    jnz .cpy_cmd

    mov edi, 0x00090228
    mov dword [fs:edi], 0x00098000

    cli
    mov ax, 0x9000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0xDE00
    jmp 0x9020:0000

load_file_to_high:
.read_loop:
    test edx, edx
    jz .done
    push edx
    push eax
    push edi

    mov ecx, edx
    cmp ecx, 16
    jbe .count_ok
    mov ecx, 16
.count_ok:
    mov [dap_lba_low], eax
    mov dword [dap_lba_high], 0
    mov [dap_count], cx
    mov word [dap_buf_off], 0x0000
    mov word [dap_buf_seg], 0x2000
    push ecx
    call read_sectors
    pop ecx

    shl ecx, 9
    mov esi, 0x00020000
.cpy_blk:
    mov eax, [fs:esi]
    mov [fs:edi], eax
    add esi, 4
    add edi, 4
    dec ecx
    jnz .cpy_blk

    pop edi
    pop eax
    pop edx

    cmp edx, 16
    jbe .done
    sub edx, 16
    add eax, 16
    add edi, 16 * 2048
    jmp .read_loop
.done:
    ret

read_sectors:
    push si
    mov si, dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    pop si
    ret

print_str:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp print_str
.done:
    ret

align 8
gdt:
    dq 0
    dw 0xFFFF, 0x0000
    db 0x00, 0x92, 0xCF, 0x00
gdt_desc:
    dw 15
    dd 0x7C00 + (gdt - entry)

boot_drive:     db 0
setup_size:     dd 0

align 4
dap:
dap_len:        db 16, 0
dap_count:      dw 0
dap_buf_off:    dw 0
dap_buf_seg:    dw 0
dap_lba_low:    dd 0
dap_lba_high:   dd 0

msg_banner1: db 13, 10, "  =======================================================", 13, 10, 0
msg_banner2: db "      DEPTH HINUX ASM BOOTLOADER v1.0 [BEDROCK CORE]", 13, 10, 0
msg_banner3: db "  =======================================================", 13, 10, 13, 10, 0
msg_load_kern: db "  [BOOT] Loading kernel /boot/vmlinuz...", 13, 10, 0
msg_load_initrd: db "  [BOOT] Loading ramdisk /boot/initrd.img...", 13, 10, 0
msg_booting: db "  [BOOT] Jumping to 64-bit Depth Hinux kernel entry point.", 13, 10, 13, 10, 0

cmdline: db "console=ttyS0 console=tty0 loglevel=7 ignore_loglevel net.ifnames=0 biosdevname=0 panic=1 rdinit=/init", 0

default rel

section .multiboot
align 4
    dd 0x1BADB002
    dd 0x00000003
    dd -(0x1BADB002 + 0x00000003)

section .bss
align 4096
pml4_table:
    resb 4096
pdp_table:
    resb 4096
pd_table:
    resb 4096
stack_bottom:
    resb 65536
stack_top:

section .rodata
gdt64:
    dq 0x0000000000000000
    dq 0x00209A0000000000
    dq 0x0000920000000000
    dq 0x0020FA0000000000
    dq 0x0000F20000000000
gdt64_ptr:
    dw gdt64_ptr - gdt64 - 1
    dq gdt64

section .text
bits 32
global _start
extern kmain

_start:
    cli
    mov esp, stack_top

    mov edi, pml4_table
    mov ecx, 3072
    xor eax, eax
    cld
    rep stosd

    mov eax, pdp_table
    or eax, 0x03
    mov [pml4_table], eax

    mov eax, pd_table
    or eax, 0x03
    mov [pdp_table], eax

    mov ecx, 0
.map_pd:
    mov eax, ecx
    shl eax, 21
    or eax, 0x83
    mov [pd_table + ecx * 8], eax
    inc ecx
    cmp ecx, 64
    jne .map_pd

    mov eax, pml4_table
    mov cr3, eax

    mov eax, cr4
    or eax, 0x20
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr

    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax

    lgdt [gdt64_ptr]
    jmp 0x08:.long_mode_entry

bits 64
.long_mode_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsp, stack_top

    call kmain

.halt:
    cli
    hlt
    jmp .halt

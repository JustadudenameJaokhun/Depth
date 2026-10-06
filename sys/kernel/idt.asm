default rel

section .rodata
msg_div0: db 10, "[HINUX TRAP] CPU Exception 00: Divide by Zero", 10, 0
msg_gpf:  db 10, "[HINUX TRAP] CPU Exception 13: General Protection Fault", 10, 0
msg_pf:   db 10, "[HINUX TRAP] CPU Exception 14: Page Fault Detected", 10, 0
msg_unhandled: db 10, "[HINUX TRAP] Unhandled CPU Interrupt Gate", 10, 0

section .bss
align 16
idt_table:
    resb 256 * 16
idt_ptr:
    resb 10

section .text
bits 64
global idt_init
global idt_set_gate
extern kprint_red
extern kprint_white
extern vga_print_hex64

%macro ISR_NOERR 1
isr_%1:
    push qword 0
    push qword %1
    jmp isr_common
%endmacro

%macro ISR_ERR 1
isr_%1:
    push qword %1
    jmp isr_common
%endmacro

ISR_NOERR 0
ISR_NOERR 1
ISR_NOERR 2
ISR_NOERR 3
ISR_NOERR 4
ISR_NOERR 5
ISR_NOERR 6
ISR_NOERR 7
ISR_ERR   8
ISR_NOERR 9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_NOERR 21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_NOERR 29
ISR_ERR   30
ISR_NOERR 31

ISR_NOERR 32
ISR_NOERR 33

isr_common:
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rbp
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    push rax

    mov rax, [rsp + 15 * 8]

    cmp rax, 0
    je .handle_div0
    cmp rax, 13
    je .handle_gpf
    cmp rax, 14
    je .handle_pf
    cmp rax, 32
    je .handle_timer
    cmp rax, 33
    je .handle_kbd

    lea rdi, [msg_unhandled]
    call kprint_red
    jmp .eoi

.handle_div0:
    lea rdi, [msg_div0]
    call kprint_red
    jmp .halt

.handle_gpf:
    lea rdi, [msg_gpf]
    call kprint_red
    jmp .halt

.handle_pf:
    lea rdi, [msg_pf]
    call kprint_red
    mov rax, cr2
    mov rdi, rax
    call vga_print_hex64
    jmp .halt

.handle_timer:
    mov al, 0x20
    out 0x20, al
    jmp .finish

.handle_kbd:
    in al, 0x60
    mov al, 0x20
    out 0x20, al
    jmp .finish

.eoi:
    mov al, 0x20
    out 0x20, al

.finish:
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rbp
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15

    add rsp, 16
    iretq

.halt:
    cli
    hlt
    jmp .halt

idt_set_gate:
    push rbx
    push rcx

    imul rcx, rdi, 16
    lea rbx, [idt_table]
    add rbx, rcx

    mov rax, rsi
    mov [rbx], ax

    mov word [rbx + 2], 0x08
    mov byte [rbx + 4], 0
    mov byte [rbx + 5], dl

    shr rax, 16
    mov [rbx + 6], ax

    shr rax, 16
    mov [rbx + 8], eax
    mov dword [rbx + 12], 0

    pop rcx
    pop rbx
    ret

pic_remap:
    push rax

    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al

    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al

    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    mov al, 0xFC
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al

    pop rax
    ret

idt_init:
    push rdi
    push rsi
    push rdx
    push rcx
    push rax

    call pic_remap

    mov rdi, idt_table
    mov rcx, 256 * 2
    xor rax, rax
    cld
    rep stosq

%macro SET_GATE 2
    mov rdi, %1
    lea rsi, [isr_%1]
    mov rdx, %2
    call idt_set_gate
%endmacro

    SET_GATE 0, 0x8E
    SET_GATE 1, 0x8E
    SET_GATE 2, 0x8E
    SET_GATE 3, 0x8E
    SET_GATE 4, 0x8E
    SET_GATE 5, 0x8E
    SET_GATE 6, 0x8E
    SET_GATE 7, 0x8E
    SET_GATE 8, 0x8E
    SET_GATE 9, 0x8E
    SET_GATE 10, 0x8E
    SET_GATE 11, 0x8E
    SET_GATE 12, 0x8E
    SET_GATE 13, 0x8E
    SET_GATE 14, 0x8E
    SET_GATE 15, 0x8E
    SET_GATE 16, 0x8E
    SET_GATE 17, 0x8E
    SET_GATE 18, 0x8E
    SET_GATE 19, 0x8E
    SET_GATE 20, 0x8E
    SET_GATE 21, 0x8E
    SET_GATE 22, 0x8E
    SET_GATE 23, 0x8E
    SET_GATE 24, 0x8E
    SET_GATE 25, 0x8E
    SET_GATE 26, 0x8E
    SET_GATE 27, 0x8E
    SET_GATE 28, 0x8E
    SET_GATE 29, 0x8E
    SET_GATE 30, 0x8E
    SET_GATE 31, 0x8E
    SET_GATE 32, 0x8E
    SET_GATE 33, 0x8E

    mov word [idt_ptr], 256 * 16 - 1
    lea rax, [idt_table]
    mov [idt_ptr + 2], rax

    lidt [idt_ptr]

    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

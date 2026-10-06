default rel
%include "syscalls.inc"

global hinux_fmt_u64
global hinux_fmt_hex
global hinux_fmt_bin
global hinux_print_int
global hinux_print_hex
global hinux_print_str
global hinux_print_nl

section .data
nl db 10
hex_chars db "0123456789abcdef"

section .bss
fmt_buf resb 64

section .text

hinux_fmt_u64:
    push rbx
    push r12
    mov rax, rdi
    mov r12, rsi
    mov rbx, 10
    xor rcx, rcx

.loop_div:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .loop_div

.loop_pop:
    pop rax
    mov [r12], al
    inc r12
    dec rcx
    jnz .loop_pop

    mov byte [r12], 0
    mov rax, r12
    pop r12
    pop rbx
    ret

hinux_fmt_hex:
    push r12
    mov r12, rsi
    mov byte [r12], '0'
    mov byte [r12 + 1], 'x'
    add r12, 2
    mov rcx, 16

.loop_hex:
    rol rdi, 4
    mov rax, rdi
    and rax, 0xf
    lea r8, [hex_chars]
    mov al, byte [r8 + rax]
    mov byte [r12], al
    inc r12
    dec rcx
    jnz .loop_hex

    mov byte [r12], 0
    mov rax, r12
    pop r12
    ret

hinux_fmt_bin:
    push r12
    mov r12, rsi
    mov byte [r12], '0'
    mov byte [r12 + 1], 'b'
    add r12, 2
    mov rcx, 64

.loop_bin:
    rol rdi, 1
    mov rax, rdi
    and rax, 1
    add al, '0'
    mov byte [r12], al
    inc r12
    dec rcx
    jnz .loop_bin

    mov byte [r12], 0
    mov rax, r12
    pop r12
    ret

hinux_print_str:
    push rdi
    xor rax, rax
.len_loop:
    cmp byte [rdi + rax], 0
    je .len_done
    inc rax
    jmp .len_loop
.len_done:
    pop rsi
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

hinux_print_int:
    push rdi
    lea rsi, [fmt_buf]
    call hinux_fmt_u64
    lea rdi, [fmt_buf]
    call hinux_print_str
    pop rdi
    ret

hinux_print_hex:
    push rdi
    lea rsi, [fmt_buf]
    call hinux_fmt_hex
    lea rdi, [fmt_buf]
    call hinux_print_str
    pop rdi
    ret

hinux_print_nl:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    ret

default rel
%include "syscalls.inc"

global hinux_term_clear
global hinux_term_cursor
global hinux_term_set_color
global hinux_term_reset
global hinux_term_hide_cursor
global hinux_term_show_cursor
global hinux_term_write_str

section .data
term_clr db 27, "[2J", 27, "[H"
term_clr_len equ $ - term_clr
term_rst db 27, "[0m"
term_rst_len equ $ - term_rst
term_hide db 27, "[?25l"
term_hide_len equ $ - term_hide
term_show db 27, "[?25h"
term_show_len equ $ - term_show

section .bss
term_seq_buf resb 64

section .text

hinux_term_clear:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [term_clr]
    mov rdx, term_clr_len
    syscall
    ret

hinux_term_reset:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [term_rst]
    mov rdx, term_rst_len
    syscall
    ret

hinux_term_hide_cursor:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [term_hide]
    mov rdx, term_hide_len
    syscall
    ret

hinux_term_show_cursor:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [term_show]
    mov rdx, term_show_len
    syscall
    ret

hinux_term_write_str:
    push rdi
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
.len_done:
    pop rsi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

hinux_term_set_color:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx

    lea rbx, [term_seq_buf]
    mov word [rbx], 0x5b1b
    mov byte [rbx + 2], '3'
    mov byte [rbx + 3], '8'
    mov byte [rbx + 4], ';'
    mov byte [rbx + 5], '2'
    mov byte [rbx + 6], ';'
    add rbx, 7

    mov rdi, r12
    call append_u8
    mov byte [rbx], ';'
    inc rbx

    mov rdi, r13
    call append_u8
    mov byte [rbx], ';'
    inc rbx

    mov rdi, r14
    call append_u8
    mov byte [rbx], 'm'
    inc rbx

    lea rsi, [term_seq_buf]
    mov rdx, rbx
    sub rdx, rsi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    pop r14
    pop r13
    pop r12
    pop rbx
    ret

append_u8:
    push rax
    push rdx
    push rcx
    mov rax, rdi
    mov rcx, 10
    cmp rax, 100
    jae .three_digits
    cmp rax, 10
    jae .two_digits

    add al, '0'
    mov [rbx], al
    inc rbx
    jmp .done_u8

.two_digits:
    xor rdx, rdx
    div rcx
    add al, '0'
    mov [rbx], al
    inc rbx
    add dl, '0'
    mov [rbx], dl
    inc rbx
    jmp .done_u8

.three_digits:
    mov r8, 100
    xor rdx, rdx
    div r8
    add al, '0'
    mov [rbx], al
    inc rbx
    mov rax, rdx
    xor rdx, rdx
    div rcx
    add al, '0'
    mov [rbx], al
    inc rbx
    add dl, '0'
    mov [rbx], dl
    inc rbx

.done_u8:
    pop rcx
    pop rdx
    pop rax
    ret

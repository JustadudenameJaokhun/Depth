default rel
%include "syscalls.inc"

global _start

section .data
    msg_elf db ": ELF 64-bit LSB executable, x86-64", 10
    len_elf equ $ - msg_elf
    msg_script db ": script text executable", 10
    len_script equ $ - msg_script
    msg_data db ": data", 10
    len_data equ $ - msg_data
    msg_err db ": cannot open file", 10
    len_err equ $ - msg_err

section .bss
    hdr resb 16

section .text

_start:
    pop rcx
    cmp rcx, 2
    jl .exit_err

    pop rsi
    pop rsi
    mov r12, rsi

    mov rdi, r12
    call strlen
    mov r13, rax

    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, r12
    mov rdx, r13
    syscall

    mov rax, SYS_OPEN
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .err_open
    mov r14, rax

    mov rax, SYS_READ
    mov rdi, r14
    lea rsi, [hdr]
    mov rdx, 16
    syscall

    mov rax, SYS_CLOSE
    mov rdi, r14
    syscall

    cmp byte [hdr], 0x7f
    jne .chk_script
    cmp byte [hdr+1], 'E'
    jne .chk_script
    cmp byte [hdr+2], 'L'
    jne .chk_script
    cmp byte [hdr+3], 'F'
    jne .chk_script

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_elf]
    mov rdx, len_elf
    syscall
    jmp .exit_ok

.chk_script:
    cmp byte [hdr], '#'
    jne .other_data
    cmp byte [hdr+1], '!'
    jne .other_data

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_script]
    mov rdx, len_script
    syscall
    jmp .exit_ok

.other_data:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_data]
    mov rdx, len_data
    syscall
    jmp .exit_ok

.err_open:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_err]
    mov rdx, len_err
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

strlen:
    xor rax, rax
.s_loop:
    cmp byte [rdi + rax], 0
    je .s_done
    inc rax
    jmp .s_loop
.s_done:
    ret

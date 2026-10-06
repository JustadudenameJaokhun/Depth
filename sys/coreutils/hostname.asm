default rel
%include "syscalls.inc"

SYS_SETHOSTNAME equ 170

global _start

section .data
    nl db 10

section .bss
    uts resb 390
    newhost resb 128

section .text

_start:
    pop rcx
    cmp rcx, 1
    jle .show_host

    pop rsi
    pop rsi
    mov rdi, rsi
    call strlen
    mov rsi, rax
    mov rax, SYS_SETHOSTNAME
    syscall
    jmp .exit_ok

.show_host:
    mov rax, SYS_UNAME
    lea rdi, [uts]
    syscall
    test rax, rax
    js .exit_err

    lea r12, [uts + 65]
    mov rdi, r12
    call strlen
    mov rdx, rax

    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, r12
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [nl]
    mov rdx, 1
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

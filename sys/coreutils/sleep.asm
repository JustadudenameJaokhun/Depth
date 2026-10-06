default rel
%include "syscalls.inc"

global _start

section .text

_start:
    mov r12, [rsp]
    cmp r12, 2
    jl .exit_ok

    mov rdi, [rsp + 16]
    xor rax, rax

.parse_loop:
    mov cl, byte [rdi]
    test cl, cl
    jz .do_sleep
    cmp cl, '0'
    jb .exit_err
    cmp cl, '9'
    ja .exit_err
    sub cl, '0'
    imul rax, 10
    movzx rcx, cl
    add rax, rcx
    inc rdi
    jmp .parse_loop

.do_sleep:
    push 0
    push rax
    mov rdi, rsp
    xor rsi, rsi
    mov rax, SYS_NANOSLEEP
    syscall
    add rsp, 16

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

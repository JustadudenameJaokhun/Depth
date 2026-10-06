default rel
%include "syscalls.inc"

global _start

section .text

_start:
    mov r12, [rsp]
    cmp r12, 2
    jl .err

    mov rdi, [rsp + 16]
    xor rax, rax

.parse_pid:
    mov cl, byte [rdi]
    test cl, cl
    jz .do_kill
    cmp cl, '0'
    jb .err
    cmp cl, '9'
    ja .err
    sub cl, '0'
    imul rax, 10
    movzx rcx, cl
    add rax, rcx
    inc rdi
    jmp .parse_pid

.do_kill:
    mov rdi, rax
    mov rsi, SIGTERM
    mov rax, SYS_KILL
    syscall
    test rax, rax
    js .err

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

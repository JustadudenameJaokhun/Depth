default rel
%include "syscalls.inc"

global _start

section .text

_start:
    mov r12, [rsp]
    cmp r12, 3
    jl .err

    mov rdi, [rsp + 16]
    xor rsi, rsi

.parse_octal:
    mov cl, byte [rdi]
    test cl, cl
    jz .do_chmod
    cmp cl, '0'
    jb .err
    cmp cl, '7'
    ja .err
    sub cl, '0'
    shl rsi, 3
    movzx rcx, cl
    or rsi, rcx
    inc rdi
    jmp .parse_octal

.do_chmod:
    mov r13, 2

.loop_files:
    cmp r13, r12
    jge .done

    mov rdi, [rsp + 16 + r13 * 8]
    mov rax, SYS_CHMOD
    syscall
    test rax, rax
    js .err

    inc r13
    jmp .loop_files

.done:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

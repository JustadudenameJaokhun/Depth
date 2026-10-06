default rel
%include "syscalls.inc"

global _start

section .data
nl db 10

section .text

_start:
    mov r12, [rsp]
    lea r13, [rsp + 8]
    lea r13, [r13 + r12 * 8]
    add r13, 8

.loop:
    mov rdi, [r13]
    test rdi, rdi
    jz .done
    call print_env_str
    add r13, 8
    jmp .loop

.done:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

print_env_str:
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop

.len_done:
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    ret

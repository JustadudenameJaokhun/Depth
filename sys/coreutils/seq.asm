default rel
%include "syscalls.inc"

global _start

section .data
nl db 10

section .bss
num_buf resb 32

section .text

_start:
    mov r12, [rsp]
    cmp r12, 2
    jl .err

    mov rdi, [rsp + 16]
    xor rax, rax

.parse_limit:
    mov cl, byte [rdi]
    test cl, cl
    jz .do_seq
    cmp cl, '0'
    jb .err
    cmp cl, '9'
    ja .err
    sub cl, '0'
    imul rax, 10
    movzx rcx, cl
    add rax, rcx
    inc rdi
    jmp .parse_limit

.do_seq:
    mov r13, rax
    mov r14, 1

.loop_seq:
    cmp r14, r13
    jg .done

    mov rdi, r14
    call print_val

    inc r14
    jmp .loop_seq

.done:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

print_val:
    push r14
    mov rax, rdi
    lea r8, [num_buf + 30]
    mov byte [r8 + 1], 0
    mov r9, 10

.d_loop:
    xor rdx, rdx
    div r9
    add dl, '0'
    mov [r8], dl
    dec r8
    test rax, rax
    jnz .d_loop

    inc r8
    mov rdi, r8
    xor rdx, rdx
.len_scan:
    cmp byte [rdi + rdx], 0
    je .out
    inc rdx
    jmp .len_scan

.out:
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall

    pop r14
    ret

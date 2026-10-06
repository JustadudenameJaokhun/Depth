default rel
%include "syscalls.inc"

global _start

section .data
    p1 db "/bin/", 0
    p2 db "/sbin/", 0
    p3 db "/usr/bin/", 0
    p4 db "/usr/sbin/", 0
    nl db 10

section .bss
    buf resb 256

section .text

_start:
    pop rcx
    cmp rcx, 2
    jl .exit_err

    pop rsi
    pop rsi
    mov r12, rsi

    lea rdi, [p1]
    call test_path
    jz .found

    lea rdi, [p2]
    call test_path
    jz .found

    lea rdi, [p3]
    call test_path
    jz .found

    lea rdi, [p4]
    call test_path
    jz .found

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.found:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [buf]
    mov rdx, rbx
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [nl]
    mov rdx, 1
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

test_path:
    lea rsi, [buf]
    mov rbx, 0

.copy_prefix:
    mov al, byte [rdi]
    test al, al
    jz .copy_name
    mov byte [rsi], al
    inc rdi
    inc rsi
    inc rbx
    jmp .copy_prefix

.copy_name:
    mov rdx, r12
.copy_n_loop:
    mov al, byte [rdx]
    test al, al
    jz .done_path
    mov byte [rsi], al
    inc rdx
    inc rsi
    inc rbx
    jmp .copy_n_loop

.done_path:
    mov byte [rsi], 0

    mov rax, SYS_ACCESS
    lea rdi, [buf]
    mov rsi, 1
    syscall
    test rax, rax
    ret

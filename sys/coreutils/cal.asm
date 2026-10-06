default rel
%include "syscalls.inc"

global _start

section .data
    title db "    October 2026   ", 10
    len_title equ $ - title
    days_hdr db "Su Mo Tu We Th Fr Sa", 10
    len_hdr equ $ - days_hdr
    sp2 db "  "
    sp3 db "   "
    sp1 db " "
    nl db 10

section .bss
    num_buf resb 8

section .text

_start:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [title]
    mov rdx, len_title
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [days_hdr]
    mov rdx, len_hdr
    syscall

    mov r12d, 4
    xor ebx, ebx

.pad_days:
    cmp ebx, r12d
    jge .start_month

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [sp3]
    mov rdx, 3
    syscall

    inc ebx
    jmp .pad_days

.start_month:
    mov r13d, 1
    mov r14d, r12d

.day_loop:
    cmp r13d, 31
    jg .cal_fin

    mov eax, r13d
    call print_day

    inc r14d
    cmp r14d, 7
    jne .next_space

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [nl]
    mov rdx, 1
    syscall
    xor r14d, r14d
    jmp .inc_day

.next_space:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [sp1]
    mov rdx, 1
    syscall

.inc_day:
    inc r13d
    jmp .day_loop

.cal_fin:
    test r14d, r14d
    jz .exit_ok

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [nl]
    mov rdx, 1
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

print_day:
    push rax
    cmp eax, 10
    jae .two_digits

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [sp1]
    mov rdx, 1
    syscall

    pop rax
    add al, '0'
    mov byte [num_buf], al
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [num_buf]
    mov rdx, 1
    syscall
    ret

.two_digits:
    pop rax
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [num_buf], al
    mov byte [num_buf + 1], dl
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [num_buf]
    mov rdx, 2
    syscall
    ret

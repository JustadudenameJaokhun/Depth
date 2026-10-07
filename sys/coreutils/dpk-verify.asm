default rel
%include "syscalls.inc"

SYS_OPEN equ 2
SYS_READ equ 0
SYS_CLOSE equ 3

global _start

section .data
    msg_usage db "Usage: dpk-verify <package.dpk>", 10
    msg_usage_len equ $ - msg_usage
    msg_ok db "[HINUX-ASM] Verified DPK archive integrity: VALID", 10
    msg_ok_len equ $ - msg_ok
    msg_fail db "[HINUX-ASM] DPK archive header mismatch or corrupt", 10
    msg_fail_len equ $ - msg_fail

section .bss
    hdr_buf resb 512

section .text

_start:
    pop rcx
    cmp rcx, 2
    jl .show_usage

    pop rdi
    pop rdi

    mov rax, SYS_OPEN
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .show_fail

    mov r8, rax
    mov rax, SYS_READ
    mov rdi, r8
    lea rsi, [hdr_buf]
    mov rdx, 512
    syscall
    mov r9, rax

    mov rax, SYS_CLOSE
    mov rdi, r8
    syscall

    cmp r9, 4
    jl .show_fail

    cmp byte [hdr_buf], 0x1f
    jne .check_tar
    cmp byte [hdr_buf + 1], 0x8b
    je .show_ok

.check_tar:
    cmp r9, 265
    jl .show_fail
    cmp byte [hdr_buf + 257], 'u'
    jne .show_fail
    cmp byte [hdr_buf + 258], 's'
    jne .show_fail
    cmp byte [hdr_buf + 259], 't'
    jne .show_fail
    cmp byte [hdr_buf + 260], 'a'
    jne .show_fail
    cmp byte [hdr_buf + 261], 'r'
    jne .show_fail

.show_ok:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_ok]
    mov rdx, msg_ok_len
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.show_fail:
    mov rax, SYS_WRITE
    mov rdi, 2
    lea rsi, [msg_fail]
    mov rdx, msg_fail_len
    syscall

    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.show_usage:
    mov rax, SYS_WRITE
    mov rdi, 2
    lea rsi, [msg_usage]
    mov rdx, msg_usage_len
    syscall

    mov rax, SYS_EXIT
    mov rdi, 2
    syscall

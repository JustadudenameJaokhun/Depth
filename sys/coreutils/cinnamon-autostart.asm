default rel
%include "syscalls.inc"

SYS_FORK equ 57
SYS_EXECVE equ 59
SYS_WAIT4 equ 61
SYS_NANOSLEEP equ 35

global _start

section .data
    msg_init db "[HINUX-ASM] Initializing Cinnamon Autostart Services...", 10
    msg_init_len equ $ - msg_init
    msg_done db "[HINUX-ASM] Autostart services initialized.", 10
    msg_done_len equ $ - msg_done
    udev_path db "/usr/bin/udevadm", 0
    udev_arg0 db "udevadm", 0
    udev_arg1 db "settle", 0
    udev_arg2 db "--timeout=1", 0
    argv_udev dq udev_arg0, udev_arg1, udev_arg2, 0
    envp_null dq 0

section .text

_start:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_init]
    mov rdx, msg_init_len
    syscall

    mov rax, SYS_FORK
    syscall
    test rax, rax
    js .finish
    jnz .parent_wait

    mov rax, SYS_EXECVE
    lea rdi, [udev_path]
    lea rsi, [argv_udev]
    lea rdx, [envp_null]
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.parent_wait:
    xor rdi, rdi
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    mov rax, SYS_WAIT4
    syscall

.finish:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_done]
    mov rdx, msg_done_len
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

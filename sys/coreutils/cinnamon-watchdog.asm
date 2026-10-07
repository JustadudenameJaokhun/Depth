default rel
%include "syscalls.inc"

SYS_NANOSLEEP equ 35
SYS_KILL equ 62
SYS_WAIT4 equ 61
SYS_GETPID equ 39
SYS_FORK equ 57
SYS_SETSID equ 112

global _start

section .data
    msg_start db "[HINUX-ASM] Cinnamon Watchdog active (pure x86-64 supervisor)", 10
    msg_start_len equ $ - msg_start
    msg_tick db "[HINUX-ASM] Desktop session monitored OK", 10
    msg_tick_len equ $ - msg_tick
    timespec:
        dq 5
        dq 0

section .bss
    rem_timespec resq 2

section .text

_start:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_start]
    mov rdx, msg_start_len
    syscall

    mov rax, SYS_FORK
    syscall
    test rax, rax
    js .exit_err
    jnz .exit_parent

    mov rax, SYS_SETSID
    syscall

.loop:
    mov rax, SYS_NANOSLEEP
    lea rdi, [timespec]
    lea rsi, [rem_timespec]
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_tick]
    mov rdx, msg_tick_len
    syscall

    jmp .loop

.exit_parent:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

default rel
%include "syscalls.inc"

SYS_SYNC equ 162
SYS_REBOOT equ 169
LINUX_REBOOT_MAGIC1 equ 0xfee1dead
LINUX_REBOOT_MAGIC2 equ 672274793
LINUX_REBOOT_CMD_POWER_OFF equ 0x4321fedc

global _start

section .data
    msg db 10, "[HINUX] System poweroff requested. Syncing storage buffers...", 10
    msg_len equ $ - msg

section .text

_start:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg]
    mov rdx, msg_len
    syscall

    mov rax, SYS_SYNC
    syscall

    mov rax, SYS_REBOOT
    mov rdi, LINUX_REBOOT_MAGIC1
    mov rsi, LINUX_REBOOT_MAGIC2
    mov rdx, LINUX_REBOOT_CMD_POWER_OFF
    xor r10, r10
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

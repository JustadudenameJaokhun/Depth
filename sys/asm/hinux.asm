default rel
%include "syscalls.inc"

global hinux_syscall_dispatch
global hinux_fork
global hinux_execve
global hinux_waitpid
global hinux_getpid
global hinux_kill
global hinux_nanosleep
global hinux_pipe
global hinux_dup2
global hinux_reboot

section .text

hinux_syscall_dispatch:
    mov rax, rdi
    mov rdi, rsi
    mov rsi, rdx
    mov rdx, rcx
    mov r10, r8
    mov r8, r9
    syscall
    ret

hinux_fork:
    mov rax, SYS_FORK
    syscall
    ret

hinux_execve:
    mov rax, SYS_EXECVE
    syscall
    ret

hinux_waitpid:
    mov rcx, rdx
    xor r10, r10
    mov rdx, rcx
    mov rax, SYS_WAIT4
    syscall
    ret

hinux_getpid:
    mov rax, SYS_GETPID
    syscall
    ret

hinux_kill:
    mov rax, SYS_KILL
    syscall
    ret

hinux_nanosleep:
    mov rax, SYS_NANOSLEEP
    syscall
    ret

hinux_pipe:
    mov rax, SYS_PIPE
    syscall
    ret

hinux_dup2:
    mov rax, SYS_DUP2
    syscall
    ret

hinux_reboot:
    mov rax, SYS_REBOOT
    syscall
    ret

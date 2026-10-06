default rel
%include "syscalls.inc"

global hinux_sigaction
global hinux_sigprocmask
global hinux_raise
global hinux_sigrestorer

section .text

hinux_sigaction:
    mov r10, 8
    mov rax, SYS_RT_SIGACTION
    syscall
    ret

hinux_sigprocmask:
    mov r10, 8
    mov rax, SYS_RT_SIGPROCMASK
    syscall
    ret

hinux_raise:
    mov r12, rdi
    mov rax, SYS_GETPID
    syscall
    mov rdi, rax
    mov rsi, r12
    mov rax, SYS_KILL
    syscall
    ret

hinux_sigrestorer:
    mov rax, 15
    syscall

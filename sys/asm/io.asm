default rel
%include "syscalls.inc"

global depth_exit
global depth_open_read
global depth_open_write
global depth_close
global depth_read
global depth_write

section .text

depth_exit:
    mov rax, SYS_EXIT
    syscall

depth_open_read:
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    ret

depth_open_write:
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 420
    mov rax, SYS_OPEN
    syscall
    ret

depth_close:
    mov rax, SYS_CLOSE
    syscall
    ret

depth_read:
    mov rax, SYS_READ
    syscall
    ret

depth_write:
    mov rax, SYS_WRITE
    syscall
    ret

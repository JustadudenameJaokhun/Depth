default rel
%include "syscalls.inc"

global hinux_vfs_open_read
global hinux_vfs_open_write
global hinux_vfs_open_append
global hinux_vfs_close
global hinux_vfs_read
global hinux_vfs_write
global hinux_vfs_stat
global hinux_vfs_fsize

section .bss
stat_buf resb 144

section .text

hinux_vfs_open_read:
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    ret

hinux_vfs_open_write:
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 420
    mov rax, SYS_OPEN
    syscall
    ret

hinux_vfs_open_append:
    mov rsi, O_WRONLY | O_CREAT | O_APPEND
    mov rdx, 420
    mov rax, SYS_OPEN
    syscall
    ret

hinux_vfs_close:
    mov rax, SYS_CLOSE
    syscall
    ret

hinux_vfs_read:
    mov rax, SYS_READ
    syscall
    ret

hinux_vfs_write:
    mov rax, SYS_WRITE
    syscall
    ret

hinux_vfs_stat:
    mov rax, SYS_STAT
    syscall
    ret

hinux_vfs_fsize:
    push rbx
    mov rbx, rdi
    mov rax, SYS_FSTAT
    lea rsi, [stat_buf]
    syscall
    test rax, rax
    js .err_fsize
    mov rax, [stat_buf + 48]
    pop rbx
    ret

.err_fsize:
    mov rax, -1
    pop rbx
    ret

default rel
%include "syscalls.inc"

global depth_memcpy
global depth_memset
global depth_mmap
global depth_munmap

section .text

depth_memcpy:
    mov rcx, rdx
    mov rax, rdi
    shr rcx, 3
    rep movsq
    mov rcx, rdx
    and rcx, 7
    rep movsb
    ret

depth_memset:
    mov rcx, rdx
    mov rax, rsi
    mov r8, rdi
    rep stosb
    mov rax, r8
    ret

depth_mmap:
    mov r10, rcx
    mov rax, SYS_MMAP
    syscall
    ret

depth_munmap:
    mov rax, SYS_MUNMAP
    syscall
    ret

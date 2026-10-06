default rel
%include "syscalls.inc"

global _start

section .data
dot db ".", 0
nl db 10

section .bss
dirbuf resb 32768

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jle .use_dot
    mov rdi, [rsp + 16]
    jmp .open_dir

.use_dot:
    lea rdi, [dot]

.open_dir:
    mov rsi, O_RDONLY | O_DIRECTORY
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .err_exit
    mov r13, rax

.getdents_loop:
    mov rax, SYS_GETDENTS64
    mov rdi, r13
    lea rsi, [dirbuf]
    mov rdx, 32768
    syscall
    test rax, rax
    jle .close_and_exit
    mov r14, rax
    xor r15, r15

.entry_loop:
    cmp r15, r14
    jge .getdents_loop
    lea rbx, [dirbuf + r15]
    movzx rdx, word [rbx + 16]
    lea rdi, [rbx + 19]
    push rdx
    call print_line
    pop rdx
    add r15, rdx
    jmp .entry_loop

.close_and_exit:
    mov rax, SYS_CLOSE
    mov rdi, r13
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err_exit:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

print_line:
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
.len_done:
    test rdx, rdx
    jz .nl_only
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
.nl_only:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    ret

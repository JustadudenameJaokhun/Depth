default rel
%include "syscalls.inc"

global _start

section .bss
buf resb 65536

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jg .has_args

    xor rdi, rdi
    call dump_fd
    jmp .exit_ok

.has_args:
    mov r14, 1
    lea r15, [rsp + 16]

.arg_loop:
    cmp r14, r12
    jge .exit_ok
    mov rdi, [r15]
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .next_arg
    mov rdi, rax
    push rdi
    call dump_fd
    pop rdi
    mov rax, SYS_CLOSE
    syscall

.next_arg:
    inc r14
    add r15, 8
    jmp .arg_loop

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

dump_fd:
    mov rbx, rdi
.read_loop:
    mov rax, SYS_READ
    mov rdi, rbx
    lea rsi, [buf]
    mov rdx, 65536
    syscall
    test rax, rax
    jle .dump_done
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [buf]
    syscall
    jmp .read_loop
.dump_done:
    ret

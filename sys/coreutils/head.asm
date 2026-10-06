default rel
%include "syscalls.inc"

global _start

section .bss
headbuf resb 4096

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jg .has_files

    xor rdi, rdi
    call dump_head
    jmp .exit

.has_files:
    mov r14, 1
    lea r15, [rsp + 16]

.file_loop:
    cmp r14, r12
    jge .exit
    mov rdi, [r15]
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .next_file
    mov rdi, rax
    call dump_head
    mov rax, SYS_CLOSE
    syscall

.next_file:
    inc r14
    add r15, 8
    jmp .file_loop

.exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

dump_head:
    push rbx
    mov rbx, rdi
    xor r8, r8

.read_loop:
    cmp r8, 10
    jge .done_dump
    mov rax, SYS_READ
    mov rdi, rbx
    lea rsi, [headbuf]
    mov rdx, 4096
    syscall
    test rax, rax
    jle .done_dump

    mov rcx, rax
    lea rdi, [headbuf]
    xor r9, r9

.scan_loop:
    cmp r9, rcx
    jge .write_chunk
    mov al, byte [rdi + r9]
    inc r9
    cmp al, 10
    jne .scan_loop
    inc r8
    cmp r8, 10
    je .write_chunk
    jmp .scan_loop

.write_chunk:
    push rcx
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [headbuf]
    mov rdx, r9
    syscall
    pop rcx
    cmp r8, 10
    jge .done_dump
    jmp .read_loop

.done_dump:
    pop rbx
    ret

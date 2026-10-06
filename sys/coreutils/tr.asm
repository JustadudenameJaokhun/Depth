default rel
%include "syscalls.inc"

global _start

section .bss
tr_map resb 256
tr_buf resb 8192

section .text

_start:
    mov r12, [rsp]
    cmp r12, 3
    jl .err

    xor rcx, rcx
.init_map:
    mov byte [tr_map + rcx], cl
    inc rcx
    cmp rcx, 256
    jl .init_map

    mov rdi, [rsp + 16]
    mov rsi, [rsp + 24]

.build_map:
    mov al, byte [rdi]
    test al, al
    jz .read_stream
    mov dl, byte [rsi]
    test dl, dl
    jz .read_stream
    movzx rax, al
    mov byte [tr_map + rax], dl
    inc rdi
    inc rsi
    jmp .build_map

.read_stream:
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [tr_buf]
    mov rdx, 8192
    syscall
    test rax, rax
    jle .done

    mov rcx, rax
    lea rdi, [tr_buf]

.translate:
    movzx rax, byte [rdi]
    mov al, byte [tr_map + rax]
    mov byte [rdi], al
    inc rdi
    dec rcx
    jnz .translate

    push rax
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [tr_buf]
    syscall
    pop rax
    jmp .read_stream

.done:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

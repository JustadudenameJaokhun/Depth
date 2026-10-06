default rel
%include "syscalls.inc"

global _start

section .data
space db 32
nl db 10

section .bss
buf resb 16384
num_str resb 32

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jg .has_files

    xor rdi, rdi
    call count_fd
    call print_counts
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
    call count_fd
    call print_counts
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

count_fd:
    push rbx
    mov rbx, rdi
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11

.read_loop:
    mov rax, SYS_READ
    mov rdi, rbx
    lea rsi, [buf]
    mov rdx, 16384
    syscall
    test rax, rax
    jle .done_read

    add r10, rax
    mov rcx, rax
    lea rdi, [buf]

.byte_loop:
    mov al, [rdi]
    cmp al, 10
    jne .check_ws
    inc r8

.check_ws:
    cmp al, ' '
    je .is_ws
    cmp al, 9
    je .is_ws
    cmp al, 10
    je .is_ws
    cmp al, 13
    je .is_ws
    test r11, r11
    jnz .next_byte
    inc r9
    mov r11, 1
    jmp .next_byte

.is_ws:
    xor r11, r11

.next_byte:
    inc rdi
    dec rcx
    jnz .byte_loop
    jmp .read_loop

.done_read:
    pop rbx
    ret

print_counts:
    push r8
    push r9
    push r10

    mov rdi, r8
    call print_num
    call print_space

    pop r10
    pop r9
    push r9
    push r10

    mov rdi, r9
    call print_num
    call print_space

    pop r10
    mov rdi, r10
    call print_num
    call print_nl

    pop r9
    pop r8
    ret

print_num:
    push r12
    push r13
    mov rax, rdi
    lea r12, [num_str + 30]
    mov byte [r12 + 1], 0
    mov r13, 10

.div_loop:
    xor rdx, rdx
    div r13
    add dl, '0'
    mov [r12], dl
    dec r12
    test rax, rax
    jnz .div_loop

    inc r12
    mov rdi, r12
    xor rdx, rdx
.len_l:
    cmp byte [rdi + rdx], 0
    je .len_d
    inc rdx
    jmp .len_l
.len_d:
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    pop r13
    pop r12
    ret

print_space:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [space]
    mov rdx, 1
    syscall
    ret

print_nl:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    ret

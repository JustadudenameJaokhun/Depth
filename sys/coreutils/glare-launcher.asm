default rel
%include "syscalls.inc"

SYS_FORK equ 57
SYS_EXECVE equ 59
SYS_WAIT4 equ 61
SYS_OPEN equ 2
SYS_READ equ 0
SYS_CLOSE equ 3

global _start

section .data
    msg_usage db "Usage: glare-launcher <application_binary|desktop_file>", 10
    msg_usage_len equ $ - msg_usage
    msg_launch db "[HINUX-ASM] Launching desktop application: "
    msg_launch_len equ $ - msg_launch
    newline db 10

section .bss
    buffer resb 4096
    cmd_buf resb 256
    argv_arr resq 16
    envp_arr resq 16

section .text

_start:
    pop rcx
    cmp rcx, 2
    jl .show_usage

    pop rdi
    pop rdi

    mov rsi, rdi
    xor rdx, rdx
.len_loop:
    cmp byte [rsi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
.len_done:

    push rdi
    push rdx
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_launch]
    mov rdx, msg_launch_len
    syscall
    pop rdx
    pop rdi

    push rdi
    push rdx
    mov rax, SYS_WRITE
    mov rsi, rdi
    mov rdi, 1
    syscall
    pop rdx
    pop rdi

    push rdi
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall
    pop rdi

    mov rax, SYS_OPEN
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .direct_exec

    mov r8, rax
    mov rax, SYS_READ
    mov rdi, r8
    lea rsi, [buffer]
    mov rdx, 4095
    syscall
    mov r9, rax

    mov rax, SYS_CLOSE
    mov rdi, r8
    syscall

    test r9, r9
    jle .direct_exec

    xor rcx, rcx
.search_exec:
    cmp rcx, r9
    jge .direct_exec
    cmp byte [buffer + rcx], 'E'
    jne .next_byte
    cmp byte [buffer + rcx + 1], 'x'
    jne .next_byte
    cmp byte [buffer + rcx + 2], 'e'
    jne .next_byte
    cmp byte [buffer + rcx + 3], 'c'
    jne .next_byte
    cmp byte [buffer + rcx + 4], '='
    jne .next_byte

    add rcx, 5
    xor r10, r10
    jmp .copy_cmd

.next_byte:
    inc rcx
    jmp .search_exec

.copy_cmd:
    cmp rcx, r9
    jge .cmd_done
    mov al, [buffer + rcx]
    cmp al, 10
    je .cmd_done
    cmp al, 13
    je .cmd_done
    cmp al, '%'
    je .skip_field
    cmp r10, 254
    jge .cmd_done
    mov [cmd_buf + r10], al
    inc r10
    inc rcx
    jmp .copy_cmd

.skip_field:
    add rcx, 2
    jmp .copy_cmd

.cmd_done:
    mov byte [cmd_buf + r10], 0
.trim_trailing:
    test r10, r10
    jz .direct_exec
    dec r10
    cmp byte [cmd_buf + r10], ' '
    jne .trim_ok
    mov byte [cmd_buf + r10], 0
    jmp .trim_trailing
.trim_ok:
    lea rdi, [cmd_buf]

.direct_exec:
    mov [argv_arr], rdi
    mov qword [argv_arr + 8], 0
    mov qword [envp_arr], 0

    mov rax, SYS_FORK
    syscall
    test rax, rax
    js .err_exit
    jnz .parent_exit

    mov rax, SYS_EXECVE
    lea rsi, [argv_arr]
    lea rdx, [envp_arr]
    syscall

    mov rax, SYS_EXIT
    mov rdi, 127
    syscall

.parent_exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.show_usage:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [msg_usage]
    mov rdx, msg_usage_len
    syscall

.err_exit:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

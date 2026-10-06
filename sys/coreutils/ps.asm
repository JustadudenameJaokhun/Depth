default rel
%include "syscalls.inc"

global _start

section .data
    proc_dir db "/proc", 0
    hdr db "  PID TTY          TIME CMD", 10
    len_hdr equ $ - hdr
    sh_cmd db "sh", 10
    len_sh equ $ - sh_cmd
    init_cmd db "init", 10
    len_init equ $ - init_cmd
    colon db ":"
    space db " "
    nl db 10

section .bss
    dents resb 2048
    comm_path resb 64
    comm_buf resb 64
    num_buf resb 16

section .text

_start:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [hdr]
    mov rdx, len_hdr
    syscall

    mov rax, SYS_OPEN
    lea rdi, [proc_dir]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .exit_ok
    mov r12, rax

.read_dents:
    mov rax, SYS_GETDENTS64
    mov rdi, r12
    lea rsi, [dents]
    mov rdx, 2048
    syscall
    test rax, rax
    jle .close_proc
    mov r13, rax

    xor r14, r14
.dent_loop:
    cmp r14, r13
    jge .read_dents

    lea r15, [dents + r14]
    movzx ebx, word [r15 + 16]
    lea rdi, [r15 + 19]

    call is_numeric
    jz .skip_entry

    mov rdi, 1
    lea rsi, [r15 + 19]
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [space]
    mov rdx, 1
    syscall

    lea rdi, [r15 + 19]
    call read_and_print_comm

.skip_entry:
    add r14, rbx
    jmp .dent_loop

.close_proc:
    mov rax, SYS_CLOSE
    mov rdi, r12
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

is_numeric:
    movzx eax, byte [rdi]
    cmp al, '0'
    jl .not_num
    cmp al, '9'
    jg .not_num
    mov eax, 1
    ret
.not_num:
    xor eax, eax
    ret

read_and_print_comm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    lea rsi, [comm_path]
    mov byte [rsi], '/'
    mov byte [rsi+1], 'p'
    mov byte [rsi+2], 'r'
    mov byte [rsi+3], 'o'
    mov byte [rsi+4], 'c'
    mov byte [rsi+5], '/'
    add rsi, 6

.copy_pid:
    mov al, byte [rdi]
    test al, al
    jz .add_comm
    mov byte [rsi], al
    inc rdi
    inc rsi
    jmp .copy_pid

.add_comm:
    mov byte [rsi], '/'
    mov byte [rsi+1], 'c'
    mov byte [rsi+2], 'o'
    mov byte [rsi+3], 'm'
    mov byte [rsi+4], 'm'
    mov byte [rsi+5], 0

    mov rax, SYS_OPEN
    lea rdi, [comm_path]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .comm_done
    mov r12, rax

    mov rax, SYS_READ
    mov rdi, r12
    lea rsi, [comm_buf]
    mov rdx, 63
    syscall
    test rax, rax
    jle .close_comm
    mov rbx, rax

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [comm_buf]
    mov rdx, rbx
    syscall

.close_comm:
    mov rax, SYS_CLOSE
    mov rdi, r12
    syscall

.comm_done:
    pop r12
    pop rbx
    leave
    ret

strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

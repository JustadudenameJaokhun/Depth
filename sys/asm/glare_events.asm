default rel
%include "syscalls.inc"

global glare_poll_event
global glare_translate_keycode
global glare_set_nonblocking
global glare_get_terminal_size_asm

section .data
    key_up_seq    db 0x1B, '[', 'A', 0
    key_down_seq  db 0x1B, '[', 'B', 0
    key_right_seq db 0x1B, '[', 'C', 0
    key_left_seq  db 0x1B, '[', 'D', 0

section .bss
    event_buf resb 128
    ws_buf resb 8

section .text

glare_poll_event:
    push rbp
    mov rbp, rsp
    push rbx

    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, rdx
    syscall

    pop rbx
    leave
    ret

glare_translate_keycode:
    push rbp
    mov rbp, rsp

    cmp rsi, 1
    je .single_char

    cmp rsi, 3
    jl .unknown

    cmp byte [rdi], 0x1B
    jne .unknown
    cmp byte [rdi+1], '['
    jne .unknown

    mov al, byte [rdi+2]
    cmp al, 'A'
    je .key_up
    cmp al, 'B'
    je .key_down
    cmp al, 'C'
    je .key_right
    cmp al, 'D'
    je .key_left
    jmp .unknown

.single_char:
    movzx eax, byte [rdi]
    leave
    ret

.key_up:
    mov eax, 1001
    leave
    ret

.key_down:
    mov eax, 1002
    leave
    ret

.key_right:
    mov eax, 1003
    leave
    ret

.key_left:
    mov eax, 1004
    leave
    ret

.unknown:
    xor eax, eax
    leave
    ret

glare_set_nonblocking:
    push rbp
    mov rbp, rsp
    mov rax, SYS_FCNTL
    mov rsi, 3
    xor rdx, rdx
    syscall
    test rax, rax
    js .nb_err

    or rax, 0x800
    mov rdx, rax
    mov rax, SYS_FCNTL
    mov rsi, 4
    syscall

.nb_err:
    leave
    ret

glare_get_terminal_size_asm:
    push rbp
    mov rbp, rsp
    mov rax, SYS_IOCTL
    mov rsi, 0x5413
    lea rdx, [ws_buf]
    syscall
    test rax, rax
    js .sz_err

    movzx eax, word [ws_buf + 2]
    mov dword [rdi], eax
    movzx eax, word [ws_buf]
    mov dword [rsi], eax
    mov eax, 1
    leave
    ret

.sz_err:
    mov dword [rdi], 80
    mov dword [rsi], 25
    xor eax, eax
    leave
    ret

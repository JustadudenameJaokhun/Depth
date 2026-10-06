default rel
%include "syscalls.inc"

global _start

section .data
    prefix db "up "
    len_pref equ $ - prefix
    comma db ", "
    day_str db " days, "
    len_days equ $ - day_str
    colon db ":"
    min_str db " min"
    len_min equ $ - min_str
    nl db 10

section .bss
    sinfo resb 112
    num_buf resb 32

section .text

_start:
    mov rax, SYS_SYSINFO
    lea rdi, [sinfo]
    syscall
    test rax, rax
    js .exit_err

    mov r12, qword [sinfo]

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [prefix]
    mov rdx, len_pref
    syscall

    mov rax, r12
    xor edx, edx
    mov ecx, 86400
    div ecx
    mov r13d, eax
    mov r14d, edx

    test r13d, r13d
    jz .hours_mins

    mov eax, r13d
    call print_dec

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [day_str]
    mov rdx, len_days
    syscall

.hours_mins:
    mov eax, r14d
    xor edx, edx
    mov ecx, 3600
    div ecx
    mov r15d, eax
    mov r14d, edx

    call print_dec_pad

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [colon]
    mov rdx, 1
    syscall

    mov eax, r14d
    xor edx, edx
    mov ecx, 60
    div ecx
    call print_dec_pad

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [nl]
    mov rdx, 1
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

print_dec:
    lea rsi, [num_buf + 31]
    mov byte [rsi], 0
    mov rbx, 10
.p_loop:
    xor edx, edx
    div rbx
    add dl, '0'
    dec rsi
    mov byte [rsi], dl
    test rax, rax
    jnz .p_loop

    lea rdx, [num_buf + 31]
    sub rdx, rsi
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    ret

print_dec_pad:
    push rax
    cmp eax, 10
    jae .no_pad
    push rax
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [colon]
    mov byte [rsi], '0'
    mov rdx, 1
    syscall
    pop rax
.no_pad:
    pop rax
    call print_dec
    ret

default rel
%include "syscalls.inc"

global _start

section .data
    header db "               total        used        free", 10
    len_hdr equ $ - header
    mem_lbl db "Mem:     "
    len_lbl equ $ - mem_lbl
    spaces db "   "
    mb_str db "M"
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

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [header]
    mov rdx, len_hdr
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [mem_lbl]
    mov rdx, len_lbl
    syscall

    mov r12, qword [sinfo + 32]
    test r12, r12
    jnz .has_unit
    mov r12, 1
.has_unit:

    mov rax, qword [sinfo + 24]
    mul r12
    shr rax, 20
    call print_val

    mov rax, qword [sinfo + 24]
    sub rax, qword [sinfo + 32]
    mul r12
    shr rax, 20
    call print_val

    mov rax, qword [sinfo + 32]
    mul r12
    shr rax, 20
    call print_val

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

print_val:
    push r12
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

    push rdx
    push rsi
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [spaces]
    mov rdx, 3
    syscall
    pop rsi
    pop rdx

    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [mb_str]
    mov rdx, 1
    syscall

    pop r12
    ret

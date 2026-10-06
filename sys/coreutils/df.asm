default rel
%include "syscalls.inc"

%ifndef SYS_STATFS
SYS_STATFS equ 137
%endif

global _start

section .data
    root_path db "/", 0
    hdr db "Filesystem          Size     Used    Avail Use% Mounted on", 10
    len_hdr equ $ - hdr
    fs_root db "rootfs          "
    len_fs_root equ $ - fs_root
    sp4 db "    "
    sp3 db "   "
    sp2 db "  "
    sp1 db " "
    pct_root db "% /", 10
    len_pct_root equ $ - pct_root
    m_unit db "M"

section .bss
    st_buf resb 128
    num_str resb 32

section .text

_start:
    mov rax, SYS_STATFS
    lea rdi, [root_path]
    lea rsi, [st_buf]
    syscall
    test rax, rax
    js .exit_err

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [hdr]
    mov rdx, len_hdr
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [fs_root]
    mov rdx, len_fs_root
    syscall

    mov r14, qword [st_buf + 8]
    test r14, r14
    jnz .has_bsize
    mov r14, 4096

.has_bsize:
    mov r12, qword [st_buf + 16]
    mov r15, qword [st_buf + 32]
    mov r13, r12
    sub r13, r15

    mov rax, r12
    mul r14
    shr rax, 20
    mov r12, rax
    call print_mb_col

    mov rax, r13
    mul r14
    shr rax, 20
    mov r13, rax
    call print_mb_col

    mov rax, r15
    mul r14
    shr rax, 20
    mov r15, rax
    call print_mb_col

    test r12, r12
    jz .zero_pct
    mov rax, r13
    imul rax, 100
    xor rdx, rdx
    div r12
    jmp .print_pct_num

.zero_pct:
    xor rax, rax

.print_pct_num:
    call print_percent_col

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [pct_root]
    mov rdx, len_pct_root
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

print_mb_col:
    push rax
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rax
    lea rdi, [num_str + 31]
    mov byte [rdi], 0
    mov r8, 0

.conv_loop:
    xor edx, edx
    mov rax, rbx
    mov rsi, 10
    div rsi
    mov rbx, rax
    add dl, '0'
    dec rdi
    mov byte [rdi], dl
    inc r8
    test rbx, rbx
    jnz .conv_loop

    mov r9, 7
    sub r9, r8
    cmp r9, 0
    jle .write_num

.pad_loop:
    push r8
    push r9
    push rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [sp1]
    mov rdx, 1
    syscall
    pop rdi
    pop r9
    pop r8
    dec r9
    jnz .pad_loop

.write_num:
    push r8
    push rdi
    mov rax, SYS_WRITE
    mov rsi, rdi
    mov rdi, STDOUT
    mov rdx, r8
    syscall
    pop rdi
    pop r8

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [m_unit]
    mov rdx, 1
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [sp2]
    mov rdx, 2
    syscall

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rax
    ret

print_percent_col:
    push rax
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rax
    lea rdi, [num_str + 31]
    mov byte [rdi], 0
    mov r8, 0

.conv_pct:
    xor edx, edx
    mov rax, rbx
    mov rsi, 10
    div rsi
    mov rbx, rax
    add dl, '0'
    dec rdi
    mov byte [rdi], dl
    inc r8
    test rbx, rbx
    jnz .conv_pct

    mov r9, 4
    sub r9, r8
    cmp r9, 0
    jle .write_pct

.pad_pct:
    push r8
    push r9
    push rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [sp1]
    mov rdx, 1
    syscall
    pop rdi
    pop r9
    pop r8
    dec r9
    jnz .pad_pct

.write_pct:
    mov rax, SYS_WRITE
    mov rsi, rdi
    mov rdi, STDOUT
    mov rdx, r8
    syscall

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rax
    ret

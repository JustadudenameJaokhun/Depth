default rel
%include "syscalls.inc"

global _start

section .bss
uniq_in resb 16384
uniq_prev resb 1024
uniq_curr resb 1024

section .text

_start:
    mov byte [uniq_prev], 0

.read_chunk:
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [uniq_in]
    mov rdx, 16384
    syscall
    test rax, rax
    jle .done

    mov r12, rax
    xor r13, r13

.line_scan:
    cmp r13, r12
    jge .read_chunk

    lea rdi, [uniq_curr]
    xor r14, r14

.copy_line:
    cmp r13, r12
    jge .compare_lines
    mov al, [uniq_in + r13]
    mov [rdi + r14], al
    inc r13
    inc r14
    cmp al, 10
    je .compare_lines
    jmp .copy_line

.compare_lines:
    mov byte [rdi + r14], 0

    lea rsi, [uniq_prev]
    lea rdi, [uniq_curr]
    call lines_match
    test eax, eax
    jnz .skip_line

    mov rdx, r14
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [uniq_curr]
    syscall

    lea rsi, [uniq_curr]
    lea rdi, [uniq_prev]
    call copy_prev_line

.skip_line:
    jmp .line_scan

.done:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

lines_match:
    xor rcx, rcx
.m_loop:
    mov al, [rdi + rcx]
    mov dl, [rsi + rcx]
    cmp al, dl
    jne .diff
    test al, al
    je .same
    inc rcx
    jmp .m_loop
.diff:
    xor eax, eax
    ret
.same:
    mov eax, 1
    ret

copy_prev_line:
    xor rcx, rcx
.c_loop:
    mov al, [rsi + rcx]
    mov [rdi + rcx], al
    test al, al
    je .c_done
    inc rcx
    jmp .c_loop
.c_done:
    ret

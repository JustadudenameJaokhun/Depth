default rel
%include "syscalls.inc"

global _start

section .bss
    tail_buf resb 65536

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jg .files_arg

    xor rdi, rdi
    call do_tail
    jmp .exit_clean

.files_arg:
    mov r14, 1
    lea r15, [rsp + 16]

.next_file_arg:
    cmp r14, r12
    jge .exit_clean

    mov rdi, [r15]
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .file_skip

    mov rdi, rax
    call do_tail
    mov rax, SYS_CLOSE
    syscall

.file_skip:
    inc r14
    add r15, 8
    jmp .next_file_arg

.exit_clean:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

do_tail:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    xor r12, r12

.fill_tail:
    cmp r12, 65536
    jge .find_last_lines

    mov rax, SYS_READ
    mov rdi, rbx
    lea rsi, [tail_buf + r12]
    mov rdx, 65536
    sub rdx, r12
    syscall
    test rax, rax
    jle .find_last_lines

    add r12, rax
    jmp .fill_tail

.find_last_lines:
    test r12, r12
    jle .tail_done

    mov r13, r12
    dec r13
    cmp byte [tail_buf + r13], 10
    jne .scan_rev
    dec r13

.scan_rev:
    xor ecx, ecx

.rev_loop:
    cmp r13, 0
    jl .output_all
    cmp byte [tail_buf + r13], 10
    jne .rev_dec

    inc ecx
    cmp ecx, 10
    je .found_point

.rev_dec:
    dec r13
    jmp .rev_loop

.found_point:
    inc r13
    lea rsi, [tail_buf + r13]
    mov rdx, r12
    sub rdx, r13
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    jmp .tail_done

.output_all:
    lea rsi, [tail_buf]
    mov rdx, r12
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

.tail_done:
    pop r13
    pop r12
    pop rbx
    ret

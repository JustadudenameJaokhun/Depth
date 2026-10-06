default rel
%include "syscalls.inc"

global _start

section .bss
    in_buf resb 65536
    line_buf resb 4096
    pat_buf resb 256

section .data
    nl db 10

section .text

_start:
    mov r12, [rsp]
    cmp r12, 2
    jl .exit_err

    mov rsi, [rsp + 16]
    call store_pattern
    mov r13d, eax

    cmp r12, 2
    je .run_stdin

    mov r14, 2

.file_args:
    cmp r14, r12
    jge .exit_clean

    mov rdi, [rsp + 8 + r14 * 8]
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .next_file

    mov rdi, rax
    call process_fd
    mov rax, SYS_CLOSE
    syscall

.next_file:
    inc r14
    jmp .file_args

.run_stdin:
    xor rdi, rdi
    call process_fd

.exit_clean:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.exit_err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

store_pattern:
    xor ecx, ecx
.sp_loop:
    mov al, byte [rsi + rcx]
    mov byte [pat_buf + rcx], al
    test al, al
    jz .sp_done
    inc rcx
    cmp rcx, 255
    jl .sp_loop
.sp_done:
    mov eax, ecx
    ret

process_fd:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov ebp, edi
    xor r15d, r15d

.read_cycle:
    mov rax, SYS_READ
    mov edi, ebp
    lea rsi, [in_buf]
    mov rdx, 65536
    syscall
    test rax, rax
    jle .flush_rem

    mov r12, rax
    xor rbx, rbx

.scan_bytes:
    cmp rbx, r12
    jge .read_cycle

    mov al, byte [in_buf + rbx]
    inc rbx

    cmp al, 10
    je .line_complete

    cmp r15d, 4095
    jge .scan_bytes

    lea rdx, [line_buf]
    mov byte [rdx + r15], al
    inc r15d
    jmp .scan_bytes

.line_complete:
    call match_and_print
    xor r15d, r15d
    jmp .scan_bytes

.flush_rem:
    test r15d, r15d
    jz .proc_fin
    call match_and_print

.proc_fin:
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

match_and_print:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    test r13d, r13d
    jz .print_matched

    cmp r15d, r13d
    jl .match_ret

    mov eax, r15d
    sub eax, r13d
    xor ecx, ecx

.outer_chk:
    cmp ecx, eax
    jg .match_ret

    xor edx, edx

.inner_chk:
    cmp edx, r13d
    jge .print_matched

    mov r8, rcx
    add r8, rdx
    mov bl, byte [line_buf + r8]

    lea rdi, [pat_buf]
    cmp bl, byte [rdi + rdx]
    jne .inner_mismatch

    inc edx
    jmp .inner_chk

.inner_mismatch:
    inc ecx
    jmp .outer_chk

.print_matched:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [line_buf]
    mov edx, r15d
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall

.match_ret:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

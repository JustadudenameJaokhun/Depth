default rel
%include "syscalls.inc"

global _start

section .bss
    in_buf resb 4096
    out_buf resb 4096

section .text

_start:
    mov r12, [rsp]
    mov r13d, 1
    mov r14b, 9
    xor r15, r15

    cmp r12, 1
    jle .run_stdin

    mov rbx, 1

.parse_args:
    cmp rbx, r12
    jge .run_stdin

    mov rsi, [rsp + 8 + rbx * 8]
    cmp byte [rsi], '-'
    jne .arg_is_file

    cmp byte [rsi + 1], 'd'
    jne .check_f

    cmp byte [rsi + 2], 0
    jne .d_direct
    inc rbx
    cmp rbx, r12
    jge .run_stdin
    mov rsi, [rsp + 8 + rbx * 8]
    mov r14b, byte [rsi]
    inc rbx
    jmp .parse_args

.d_direct:
    mov r14b, byte [rsi + 2]
    inc rbx
    jmp .parse_args

.check_f:
    cmp byte [rsi + 1], 'f'
    jne .unknown_opt

    cmp byte [rsi + 2], 0
    jne .f_direct
    inc rbx
    cmp rbx, r12
    jge .run_stdin
    mov rsi, [rsp + 8 + rbx * 8]
    call parse_int
    mov r13d, eax
    inc rbx
    jmp .parse_args

.f_direct:
    add rsi, 2
    call parse_int
    mov r13d, eax
    inc rbx
    jmp .parse_args

.arg_is_file:
    mov r15, rsi
    inc rbx
    jmp .parse_args

.unknown_opt:
    inc rbx
    jmp .parse_args

.run_stdin:
    test r15, r15
    jnz .open_file

    xor rdi, rdi
    call process_fd
    jmp .exit_clean

.open_file:
    mov rdi, r15
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .exit_clean

    mov rdi, rax
    call process_fd
    mov rax, SYS_CLOSE
    syscall

.exit_clean:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

parse_int:
    xor eax, eax
.pi_loop:
    movzx ecx, byte [rsi]
    cmp cl, '0'
    jb .pi_done
    cmp cl, '9'
    ja .pi_done
    sub cl, '0'
    imul eax, eax, 10
    add eax, ecx
    inc rsi
    jmp .pi_loop
.pi_done:
    ret

process_fd:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov ebp, edi
    mov r8d, 1
    xor r9d, r9d

.read_more:
    mov rax, SYS_READ
    mov edi, ebp
    lea rsi, [in_buf]
    mov rdx, 4096
    syscall
    test rax, rax
    jle .proc_done

    mov r12, rax
    xor rbx, rbx

.scan_byte:
    cmp rbx, r12
    jge .read_more

    mov al, byte [in_buf + rbx]
    inc rbx

    cmp al, 10
    je .handle_nl

    cmp al, r14b
    je .handle_delim

    cmp r8d, r13d
    jne .scan_byte

    call emit_byte
    jmp .scan_byte

.handle_delim:
    inc r8d
    jmp .scan_byte

.handle_nl:
    mov al, 10
    call emit_byte
    mov r8d, 1
    jmp .scan_byte

.proc_done:
    test r9d, r9d
    jle .cleanup_done
    call flush_out

.cleanup_done:
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

emit_byte:
    push rbx
    push rcx
    lea rcx, [out_buf]
    mov byte [rcx + r9], al
    inc r9d
    cmp r9d, 4096
    jl .eb_ret
    call flush_out
.eb_ret:
    pop rcx
    pop rbx
    ret

flush_out:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    push r11
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [out_buf]
    mov edx, r9d
    syscall
    xor r9d, r9d
    pop r11
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

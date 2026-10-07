global _start

section .rodata
    color_red db 27, "[1;31m", 0
    color_bold db 27, "[1m", 0
    color_reset db 27, "[0m", 0

    msg_banner db 27, "[1;31m=== Depth Hinux Root Actions (rac) === ", 27, "[0m", 10, 0
    msg_usage db "Usage: rac <command> [args...]", 10
              db "       rac dive install <package>", 10
              db "       rac depthpart list", 10, 0
    msg_err_exec db 27, "[1;31m[RAC ERROR]", 27, "[0m Command execution failed: ", 0
    msg_err_perm db 27, "[1;31m[RAC ERROR]", 27, "[0m Failed to acquire root authorization", 10, 0
    newline db 10, 0

    bin_prefix db "/bin/", 0
    usr_prefix db "/usr/bin/", 0
    sbin_prefix db "/sbin/", 0

    env_home db "HOME=/root", 0
    env_user db "USER=root", 0
    env_logname db "LOGNAME=root", 0
    env_path db "PATH=/bin:/sbin:/usr/bin:/usr/sbin", 0
    env_term db "TERM=linux", 0

section .data
    envp dq env_home, env_user, env_logname, env_path, env_term, 0

section .bss
    cmd_path resb 512
    cmd_args resq 64

section .text

_start:
    pop r14
    cmp r14, 2
    jl .show_usage

    pop rsi
    pop rbx

    mov r12, cmd_args
    mov [r12], rbx
    add r12, 8

    sub r14, 2
.copy_args:
    test r14, r14
    jz .args_done
    pop rsi
    mov [r12], rsi
    add r12, 8
    dec r14
    jmp .copy_args

.args_done:
    mov qword [r12], 0

    mov rax, 105
    xor rdi, rdi
    syscall

    mov rax, 106
    xor rdi, rdi
    syscall

    mov rax, 116
    xor rdi, rdi
    xor rsi, rsi
    syscall

    mov rsi, rbx
.check_slash:
    lodsb
    test al, al
    jz .no_slash
    cmp al, '/'
    je .has_slash
    jmp .check_slash

.has_slash:
    mov rdi, cmd_path
    mov rsi, rbx
    call str_copy
    jmp .do_exec

.no_slash:
    mov rdi, cmd_path
    mov rsi, bin_prefix
    call str_copy
    dec rdi
    mov rsi, rbx
    call str_copy

    mov rax, 21
    mov rdi, cmd_path
    mov rsi, 1
    syscall
    test rax, rax
    jz .do_exec

    mov rdi, cmd_path
    mov rsi, usr_prefix
    call str_copy
    dec rdi
    mov rsi, rbx
    call str_copy

    mov rax, 21
    mov rdi, cmd_path
    mov rsi, 1
    syscall
    test rax, rax
    jz .do_exec

    mov rdi, cmd_path
    mov rsi, sbin_prefix
    call str_copy
    dec rdi
    mov rsi, rbx
    call str_copy

.do_exec:
    mov rax, 59
    mov rdi, cmd_path
    mov rsi, cmd_args
    mov rdx, envp
    syscall

    mov rdi, msg_err_exec
    call print_str
    mov rdi, cmd_path
    call print_str
    mov rdi, newline
    call print_str

    mov edi, 127
    mov eax, 60
    syscall

.show_usage:
    mov rdi, msg_banner
    call print_str
    mov rdi, msg_usage
    call print_str
    mov edi, 1
    mov eax, 60
    syscall

.fail_perm:
    mov rdi, msg_err_perm
    call print_str
    mov edi, 1
    mov eax, 60
    syscall

print_str:
    push rdi
    push rsi
    push rdx
    push rax
    xor rdx, rdx
.count:
    cmp byte [rdi + rdx], 0
    jz .done_count
    inc rdx
    jmp .count
.done_count:
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

str_copy:
    push rax
.cpy:
    lodsb
    stosb
    test al, al
    jnz .cpy
    pop rax
    ret

global _start

section .rodata
    color_crimson db 27, "[38;2;220;20;60m", 0
    color_gold db 27, "[1;33m", 0
    color_bold db 27, "[1m", 0
    color_reset db 27, "[0m", 0
    color_cyan db 27, "[1;36m", 0

    msg_box_top db 27, "[38;2;220;20;60m+======================================================================+", 27, "[0m", 10, 0
    msg_box_elev db 27, "[38;2;220;20;60m| ", 27, "[1;33m[HIGH SECURITY ALERT]", 27, "[38;2;220;20;60m RAC PRIVILEGE ELEVATION GRANTED               |", 27, "[0m", 10, 0
    msg_box_shell db 27, "[38;2;220;20;60m| ", 27, "[1;33m[HIGH SECURITY ALERT]", 27, "[38;2;220;20;60m RAC INTERACTIVE ROOT SHELL GRANTED            |", 27, "[0m", 10, 0
    msg_box_info db 27, "[38;2;220;20;60m| Node: depth-hinux | Target: ROOT (UID 0) | Kernel Ring 0/Ring 3 Auth |", 27, "[0m", 10, 0
    msg_box_bot db 27, "[38;2;220;20;60m+======================================================================+", 27, "[0m", 10, 0

    msg_version db "rac (Root Actions Controller) - Depth Hinux x86_64", 10
                db "Pure Assembly High-Security Privilege Engine", 10, 0

    msg_status db 27, "[1;32m[RAC STATUS]", 27, "[0m UID=0 EUID=0 GID=0 EGID=0 System Authorization Active", 10, 0

    msg_usage db "Usage: rac <command> [args...]", 10
              db "       rac -i | -s | sh     (interactive root shell)", 10
              db "       rac --status         (privilege status check)", 10
              db "       rac -v | --version   (version information)", 10, 0

    msg_err_exec db 27, "[1;31m[RAC ERROR]", 27, "[0m Command execution failed: ", 0
    msg_err_perm db 27, "[1;31m[RAC ERROR]", 27, "[0m Failed to acquire root authorization", 10, 0
    newline db 10, 0

    bin_prefix db "/bin/", 0
    usr_prefix db "/usr/bin/", 0
    sbin_prefix db "/sbin/", 0
    bash_path db "/bin/bash", 0

    run_dir db "/run/hinux", 0
    log_path db "/run/hinux/security.log", 0
    log_prefix db "[RAC AUDIT] Command executed: ", 0
    log_prefix_len equ $ - log_prefix
    log_shell_msg db "[RAC AUDIT] Interactive root shell launched", 10, 0
    log_shell_len equ $ - log_shell_msg

    opt_i db "-i", 0
    opt_s db "-s", 0
    opt_sh db "sh", 0
    opt_v db "-v", 0
    opt_version db "--version", 0
    opt_status db "--status", 0

    env_home db "HOME=/root", 0
    env_user db "USER=root", 0
    env_logname db "LOGNAME=root", 0
    env_path db "PATH=/bin:/sbin:/usr/bin:/usr/sbin", 0
    env_term db "TERM=xterm-256color", 0
    env_ps1 db "PS1=\[\033[1;31m\]depth-hinux \[\033[0;31m\]\w\[\033[1;31m\] # \[\033[0m\] ", 0

section .data
    envp dq env_home, env_user, env_logname, env_path, env_term, env_ps1, 0
    bash_args dq bash_path, 0

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

    mov rdi, rbx
    mov rsi, opt_v
    call str_cmp
    test eax, eax
    jz .show_version

    mov rdi, rbx
    mov rsi, opt_version
    call str_cmp
    test eax, eax
    jz .show_version

    mov rdi, rbx
    mov rsi, opt_status
    call str_cmp
    test eax, eax
    jz .show_status

    mov rdi, rbx
    mov rsi, opt_i
    call str_cmp
    test eax, eax
    jz .do_interactive

    mov rdi, rbx
    mov rsi, opt_s
    call str_cmp
    test eax, eax
    jz .do_interactive

    mov rdi, rbx
    mov rsi, opt_sh
    call str_cmp
    test eax, eax
    jz .do_interactive

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

    call print_alert_banner

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
    jmp .do_log_and_exec

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
    jz .do_log_and_exec

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
    jz .do_log_and_exec

    mov rdi, cmd_path
    mov rsi, sbin_prefix
    call str_copy
    dec rdi
    mov rsi, rbx
    call str_copy

.do_log_and_exec:
    call log_command_exec

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

.do_interactive:
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

    call print_shell_banner
    call log_shell_exec

    mov rax, 59
    mov rdi, bash_path
    mov rsi, bash_args
    mov rdx, envp
    syscall

    mov rdi, msg_err_exec
    call print_str
    mov rdi, bash_path
    call print_str
    mov rdi, newline
    call print_str

    mov edi, 127
    mov eax, 60
    syscall

.show_version:
    mov rdi, msg_version
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

.show_status:
    mov rdi, msg_status
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

.show_usage:
    mov rdi, msg_box_top
    call print_str
    mov rdi, msg_box_elev
    call print_str
    mov rdi, msg_box_info
    call print_str
    mov rdi, msg_box_bot
    call print_str
    mov rdi, msg_usage
    call print_str
    mov edi, 1
    mov eax, 60
    syscall

print_alert_banner:
    push rdi
    mov rdi, msg_box_top
    call print_str
    mov rdi, msg_box_elev
    call print_str
    mov rdi, msg_box_info
    call print_str
    mov rdi, msg_box_bot
    call print_str
    pop rdi
    ret

print_shell_banner:
    push rdi
    mov rdi, msg_box_top
    call print_str
    mov rdi, msg_box_shell
    call print_str
    mov rdi, msg_box_info
    call print_str
    mov rdi, msg_box_bot
    call print_str
    pop rdi
    ret

log_command_exec:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, 83
    mov rdi, run_dir
    mov rsi, 493
    syscall
    mov rax, 2
    mov rdi, log_path
    mov rsi, 1089
    mov rdx, 416
    syscall
    test rax, rax
    js .log_done
    mov r8, rax
    mov rax, 1
    mov rdi, r8
    mov rsi, log_prefix
    mov rdx, log_prefix_len
    syscall
    mov rdi, cmd_path
    xor rdx, rdx
.len_cmd:
    cmp byte [rdi + rdx], 0
    jz .write_cmd
    inc rdx
    jmp .len_cmd
.write_cmd:
    mov rax, 1
    mov rdi, r8
    mov rsi, cmd_path
    syscall
    mov rax, 1
    mov rdi, r8
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 3
    mov rdi, r8
    syscall
.log_done:
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

log_shell_exec:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, 83
    mov rdi, run_dir
    mov rsi, 493
    syscall
    mov rax, 2
    mov rdi, log_path
    mov rsi, 1089
    mov rdx, 416
    syscall
    test rax, rax
    js .log_sh_done
    mov r8, rax
    mov rax, 1
    mov rdi, r8
    mov rsi, log_shell_msg
    mov rdx, log_shell_len
    syscall
    mov rax, 3
    mov rdi, r8
    syscall
.log_sh_done:
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

str_cmp:
    push rbx
.cmp_loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .cmp_diff
    test al, al
    jz .cmp_eq
    inc rdi
    inc rsi
    jmp .cmp_loop
.cmp_diff:
    mov eax, 1
    pop rbx
    ret
.cmp_eq:
    xor eax, eax
    pop rbx
    ret

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

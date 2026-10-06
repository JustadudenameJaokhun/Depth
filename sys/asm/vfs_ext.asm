default rel
%include "syscalls.inc"

global vfs_get_file_size
global vfs_path_is_dir
global vfs_path_extension
global vfs_path_strip_trailing_slash

section .bss
    stat_buf resb 144

section .text

vfs_get_file_size:
    push rbp
    mov rbp, rsp
    mov rax, SYS_STAT
    lea rsi, [stat_buf]
    syscall
    test rax, rax
    js .stat_err

    mov rax, qword [stat_buf + 48]
    leave
    ret

.stat_err:
    mov rax, -1
    leave
    ret

vfs_path_is_dir:
    push rbp
    mov rbp, rsp
    mov rax, SYS_STAT
    lea rsi, [stat_buf]
    syscall
    test rax, rax
    js .not_dir

    mov eax, dword [stat_buf + 24]
    and eax, 0xF000
    cmp eax, 0x4000
    sete al
    movzx eax, al
    leave
    ret

.not_dir:
    xor eax, eax
    leave
    ret

vfs_path_extension:
    push rbp
    mov rbp, rsp
    mov r8, rdi
    call strlen
    test rax, rax
    jz .no_ext

    lea rsi, [r8 + rax]
.ext_search:
    cmp rsi, r8
    jle .no_ext
    dec rsi
    cmp byte [rsi], '.'
    je .found_ext
    cmp byte [rsi], '/'
    je .no_ext
    jmp .ext_search

.found_ext:
    inc rsi
    mov rax, rsi
    leave
    ret

.no_ext:
    xor rax, rax
    leave
    ret

vfs_path_strip_trailing_slash:
    push rbp
    mov rbp, rsp
    mov r8, rdi
    call strlen
    cmp rax, 1
    jle .strip_done

    lea rsi, [r8 + rax - 1]
    cmp byte [rsi], '/'
    jne .strip_done
    mov byte [rsi], 0

.strip_done:
    leave
    ret

strlen:
    xor rax, rax
.s_loop:
    cmp byte [rdi + rax], 0
    je .s_done
    inc rax
    jmp .s_loop
.s_done:
    ret

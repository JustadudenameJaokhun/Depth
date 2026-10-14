default rel

global _start

section .rodata
    needle_power db "power", 0
    needle_shutdown db "shutdown", 0
    needle_off db "off", 0
    needle_reboot db "reboot", 0
    needle_restart db "restart", 0
    needle_lock db "lock", 0
    needle_logout db "logout", 0

    msg_usage db "Depth Hinux Session Controller (session-ctrl)", 10
              db "Usage: session-ctrl [--power-off | --reboot | --logout | --lock]", 10, 0

    msg_poweroff db 10, "[DEPTH] Safe system poweroff initiated. Syncing storage...", 10, 0
    msg_reboot db 10, "[DEPTH] Safe system reboot initiated. Syncing storage...", 10, 0
    msg_lock db "[DEPTH] Locking session...", 10, 0

    term_path db "/usr/bin/gnome-terminal", 0
    term_arg0 db "gnome-terminal", 0
    term_arg1 db "--full-screen", 0
    term_arg2 db "--title=Depth Hinux Lockscreen", 0
    term_arg3 db "--", 0
    term_arg4 db "/bin/depth-lock", 0

    lock_path db "/bin/depth-lock", 0
    pkill_path db "/usr/bin/pkill", 0
    pkill_arg0 db "pkill", 0
    pkill_arg1 db "-9", 0
    pkill_arg2 db "cinnamon-session", 0

    env_display db "DISPLAY=:0", 0
    env_home db "HOME=/root", 0
    env_user db "USER=root", 0
    env_path db "PATH=/bin:/sbin:/usr/bin:/usr/sbin", 0

section .data
    term_args dq term_arg0, term_arg1, term_arg2, term_arg3, term_arg4, 0
    lock_args dq lock_path, 0
    pkill_args dq pkill_arg0, pkill_arg1, pkill_arg2, 0
    envp dq env_display, env_home, env_user, env_path, 0

section .bss
    status_buf resd 1

section .text

_start:
    pop r14
    cmp r14, 1
    jle .show_usage

    pop rsi

.scan_args:
    dec r14
    test r14, r14
    jz .show_usage

    pop r12

    mov rdi, r12
    lea rsi, [needle_power]
    call str_contains
    test eax, eax
    jnz .do_poweroff

    mov rdi, r12
    lea rsi, [needle_shutdown]
    call str_contains
    test eax, eax
    jnz .do_poweroff

    mov rdi, r12
    lea rsi, [needle_off]
    call str_contains
    test eax, eax
    jnz .do_poweroff

    mov rdi, r12
    lea rsi, [needle_reboot]
    call str_contains
    test eax, eax
    jnz .do_reboot

    mov rdi, r12
    lea rsi, [needle_restart]
    call str_contains
    test eax, eax
    jnz .do_reboot

    mov rdi, r12
    lea rsi, [needle_lock]
    call str_contains
    test eax, eax
    jnz .do_lock

    mov rdi, r12
    lea rsi, [needle_logout]
    call str_contains
    test eax, eax
    jnz .do_logout

    jmp .scan_args

.do_poweroff:
    lea rdi, [msg_poweroff]
    call print_str
    mov eax, 162
    syscall
    mov eax, 169
    mov rdi, 0xfee1dead
    mov rsi, 672274793
    mov rdx, 0x4321fedc
    xor r10, r10
    syscall
    xor edi, edi
    mov eax, 60
    syscall

.do_reboot:
    lea rdi, [msg_reboot]
    call print_str
    mov eax, 162
    syscall
    mov eax, 169
    mov rdi, 0xfee1dead
    mov rsi, 672274793
    mov rdx, 0x01234567
    xor r10, r10
    syscall
    xor edi, edi
    mov eax, 60
    syscall

.do_lock:
    lea rdi, [msg_lock]
    call print_str
    mov eax, 57
    syscall
    test eax, eax
    jz .lock_child
    xor edi, edi
    mov eax, 60
    syscall

.lock_child:
    mov eax, 112
    syscall
    mov eax, 59
    lea rdi, [term_path]
    lea rsi, [term_args]
    lea rdx, [envp]
    syscall
    mov eax, 59
    lea rdi, [lock_path]
    lea rsi, [lock_args]
    lea rdx, [envp]
    syscall
    mov eax, 60
    mov edi, 1
    syscall

.do_logout:
    mov eax, 57
    syscall
    test eax, eax
    jz .logout_kill
    mov eax, 57
    syscall
    test eax, eax
    jz .lock_child
    xor edi, edi
    mov eax, 60
    syscall

.logout_kill:
    mov eax, 59
    lea rdi, [pkill_path]
    lea rsi, [pkill_args]
    lea rdx, [envp]
    syscall
    mov eax, 60
    xor edi, edi
    syscall

.show_usage:
    lea rdi, [msg_usage]
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

str_contains:
    push rbx
    push rcx
    push rdx
.search_outer:
    mov r8, rdi
    mov r9, rsi
.match_inner:
    mov al, [r9]
    test al, al
    jz .found
    mov bl, [r8]
    test bl, bl
    jz .not_found
    cmp al, bl
    jne .next_char
    inc r8
    inc r9
    jmp .match_inner
.next_char:
    inc rdi
    cmp byte [rdi], 0
    jnz .search_outer
.not_found:
    xor eax, eax
    pop rdx
    pop rcx
    pop rbx
    ret
.found:
    mov eax, 1
    pop rdx
    pop rcx
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

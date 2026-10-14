default rel

global _start

section .rodata
    ansi_clear db 27, "[2J", 27, "[H", 0
    ansi_hide_cursor db 27, "[?25l", 0
    ansi_show_cursor db 27, "[?25h", 0
    ansi_reset db 27, "[0m", 0
    ansi_crimson db 27, "[38;2;220;20;60m", 0
    ansi_gold db 27, "[1;33m", 0
    ansi_white db 27, "[1;37m", 0
    ansi_dim db 27, "[38;2;160;160;160m", 0
    ansi_green db 27, "[1;32m", 0
    ansi_red db 27, "[1;31m", 0

    lock_banner:
        db 10
        db 27, "[38;2;220;20;60m"
        db "  ██████╗ ███████╗██████╗ ████████╗██╗  ██╗   ██╗  ██╗██╗███╗   ██╗██╗   ██╗██╗  ██╗", 10
        db "  ██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██║  ██║   ██║  ██║██║████╗  ██║██║   ██║╚██╗██╔╝", 10
        db "  ██║  ██║█████╗  ██████╔╝   ██║   ███████║   ███████║██║██╔██╗ ██║██║   ██║ ╚███╔╝ ", 10
        db "  ██║  ██║██╔══╝  ██╔═══╝    ██║   ██╔══██║   ██╔══██║██║██║╚██╗██║██║   ██║ ██╔██╗ ", 10
        db "  ██████╔╝███████╗██║        ██║   ██║  ██║   ██║  ██║██║██║ ╚████║╚██████╔╝██╔╝ ██╗", 10
        db "  ╚═════╝ ╚══════╝╚═╝        ╚═╝   ╚═╝  ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝", 10
        db 27, "[0m", 10
        db 27, "[1;37m                       === DEPTH HINUX SESSION LOCKED ===                       ", 27, "[0m", 10
        db 27, "[38;2;160;160;160m             Hotkeys: [S] Shutdown   [R] Reboot   [Credentials] Unlock          ", 27, "[0m", 10
        db 10, 0

    prompt_str db 27, "[1;31mDepth Hinux Password: ", 27, "[0m", 0
    bs_str db 8, 32, 8, 0
    star_str db "*", 0
    newline_str db 10, 0

    msg_shutdown db 10, 27, "[1;33m[DEPTH] Safe system poweroff initiated. Syncing buffers...", 27, "[0m", 10, 0
    msg_reboot db 10, 27, "[1;33m[DEPTH] Safe system reboot initiated. Syncing buffers...", 27, "[0m", 10, 0
    msg_granted db 10, 27, "[1;32m[Access Granted] Session Unlocked. Returning to Glare...", 27, "[0m", 10, 0
    msg_denied db 10, 27, "[1;31m[Access Denied] Invalid Credentials.", 27, "[0m", 10, 0

    pass_target db "3d", 0

    sleep_spec:
        dq 1
        dq 0

section .bss
    termios_orig resb 64
    termios_raw resb 64
    has_termios resb 1
    input_buf resb 64
    buf_len resd 1
    char_in resb 1

section .text

_start:
    call setup_terminal

.draw_screen:
    mov rdi, ansi_clear
    call print_str
    mov rdi, lock_banner
    call print_str
    mov rdi, prompt_str
    call print_str

    mov dword [buf_len], 0

.input_loop:
    mov rax, 0
    mov rdi, 0
    lea rsi, [char_in]
    mov rdx, 1
    syscall

    cmp rax, 1
    jne .input_loop

    movzx eax, byte [char_in]

    cmp al, 10
    je .check_password
    cmp al, 13
    je .check_password

    cmp al, 8
    je .handle_backspace
    cmp al, 127
    je .handle_backspace

    cmp dword [buf_len], 0
    jne .normal_char

    cmp al, 'S'
    je .do_poweroff
    cmp al, 's'
    je .do_poweroff
    cmp al, 'R'
    je .do_reboot
    cmp al, 'r'
    je .do_reboot

.normal_char:
    cmp al, 32
    jl .input_loop
    cmp al, 126
    jg .input_loop

    mov edx, [buf_len]
    cmp edx, 60
    jge .input_loop

    lea rdi, [input_buf]
    mov [rdi + rdx], al
    inc edx
    mov [buf_len], edx

    mov rdi, star_str
    call print_str
    jmp .input_loop

.handle_backspace:
    mov edx, [buf_len]
    test edx, edx
    jz .input_loop
    dec edx
    mov [buf_len], edx
    mov rdi, bs_str
    call print_str
    jmp .input_loop

.check_password:
    mov edx, [buf_len]
    lea rdi, [input_buf]
    mov byte [rdi + rdx], 0

    cmp edx, 2
    jne .pwd_fail
    cmp byte [rdi], '3'
    jne .pwd_fail
    cmp byte [rdi + 1], 'd'
    jne .pwd_fail

.pwd_success:
    mov rdi, msg_granted
    call print_str
    call restore_terminal
    mov rdi, ansi_show_cursor
    call print_str
    mov rdi, ansi_clear
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

.pwd_fail:
    mov rdi, msg_denied
    call print_str
    mov eax, 35
    lea rdi, [sleep_spec]
    xor rsi, rsi
    syscall
    jmp .draw_screen

.do_poweroff:
    mov rdi, msg_shutdown
    call print_str
    call restore_terminal
    mov eax, 162
    syscall
    mov eax, 169
    mov rdi, 0xfee1dead
    mov rsi, 672274793
    mov rdx, 0x4321fedc
    xor r10, r10
    syscall
    mov eax, 60
    xor edi, edi
    syscall

.do_reboot:
    mov rdi, msg_reboot
    call print_str
    call restore_terminal
    mov eax, 162
    syscall
    mov eax, 169
    mov rdi, 0xfee1dead
    mov rsi, 672274793
    mov rdx, 0x01234567
    xor r10, r10
    syscall
    mov eax, 60
    xor edi, edi
    syscall

setup_terminal:
    push rbp
    mov rbp, rsp
    mov byte [has_termios], 0
    mov eax, 16
    mov edi, 0
    mov esi, 0x5401
    lea rdx, [termios_orig]
    syscall
    test eax, eax
    jnz .no_term

    mov byte [has_termios], 1
    lea rsi, [termios_orig]
    lea rdi, [termios_raw]
    mov ecx, 15
    rep movsd

    lea rbx, [termios_raw]
    mov eax, [rbx + 12]
    and eax, ~0x000a
    mov [rbx + 12], eax

    mov byte [rbx + 23], 1
    mov byte [rbx + 22], 0

    mov eax, 16
    mov edi, 0
    mov esi, 0x5402
    lea rdx, [termios_raw]
    syscall

.no_term:
    mov rdi, ansi_hide_cursor
    call print_str
    leave
    ret

restore_terminal:
    push rbp
    mov rbp, rsp
    cmp byte [has_termios], 1
    jne .term_done
    mov eax, 16
    mov edi, 0
    mov esi, 0x5402
    lea rdx, [termios_orig]
    syscall
.term_done:
    leave
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

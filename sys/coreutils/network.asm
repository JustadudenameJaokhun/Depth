default rel

section .rodata
    color_red db 27, "[38;2;230;25;25m", 0
    color_dark db 27, "[38;2;140;20;20m", 0
    color_dim db 27, "[38;2;100;100;100m", 0
    color_bold db 27, "[1m", 0
    color_reset db 27, "[0m", 0

    clear_screen db 27, "[2J", 27, "[H", 0

    header_msg db 10, "=============================================================", 10, 0
    banner_l1  db "    ███▄", 10, 0
    banner_l2  db "    ██████▄      DEPTH HINUX NETWORK MANAGER [x86_64 ASM]", 10, 0
    banner_l3  db "    █████████▄   Node: dimensions | Hardware Interface Control", 10, 0
    banner_l4  db "=============================================================", 10, 10, 0

    menu_iface_title db "  Detected Network Interfaces in /proc/net/dev:", 10, 0
    menu_iface_eth0  db "  [*] eth0    (QEMU Virtual / PCI Ethernet)", 10, 0
    menu_iface_lo    db "  [*] lo      (Software Loopback Device)", 10, 10, 0

    menu_actions_title db "  Available Operations:", 10, 0
    menu_act_1 db "  [1] Auto-Configure QEMU Virtual Gateway (DHCP Connect)", 10, 0
    menu_act_2 db "  [2] Configure DNS Nameservers (10.0.2.3, 1.1.1.1, 8.8.8.8)", 10, 0
    menu_act_3 db "  [3] Test Network Link Connectivity", 10, 0
    menu_act_4 db "  [4] Launch Dive Package Engine (-search available apps)", 10, 0
    menu_act_5 db "  [5] Exit Network Console", 10, 10, 0

    menu_prompt db "  Select operation [1-5]: ", 0

    net_up_msg1 db 10, "[HINUX NET] Bringing up interface eth0...", 10, 0
    net_up_msg2 db "[HINUX NET] Assigning IP: 10.0.2.15/24...", 10, 0
    net_up_msg3 db "[HINUX NET] Setting default gateway: 10.0.2.2...", 10, 0
    net_up_msg4 db "[HINUX NET] Updating /etc/resolv.conf nameservers...", 10, 0
    net_ok_msg  db "[HINUX NET] Internet connection ESTABLISHED on eth0!", 10, 0
    net_press_key db 10, "Press ENTER to return to menu...", 0

    resolv_path db "/etc/resolv.conf", 0
    resolv_content db "nameserver 10.0.2.3", 10, "nameserver 1.1.1.1", 10, "nameserver 8.8.8.8", 10, 0

    ip_path db "/bin/ip", 0
    ip_alt_path db "/usr/bin/ip", 0

    ip_cmd1_a0 db "ip", 0
    ip_cmd1_a1 db "link", 0
    ip_cmd1_a2 db "set", 0
    ip_cmd1_a3 db "eth0", 0
    ip_cmd1_a4 db "up", 0

    ip_cmd2_a0 db "ip", 0
    ip_cmd2_a1 db "addr", 0
    ip_cmd2_a2 db "add", 0
    ip_cmd2_a3 db "10.0.2.15/24", 0
    ip_cmd2_a4 db "dev", 0
    ip_cmd2_a5 db "eth0", 0

    ip_cmd3_a0 db "ip", 0
    ip_cmd3_a1 db "route", 0
    ip_cmd3_a2 db "add", 0
    ip_cmd3_a3 db "default", 0
    ip_cmd3_a4 db "via", 0
    ip_cmd3_a5 db "10.0.2.2", 0
    ip_cmd3_a6 db "dev", 0
    ip_cmd3_a7 db "eth0", 0

    dive_path db "/bin/dive", 0
    dive_cmd_a0 db "dive", 0
    dive_cmd_a1 db "-search", 0

    newline db 10, 0

section .data
    argv_cmd1 dq ip_cmd1_a0, ip_cmd1_a1, ip_cmd1_a2, ip_cmd1_a3, ip_cmd1_a4, 0
    argv_cmd2 dq ip_cmd2_a0, ip_cmd2_a1, ip_cmd2_a2, ip_cmd2_a3, ip_cmd2_a4, ip_cmd2_a5, 0
    argv_cmd3 dq ip_cmd3_a0, ip_cmd3_a1, ip_cmd3_a2, ip_cmd3_a3, ip_cmd3_a4, ip_cmd3_a5, ip_cmd3_a6, ip_cmd3_a7, 0
    argv_dive dq dive_cmd_a0, dive_cmd_a1, 0
    envp_empty dq 0

section .bss
    input_buf resb 64

section .text
global _start

_start:
menu_loop:
    lea rdi, [clear_screen]
    call print_str

    lea rdi, [color_bold]
    call print_str
    lea rdi, [color_red]
    call print_str

    lea rdi, [header_msg]
    call print_str
    lea rdi, [banner_l1]
    call print_str
    lea rdi, [banner_l2]
    call print_str
    lea rdi, [banner_l3]
    call print_str
    lea rdi, [banner_l4]
    call print_str

    lea rdi, [color_reset]
    call print_str

    lea rdi, [color_bold]
    call print_str
    lea rdi, [menu_iface_title]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [color_red]
    call print_str
    lea rdi, [menu_iface_eth0]
    call print_str
    lea rdi, [menu_iface_lo]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [color_bold]
    call print_str
    lea rdi, [menu_actions_title]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [color_red]
    call print_str
    lea rdi, [menu_act_1]
    call print_str
    lea rdi, [menu_act_2]
    call print_str
    lea rdi, [menu_act_3]
    call print_str
    lea rdi, [menu_act_4]
    call print_str
    lea rdi, [menu_act_5]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [color_bold]
    call print_str
    lea rdi, [menu_prompt]
    call print_str
    lea rdi, [color_reset]
    call print_str

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buf]
    mov rdx, 64
    syscall

    cmp rax, 0
    jle exit_prog

    mov al, byte [input_buf]
    cmp al, '1'
    je action_connect
    cmp al, '2'
    je action_dns
    cmp al, '3'
    je action_test
    cmp al, '4'
    je action_dive
    cmp al, '5'
    je exit_prog
    cmp al, 'q'
    je exit_prog

    jmp menu_loop

action_connect:
    lea rdi, [color_bold]
    call print_str
    lea rdi, [color_red]
    call print_str
    lea rdi, [net_up_msg1]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [ip_path]
    lea rsi, [argv_cmd1]
    call run_process

    lea rdi, [color_red]
    call print_str
    lea rdi, [net_up_msg2]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [ip_path]
    lea rsi, [argv_cmd2]
    call run_process

    lea rdi, [color_red]
    call print_str
    lea rdi, [net_up_msg3]
    call print_str
    lea rdi, [color_reset]
    call print_str

    lea rdi, [ip_path]
    lea rsi, [argv_cmd3]
    call run_process

    call write_resolv

    lea rdi, [color_bold]
    call print_str
    lea rdi, [color_red]
    call print_str
    lea rdi, [net_ok_msg]
    call print_str
    lea rdi, [color_reset]
    call print_str

    call wait_user_return
    jmp menu_loop

action_dns:
    call write_resolv
    lea rdi, [color_red]
    call print_str
    lea rdi, [net_up_msg4]
    call print_str
    lea rdi, [color_reset]
    call print_str
    call wait_user_return
    jmp menu_loop

action_test:
    lea rdi, [color_bold]
    call print_str
    lea rdi, [color_red]
    call print_str
    lea rdi, [net_ok_msg]
    call print_str
    lea rdi, [color_reset]
    call print_str
    call wait_user_return
    jmp menu_loop

action_dive:
    lea rdi, [dive_path]
    lea rsi, [argv_dive]
    call run_process
    call wait_user_return
    jmp menu_loop

write_resolv:
    mov rax, 2
    lea rdi, [resolv_path]
    mov rsi, 577
    mov rdx, 420
    syscall
    cmp rax, 0
    jl .done_resolv
    mov r12, rax

    lea rdi, [resolv_content]
    call str_len
    mov rdx, rax
    mov rax, 1
    mov rdi, r12
    lea rsi, [resolv_content]
    syscall

    mov rax, 3
    mov rdi, r12
    syscall
.done_resolv:
    ret

wait_user_return:
    lea rdi, [color_dim]
    call print_str
    lea rdi, [net_press_key]
    call print_str
    lea rdi, [color_reset]
    call print_str

    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buf]
    mov rdx, 64
    syscall
    ret

run_process:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    mov rax, 57
    syscall

    cmp rax, 0
    jl .fork_fail
    je .child

    mov rdi, rax
    mov rax, 61
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    jmp .done_proc

.child:
    mov rax, 59
    mov rdi, r12
    mov rsi, r13
    lea rdx, [envp_empty]
    syscall

    mov rax, 59
    lea rdi, [ip_alt_path]
    mov rsi, r13
    lea rdx, [envp_empty]
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

.fork_fail:
.done_proc:
    pop r13
    pop r12
    pop rbp
    ret

exit_prog:
    lea rdi, [newline]
    call print_str
    mov rax, 60
    xor rdi, rdi
    syscall

print_str:
    push rdi
    call str_len
    mov rdx, rax
    pop rsi
    mov rax, 1
    mov rdi, 1
    syscall
    ret

str_len:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

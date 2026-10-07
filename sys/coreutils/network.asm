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

    menu_iface_title db "  Detected Hardware Interfaces in /sys/class/net:", 10, 0
    bullet_iface     db "  [*] ", 0
    iface_tag_up     db " (Carrier: UP)", 10, 0
    iface_tag_down   db " (Carrier: DOWN)", 10, 0

    menu_actions_title db 10, "  Available Operations:", 10, 0
    menu_act_1 db "  [1] Bring Up All Detected Network Interfaces", 10, 0
    menu_act_2 db "  [2] Configure DNS Nameservers (1.1.1.1, 8.8.8.8, 10.0.2.3)", 10, 0
    menu_act_3 db "  [3] Test Real Internet TCP Connectivity (1.1.1.1)", 10, 0
    menu_act_4 db "  [4] Launch Dive Package Engine (-search available apps)", 10, 0
    menu_act_5 db "  [5] Exit Network Console", 10, 10, 0

    menu_prompt db "  Select operation [1-5]: ", 0

    net_scan_err db "  [ERROR] Cannot open /sys/class/net directory", 10, 0
    net_up_msg1 db 10, "[HINUX NET] Bringing up network interfaces...", 10, 0
    net_up_msg4 db "[HINUX NET] Updated /etc/resolv.conf with global DNS servers.", 10, 0
    net_ok_msg  db 10, "[HINUX NET] Real Internet connection ESTABLISHED and verified!", 10, 0
    net_fail_msg db 10, "[HINUX NET] Connection test FAILED. System is currently OFFLINE.", 10, 0
    net_press_key db 10, "Press ENTER to return to menu...", 0

    path_sys_net db "/sys/class/net", 0
    resolv_path db "/etc/resolv.conf", 0
    resolv_content db "nameserver 1.1.1.1", 10, "nameserver 8.8.8.8", 10, "nameserver 10.0.2.3", 10, 0

    ip_path db "/bin/ip", 0
    ip_alt_path db "/usr/bin/ip", 0

    ip_cmd_up_a0 db "ip", 0
    ip_cmd_up_a1 db "link", 0
    ip_cmd_up_a2 db "set", 0
    ip_cmd_up_a4 db "up", 0

    ip_cmd_lo_a3 db "lo", 0

    dive_path db "/bin/dive", 0
    dive_alt_path db "/usr/bin/dive", 0
    dive_cmd_a0 db "dive", 0
    dive_cmd_a1 db "search", 0
    dive_cmd_a2 db "all", 0

    newline db 10, 0

section .data
    argv_cmd_lo dq ip_cmd_up_a0, ip_cmd_up_a1, ip_cmd_up_a2, ip_cmd_lo_a3, ip_cmd_up_a4, 0
    argv_cmd_dyn dq ip_cmd_up_a0, ip_cmd_up_a1, ip_cmd_up_a2, dyn_iface_buf, ip_cmd_up_a4, 0
    argv_dive dq dive_cmd_a0, dive_cmd_a1, dive_cmd_a2, 0
    envp_empty dq 0

    target_sock:
        dw 2
        dw 0x3500
        dd 0x01010101
        dq 0

section .bss
    input_buf resb 64
    dents_buf resb 1024
    dyn_iface_buf resb 64
    subpath resb 256
    io_buf resb 16

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

    call scan_and_print_interfaces

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

scan_and_print_interfaces:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov rax, 2
    lea rdi, [path_sys_net]
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .scan_fail
    mov r12, rax

.read_loop:
    mov rax, 217
    mov rdi, r12
    lea rsi, [dents_buf]
    mov rdx, 1024
    syscall
    test rax, rax
    jle .done_dents

    xor r13d, r13d
.iter_dents:
    cmp r13d, eax
    jge .read_loop

    lea rbx, [dents_buf + r13]
    movzx edx, word [rbx + 16]
    lea rdi, [rbx + 19]

    cmp byte [rdi], '.'
    je .next_ent

    push rdx
    push rdi
    lea rdi, [color_dim]
    call print_str
    lea rdi, [bullet_iface]
    call print_str
    lea rdi, [color_bold]
    call print_str
    lea rdi, [color_red]
    call print_str
    pop rdi
    push rdi
    call print_str
    lea rdi, [color_reset]
    call print_str

    pop rdi
    push rdi
    call check_carrier_stat
    test eax, eax
    jz .pr_down
    lea rdi, [color_dim]
    call print_str
    lea rdi, [iface_tag_up]
    call print_str
    lea rdi, [color_reset]
    call print_str
    jmp .ent_fin

.pr_down:
    lea rdi, [color_dim]
    call print_str
    lea rdi, [iface_tag_down]
    call print_str
    lea rdi, [color_reset]
    call print_str

.ent_fin:
    pop rdi
    pop rdx

.next_ent:
    add r13d, edx
    jmp .iter_dents

.done_dents:
    mov rax, 3
    mov rdi, r12
    syscall
    pop r13
    pop r12
    pop rbp
    ret

.scan_fail:
    lea rdi, [net_scan_err]
    call print_str
    pop r13
    pop r12
    pop rbp
    ret

check_carrier_stat:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi

    lea rsi, [path_sys_net]
    lea rdi, [subpath]
    call str_copy_p
    mov byte [rdi], '/'
    inc rdi
    pop rsi
    push rsi
    call str_copy_p
    mov dword [rdi], 0x72726163
    mov dword [rdi + 4], 0x00726569

    mov rax, 2
    lea rdi, [subpath]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .stat_no
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    lea rsi, [io_buf]
    mov rdx, 8
    syscall
    mov rdx, rax
    mov rax, 3
    mov rdi, rbx
    syscall

    cmp rdx, 0
    jle .stat_no
    cmp byte [io_buf], '1'
    je .stat_yes

.stat_no:
    xor eax, eax
    pop rsi
    pop rbx
    pop rbp
    ret

.stat_yes:
    mov eax, 1
    pop rsi
    pop rbx
    pop rbp
    ret

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
    lea rsi, [argv_cmd_lo]
    call run_process

    call bring_up_all_interfaces
    call write_resolv

    call wait_user_return
    jmp menu_loop

bring_up_all_interfaces:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov rax, 2
    lea rdi, [path_sys_net]
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .b_done
    mov r12, rax

.b_read:
    mov rax, 217
    mov rdi, r12
    lea rsi, [dents_buf]
    mov rdx, 1024
    syscall
    test rax, rax
    jle .b_fin

    xor r13d, r13d
.b_iter:
    cmp r13d, eax
    jge .b_read

    lea rbx, [dents_buf + r13]
    movzx edx, word [rbx + 16]
    lea rdi, [rbx + 19]

    cmp byte [rdi], '.'
    je .b_next
    cmp word [rdi], 0x6F6C
    jne .b_act_up
    cmp byte [rdi + 2], 0
    je .b_next

.b_act_up:
    push rdx
    push rdi
    lea rsi, [rbx + 19]
    lea rdi, [dyn_iface_buf]
    call str_copy_p
    mov byte [rdi], 0

    lea rdi, [ip_path]
    lea rsi, [argv_cmd_dyn]
    call run_process
    pop rdi
    pop rdx

.b_next:
    add r13d, edx
    jmp .b_iter

.b_fin:
    mov rax, 3
    mov rdi, r12
    syscall
.b_done:
    pop r13
    pop r12
    pop rbp
    ret

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
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .test_failed
    mov r12, rax

    mov rax, 42
    mov rdi, r12
    lea rsi, [target_sock]
    mov rdx, 16
    syscall
    push rax
    mov rax, 3
    mov rdi, r12
    syscall
    pop rax

    cmp rax, 0
    jne .test_failed

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

.test_failed:
    lea rdi, [color_bold]
    call print_str
    lea rdi, [color_dark]
    call print_str
    lea rdi, [net_fail_msg]
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

    mov rax, 59
    lea rdi, [dive_alt_path]
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

str_copy_p:
.loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .loop
    dec rdi
    ret

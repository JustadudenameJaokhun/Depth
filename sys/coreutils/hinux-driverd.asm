global _start

section .data
dir_run_hinux:
    db "/run/hinux", 0
file_net_stat:
    db "/run/hinux/net.stat", 0
file_pwr_stat:
    db "/run/hinux/power.stat", 0

path_eth0_state:
    db "/sys/class/net/eth0/operstate", 0
path_eth0_carrier:
    db "/sys/class/net/eth0/carrier", 0
path_enp_state:
    db "/sys/class/net/enp0s3/operstate", 0

path_bat_cap:
    db "/sys/class/power_supply/BAT0/capacity", 0
path_bat_stat:
    db "/sys/class/power_supply/BAT0/status", 0
path_ac_online:
    db "/sys/class/power_supply/AC/online", 0

str_net_online:
    db "INTERFACE=eth0", 10
    db "STATUS=connected", 10
    db "TYPE=ethernet", 10
    db "SPEED=1000Mb/s", 10
    db "IP=10.0.2.15", 10
    db "CARRIER=1", 10, 0

str_net_offline:
    db "INTERFACE=eth0", 10
    db "STATUS=disconnected", 10
    db "TYPE=ethernet", 10
    db "SPEED=0", 10
    db "IP=127.0.0.1", 10
    db "CARRIER=0", 10, 0

str_pwr_full:
    db "PERCENT=100", 10
    db "STATUS=Full", 10
    db "AC=Online", 10
    db "HEALTH=Good", 10
    db "SOURCE=AC Power", 10, 0

str_pwr_bat:
    db "PERCENT=", 0
str_pwr_bat_mid:
    db 10, "STATUS=", 0
str_pwr_bat_end:
    db 10, "AC=Offline", 10
    db "HEALTH=Good", 10
    db "SOURCE=Battery", 10, 0

timespec:
    dq 2
    dq 0

section .bss
io_buf: resb 256
cap_buf: resb 32
stat_buf: resb 64
work_buf: resb 512

section .text

_start:
    mov rax, 57
    syscall
    test rax, rax
    jnz .parent_exit
    js .direct_run

    mov rax, 112
    syscall

.direct_run:
    mov rax, 83
    mov rdi, dir_run_hinux
    mov rsi, 0755o
    syscall

.main_loop:
    call update_network
    call update_power

    mov rax, 35
    mov rdi, timespec
    xor rsi, rsi
    syscall

    jmp .main_loop

.parent_exit:
    xor edi, edi
    mov eax, 60
    syscall

update_network:
    push rbp
    mov rbp, rsp

    mov rax, 2
    mov rdi, path_eth0_carrier
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .check_enp

    mov rdi, rax
    mov rax, 0
    mov rsi, io_buf
    mov rdx, 16
    syscall
    mov rax, 3
    syscall

    mov al, byte [io_buf]
    cmp al, '1'
    je .net_write_up
    jmp .net_write_down

.check_enp:
    mov rax, 2
    mov rdi, path_enp_state
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .net_write_up

    mov rdi, rax
    mov rax, 0
    mov rsi, io_buf
    mov rdx, 16
    syscall
    mov rax, 3
    syscall

    mov al, byte [io_buf]
    cmp al, 'u'
    je .net_write_up

.net_write_down:
    mov rdi, file_net_stat
    mov rsi, str_net_offline
    call write_file_content
    pop rbp
    ret

.net_write_up:
    mov rdi, file_net_stat
    mov rsi, str_net_online
    call write_file_content
    pop rbp
    ret

update_power:
    push rbp
    mov rbp, rsp

    mov rax, 2
    mov rdi, path_bat_cap
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .pwr_default_ac

    mov rbx, rax
    mov rax, 0
    mov rdi, rbx
    mov rsi, cap_buf
    mov rdx, 31
    syscall
    test rax, rax
    jle .close_bat_fail
    mov byte [cap_buf + rax], 0

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 2
    mov rdi, path_bat_stat
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .pwr_default_ac

    mov rbx, rax
    mov rax, 0
    mov rdi, rbx
    mov rsi, stat_buf
    mov rdx, 63
    syscall
    test rax, rax
    jle .close_stat_fail
    mov byte [stat_buf + rax], 0

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rdi, work_buf
    mov rsi, str_pwr_bat
    call strcpy_dst
    mov rsi, cap_buf
    call strcat_strip
    mov rsi, str_pwr_bat_mid
    call strcat_dst
    mov rsi, stat_buf
    call strcat_strip
    mov rsi, str_pwr_bat_end
    call strcat_dst

    mov rdi, file_pwr_stat
    mov rsi, work_buf
    call write_file_content
    pop rbp
    ret

.close_bat_fail:
    mov rax, 3
    mov rdi, rbx
    syscall
    jmp .pwr_default_ac

.close_stat_fail:
    mov rax, 3
    mov rdi, rbx
    syscall
    jmp .pwr_default_ac

.pwr_default_ac:
    mov rdi, file_pwr_stat
    mov rsi, str_pwr_full
    call write_file_content
    pop rbp
    ret

write_file_content:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    mov rax, 2
    mov rdi, r12
    mov rsi, 577
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .wfc_done
    mov rbx, rax

    mov rdi, r13
    call strlen
    mov rdx, rax

    mov rax, 1
    mov rdi, rbx
    mov rsi, r13
    syscall

    mov rax, 3
    syscall

.wfc_done:
    pop r13
    pop r12
    pop rbp
    ret

strlen:
    xor rax, rax
.sl_loop:
    cmp byte [rdi + rax], 0
    je .sl_done
    inc rax
    jmp .sl_loop
.sl_done:
    ret

strcpy_dst:
.scd_loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rdi
    inc rsi
    test al, al
    jnz .scd_loop
    dec rdi
    ret

strcat_dst:
.sad_loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rdi
    inc rsi
    test al, al
    jnz .sad_loop
    dec rdi
    ret

strcat_strip:
.sas_loop:
    mov al, byte [rsi]
    cmp al, 10
    je .sas_next
    cmp al, 13
    je .sas_next
    test al, al
    jz .sas_done
    mov byte [rdi], al
    inc rdi
.sas_next:
    inc rsi
    jmp .sas_loop
.sas_done:
    mov byte [rdi], 0
    ret

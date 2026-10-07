default rel
global _start

section .data
dir_run_hinux:
    db "/run/hinux", 0
file_net_stat:
    db "/run/hinux/net.stat", 0
file_pwr_stat:
    db "/run/hinux/power.stat", 0

path_sys_net:
    db "/sys/class/net", 0
path_sys_pwr:
    db "/sys/class/power_supply", 0

slash_carrier:
    db "/carrier", 0
slash_operstate:
    db "/operstate", 0
slash_capacity:
    db "/capacity", 0
slash_status:
    db "/status", 0
slash_online:
    db "/online", 0

str_k_iface:
    db "INTERFACE=", 0
str_k_stat:
    db 10, "STATUS=", 0
str_k_type:
    db 10, "TYPE=", 0
str_k_speed:
    db 10, "SPEED=", 0
str_k_ip:
    db 10, "IP=", 0
str_k_carr:
    db 10, "CARRIER=", 0
nl_byte:
    db 10, 0

str_val_conn:
    db "connected", 0
str_val_disc:
    db "disconnected", 0
str_val_wire:
    db "wireless", 0
str_val_eth:
    db "ethernet", 0
str_val_auto:
    db "auto", 0
str_val_zero:
    db "0", 0
str_val_one:
    db "1", 0
str_val_none:
    db "none", 0

str_p_pct:
    db "PERCENT=", 0
str_p_stat:
    db 10, "STATUS=", 0
str_p_ac:
    db 10, "AC=", 0
str_p_hlth:
    db 10, "HEALTH=Good", 10, "SOURCE=", 0
str_val_bat:
    db "Battery", 10, 0
str_val_acpwr:
    db "AC Power", 10, 0
str_val_on:
    db "Online", 0
str_val_off:
    db "Offline", 0
str_val_full:
    db "Full", 0
str_val_hundred:
    db "100", 0

timespec:
    dq 2
    dq 0

section .bss
dents_buf:  resb 1024
io_buf:     resb 256
work_buf:   resb 1024
subpath:    resb 256
act_iface:  resb 32
act_ip:     resb 32
act_type:   resb 32
cap_buf:    resb 32
stat_buf:   resb 32
ifreq_buf:  resb 40
bat_name:   resb 32
ac_name:    resb 32

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
    push r12
    push r13
    push r14
    push r15

    mov byte [act_iface], 0
    mov byte [act_ip], 0
    mov byte [act_type], 0
    xor r14d, r14d
    xor r15d, r15d

    mov rax, 2
    mov rdi, path_sys_net
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .net_write_fallback
    mov r12, rax

.net_read_dents:
    mov rax, 217
    mov rdi, r12
    mov rsi, dents_buf
    mov rdx, 1024
    syscall
    test rax, rax
    jle .net_dents_done

    xor r13d, r13d
.net_iter:
    cmp r13d, eax
    jge .net_read_dents

    lea rbx, [dents_buf + r13]
    movzx edx, word [rbx + 16]
    lea rdi, [rbx + 19]

    cmp byte [rdi], '.'
    je .net_next
    cmp word [rdi], 0x6F6C
    jne .net_process_iface
    cmp byte [rdi + 2], 0
    je .net_next

.net_process_iface:
    push rdx
    push rdi

    cmp byte [act_iface], 0
    jnz .has_fallback_iface
    mov rsi, rdi
    mov rdi, act_iface
    call strcpy_raw
    call detect_iface_type

.has_fallback_iface:
    pop rdi
    push rdi
    call check_iface_carrier
    mov ebx, eax

    pop rdi
    push rbx
    push rdi
    call check_iface_ip
    pop rdi
    pop rbx

    test ebx, ebx
    jz .skip_active_select

    mov rsi, rdi
    mov rdi, act_iface
    call strcpy_raw

    call detect_iface_type

    mov r14d, 1
    cmp byte [act_ip], 0
    jz .skip_active_select
    mov r15d, 1
    pop rdx
    jmp .net_dents_done

.skip_active_select:
    pop rdx
.net_next:
    add r13d, edx
    jmp .net_iter

.net_dents_done:
    mov rax, 3
    mov rdi, r12
    syscall

    cmp byte [act_iface], 0
    jnz .net_format
    mov rsi, str_val_none
    mov rdi, act_iface
    call strcpy_raw
    mov rsi, str_val_none
    mov rdi, act_type
    call strcpy_raw

.net_format:
    mov rdi, work_buf
    mov rsi, str_k_iface
    call strcpy_dst
    mov rsi, act_iface
    call strcat_dst
    mov rsi, str_k_stat
    call strcat_dst
    test r14d, r14d
    jnz .lbl_conn
    mov rsi, str_val_disc
    jmp .lbl_stat_done
.lbl_conn:
    mov rsi, str_val_conn
.lbl_stat_done:
    call strcat_dst
    mov rsi, str_k_type
    call strcat_dst
    mov rsi, act_type
    call strcat_dst
    mov rsi, str_k_speed
    call strcat_dst
    test r14d, r14d
    jnz .lbl_spd_auto
    mov rsi, str_val_zero
    jmp .lbl_spd_done
.lbl_spd_auto:
    mov rsi, str_val_auto
.lbl_spd_done:
    call strcat_dst
    mov rsi, str_k_ip
    call strcat_dst
    cmp byte [act_ip], 0
    jnz .lbl_has_ip
    mov rsi, str_val_none
    jmp .lbl_ip_done
.lbl_has_ip:
    mov rsi, act_ip
.lbl_ip_done:
    call strcat_dst
    mov rsi, str_k_carr
    call strcat_dst
    test r14d, r14d
    jnz .lbl_carr_one
    mov rsi, str_val_zero
    jmp .lbl_carr_done
.lbl_carr_one:
    mov rsi, str_val_one
.lbl_carr_done:
    call strcat_dst
    mov rsi, nl_byte
    call strcat_dst

    mov rdi, file_net_stat
    mov rsi, work_buf
    call write_file_content

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

.net_write_fallback:
    mov rdi, work_buf
    mov rsi, str_k_iface
    call strcpy_dst
    mov rsi, str_val_none
    call strcat_dst
    mov rsi, str_k_stat
    call strcat_dst
    mov rsi, str_val_disc
    call strcat_dst
    mov rsi, str_k_type
    call strcat_dst
    mov rsi, str_val_none
    call strcat_dst
    mov rsi, str_k_speed
    call strcat_dst
    mov rsi, str_val_zero
    call strcat_dst
    mov rsi, str_k_ip
    call strcat_dst
    mov rsi, str_val_none
    call strcat_dst
    mov rsi, str_k_carr
    call strcat_dst
    mov rsi, str_val_zero
    call strcat_dst
    mov rsi, nl_byte
    call strcat_dst

    mov rdi, file_net_stat
    mov rsi, work_buf
    call write_file_content

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

check_iface_carrier:
    push rbp
    mov rbp, rsp
    push rbx

    mov rsi, rdi
    mov rdi, subpath
    call build_net_subpath
    mov rsi, slash_carrier
    call strcat_dst

    mov rax, 2
    mov rdi, subpath
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .check_operstate
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, io_buf
    mov rdx, 8
    syscall
    mov rdx, rax
    mov rax, 3
    mov rdi, rbx
    syscall

    cmp rdx, 0
    jle .check_operstate
    cmp byte [io_buf], '1'
    je .carr_is_up

.check_operstate:
    mov rsi, rdi
    mov rdi, subpath
    call build_net_subpath
    mov rsi, slash_operstate
    call strcat_dst

    mov rax, 2
    mov rdi, subpath
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .carr_is_down
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, io_buf
    mov rdx, 8
    syscall
    mov rdx, rax
    mov rax, 3
    mov rdi, rbx
    syscall

    cmp rdx, 0
    jle .carr_is_down
    cmp byte [io_buf], 'u'
    je .carr_is_up

.carr_is_down:
    xor eax, eax
    pop rbx
    pop rbp
    ret

.carr_is_up:
    mov eax, 1
    pop rbx
    pop rbp
    ret

check_iface_ip:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov byte [act_ip], 0

    mov rax, 41
    mov rdi, 2
    mov rsi, 2
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .ip_done
    mov r13, rax

    mov rdi, ifreq_buf
    xor eax, eax
    mov ecx, 10
    rep stosd

    mov rsi, r12
    mov rdi, ifreq_buf
    call strcpy_raw

    mov rax, 16
    mov rdi, r13
    mov rsi, 0x8915
    mov rdx, ifreq_buf
    syscall

    push rax
    mov rax, 3
    mov rdi, r13
    syscall
    pop rax

    cmp rax, 0
    jne .ip_done

    lea rsi, [ifreq_buf + 20]
    mov rdi, act_ip
    call format_ipv4

.ip_done:
    pop r13
    pop r12
    pop rbp
    ret

format_ipv4:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12, rsi
    mov rbx, rdi

    movzx eax, byte [r12]
    call append_dec_byte
    mov byte [rbx], '.'
    inc rbx

    movzx eax, byte [r12 + 1]
    call append_dec_byte
    mov byte [rbx], '.'
    inc rbx

    movzx eax, byte [r12 + 2]
    call append_dec_byte
    mov byte [rbx], '.'
    inc rbx

    movzx eax, byte [r12 + 3]
    call append_dec_byte
    mov byte [rbx], 0

    pop r12
    pop rbx
    pop rbp
    ret

append_dec_byte:
    push rcx
    push rdx
    xor edx, edx
    mov ecx, 100
    div ecx
    test eax, eax
    jz .chk_tens
    add al, '0'
    mov byte [rbx], al
    inc rbx
    jmp .do_tens_force

.chk_tens:
    mov eax, edx
    xor edx, edx
    mov ecx, 10
    div ecx
    test eax, eax
    jz .do_units
    add al, '0'
    mov byte [rbx], al
    inc rbx
    jmp .do_units_val

.do_tens_force:
    mov eax, edx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    mov byte [rbx], al
    inc rbx

.do_units_val:
    add dl, '0'
    mov byte [rbx], dl
    inc rbx
    pop rdx
    pop rcx
    ret

.do_units:
    add dl, '0'
    mov byte [rbx], dl
    inc rbx
    pop rdx
    pop rcx
    ret

detect_iface_type:
    cmp word [act_iface], 0x6C77
    jne .chk_eth
    mov rsi, str_val_wire
    mov rdi, act_type
    call strcpy_raw
    ret

.chk_eth:
    mov rsi, str_val_eth
    mov rdi, act_type
    call strcpy_raw
    ret

build_net_subpath:
    push rsi
    mov rdi, subpath
    mov rsi, path_sys_net
    call strcpy_dst
    mov byte [rdi], '/'
    inc rdi
    pop rsi
    call strcpy_dst
    ret

update_power:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov byte [bat_name], 0
    mov byte [ac_name], 0

    mov rax, 2
    mov rdi, path_sys_pwr
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .pwr_default_ac
    mov r12, rax

.pwr_read_dents:
    mov rax, 217
    mov rdi, r12
    mov rsi, dents_buf
    mov rdx, 1024
    syscall
    test rax, rax
    jle .pwr_dents_done

    xor r13d, r13d
.pwr_iter:
    cmp r13d, eax
    jge .pwr_read_dents

    lea rbx, [dents_buf + r13]
    movzx edx, word [rbx + 16]
    lea rdi, [rbx + 19]

    cmp byte [rdi], 'B'
    jne .pwr_chk_ac
    cmp byte [rdi + 1], 'A'
    jne .pwr_chk_ac
    cmp byte [rdi + 2], 'T'
    jne .pwr_chk_ac

    push rsi
    push rdi
    mov rsi, rdi
    mov rdi, bat_name
    call strcpy_raw
    pop rdi
    pop rsi
    jmp .pwr_next

.pwr_chk_ac:
    cmp byte [rdi], 'A'
    jne .pwr_next
    cmp byte [rdi + 1], 'C'
    jne .pwr_next

    push rsi
    push rdi
    mov rsi, rdi
    mov rdi, ac_name
    call strcpy_raw
    pop rdi
    pop rsi

.pwr_next:
    add r13d, edx
    jmp .pwr_iter

.pwr_dents_done:
    mov rax, 3
    mov rdi, r12
    syscall

    cmp byte [bat_name], 0
    jnz .pwr_has_bat
    jmp .pwr_default_ac

.pwr_has_bat:
    call read_battery_info
    pop r13
    pop r12
    pop rbp
    ret

.pwr_default_ac:
    mov rdi, work_buf
    mov rsi, str_p_pct
    call strcpy_dst
    mov rsi, str_val_hundred
    call strcat_dst
    mov rsi, str_p_stat
    call strcat_dst
    mov rsi, str_val_full
    call strcat_dst
    mov rsi, str_p_ac
    call strcat_dst
    mov rsi, str_val_on
    call strcat_dst
    mov rsi, str_p_hlth
    call strcat_dst
    mov rsi, str_val_acpwr
    call strcat_dst

    mov rdi, file_pwr_stat
    mov rsi, work_buf
    call write_file_content

    pop r13
    pop r12
    pop rbp
    ret

read_battery_info:
    push rbp
    mov rbp, rsp
    push rbx

    mov rsi, bat_name
    mov rdi, subpath
    call build_pwr_subpath
    mov rsi, slash_capacity
    call strcat_dst

    mov rax, 2
    mov rdi, subpath
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .bat_read_fail
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, cap_buf
    mov rdx, 31
    syscall
    test rax, rax
    jle .close_cap_fail
    mov byte [cap_buf + rax], 0
    mov rax, 3
    mov rdi, rbx
    syscall

    mov rsi, subpath
    call truncate_subpath
    mov rsi, slash_status
    call strcat_dst

    mov rax, 2
    mov rdi, subpath
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .bat_read_fail
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, stat_buf
    mov rdx, 31
    syscall
    test rax, rax
    jle .close_stat_fail
    mov byte [stat_buf + rax], 0
    mov rax, 3
    mov rdi, rbx
    syscall

    mov rdi, work_buf
    mov rsi, str_p_pct
    call strcpy_dst
    mov rsi, cap_buf
    call strcat_strip
    mov rsi, str_p_stat
    call strcat_dst
    mov rsi, stat_buf
    call strcat_strip
    mov rsi, str_p_ac
    call strcat_dst

    cmp byte [ac_name], 0
    jz .chk_stat_charging

    mov rsi, ac_name
    mov rdi, subpath
    call build_pwr_subpath
    mov rsi, slash_online
    call strcat_dst

    mov rax, 2
    mov rdi, subpath
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .chk_stat_charging
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, io_buf
    mov rdx, 4
    syscall
    mov rax, 3
    mov rdi, rbx
    syscall

    cmp byte [io_buf], '1'
    je .ac_is_on
    jmp .ac_is_off

.chk_stat_charging:
    cmp byte [stat_buf], 'C'
    je .ac_is_on
    cmp byte [stat_buf], 'F'
    je .ac_is_on

.ac_is_off:
    mov rsi, str_val_off
    jmp .ac_done
.ac_is_on:
    mov rsi, str_val_on
.ac_done:
    call strcat_dst
    mov rsi, str_p_hlth
    call strcat_dst
    mov rsi, str_val_bat
    call strcat_dst

    mov rdi, file_pwr_stat
    mov rsi, work_buf
    call write_file_content

    pop rbx
    pop rbp
    ret

.close_cap_fail:
    mov rax, 3
    mov rdi, rbx
    syscall
.bat_read_fail:
    pop rbx
    pop rbp
    ret

.close_stat_fail:
    mov rax, 3
    mov rdi, rbx
    syscall
    pop rbx
    pop rbp
    ret

build_pwr_subpath:
    push rsi
    mov rdi, subpath
    mov rsi, path_sys_pwr
    call strcpy_dst
    mov byte [rdi], '/'
    inc rdi
    pop rsi
    call strcpy_dst
    ret

truncate_subpath:
    mov rdi, subpath
.tr_loop:
    cmp byte [rdi], 0
    je .tr_find_slash
    inc rdi
    jmp .tr_loop
.tr_find_slash:
    cmp rdi, subpath
    jbe .tr_done
    dec rdi
    cmp byte [rdi], '/'
    jne .tr_find_slash
    mov byte [rdi], 0
.tr_done:
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

    mov rdi, rbx
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

strcpy_raw:
.scr_loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rdi
    inc rsi
    test al, al
    jnz .scr_loop
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

default rel

global net_calc_ip_checksum
global net_calc_tcp_checksum
global net_parse_ethernet_hdr
global net_parse_ipv4_hdr

section .text

net_calc_ip_checksum:
    push rbp
    mov rbp, rsp
    push rbx

    xor eax, eax
    mov rcx, rsi
    shr rcx, 1

.sum_loop:
    test rcx, rcx
    jz .odd_check
    movzx edx, word [rdi]
    add eax, edx
    add rdi, 2
    dec rcx
    jmp .sum_loop

.odd_check:
    test rsi, 1
    jz .fold
    movzx edx, byte [rdi]
    add eax, edx

.fold:
    mov edx, eax
    shr edx, 16
    and eax, 0xFFFF
    add eax, edx
    mov edx, eax
    shr edx, 16
    add eax, edx
    not ax
    and eax, 0xFFFF

    pop rbx
    leave
    ret

net_calc_tcp_checksum:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

    xor eax, eax
    movzx edx, word [rdx]
    add eax, edx
    movzx edx, word [rdx+2]
    add eax, edx
    movzx edx, word [rcx]
    add eax, edx
    movzx edx, word [rcx+2]
    add eax, edx
    add eax, 6
    add eax, r8d

    mov rdi, r12
    mov rsi, r13
    call net_calc_ip_checksum

    pop r13
    pop r12
    pop rbx
    leave
    ret

net_parse_ethernet_hdr:
    cmp rsi, 14
    jl .eth_err
    movzx eax, word [rdi + 12]
    xchg al, ah
    ret
.eth_err:
    xor eax, eax
    ret

net_parse_ipv4_hdr:
    cmp rsi, 20
    jl .ip_err
    movzx eax, byte [rdi]
    shr eax, 4
    cmp eax, 4
    jne .ip_err
    movzx eax, byte [rdi]
    and eax, 0x0F
    shl eax, 2
    ret
.ip_err:
    xor eax, eax
    ret

default rel
%include "syscalls.inc"

global hinux_net_socket_tcp
global hinux_net_socket_udp
global hinux_net_bind
global hinux_net_listen
global hinux_net_accept
global hinux_net_connect
global hinux_net_send
global hinux_net_recv
global hinux_net_parse_ipv4

section .bss
sockaddr_in resb 16

section .text

hinux_net_socket_tcp:
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    mov rax, SYS_SOCKET
    syscall
    ret

hinux_net_socket_udp:
    mov rdi, 2
    mov rsi, 2
    xor rdx, rdx
    mov rax, SYS_SOCKET
    syscall
    ret

hinux_net_bind:
    mov rax, SYS_BIND
    syscall
    ret

hinux_net_listen:
    mov rax, SYS_LISTEN
    syscall
    ret

hinux_net_accept:
    mov rax, SYS_ACCEPT
    syscall
    ret

hinux_net_connect:
    mov rax, SYS_CONNECT
    syscall
    ret

hinux_net_send:
    xor r10, r10
    mov rax, SYS_SENDTO
    syscall
    ret

hinux_net_recv:
    xor r10, r10
    xor r8, r8
    xor r9, r9
    mov rax, SYS_RECVFROM
    syscall
    ret

hinux_net_parse_ipv4:
    push rbx
    push r12
    mov r12, rdi
    xor eax, eax
    xor rbx, rbx
    xor ecx, ecx

.parse_byte:
    mov dl, byte [r12]
    test dl, dl
    jz .byte_done
    cmp dl, '.'
    je .byte_sep
    cmp dl, '0'
    jb .parse_err
    cmp dl, '9'
    ja .parse_err
    sub dl, '0'
    imul eax, 10
    movzx edx, dl
    add eax, edx
    inc r12
    jmp .parse_byte

.byte_sep:
    shl ebx, 8
    or ebx, eax
    xor eax, eax
    inc ecx
    inc r12
    jmp .parse_byte

.byte_done:
    shl ebx, 8
    or ebx, eax
    inc ecx
    cmp ecx, 4
    jne .parse_err
    mov eax, ebx
    bswap eax
    pop r12
    pop rbx
    ret

.parse_err:
    xor eax, eax
    pop r12
    pop rbx
    ret

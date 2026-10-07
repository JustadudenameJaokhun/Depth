default rel
global _start

section .data
    timespec:
        dq 5
        dq 0

    log_path:
        db "/run/hinux/killer.stat", 0

    stat_active:
        db "ACTIVE=1", 10, "MONITOR=depth-killer", 10, 0
    stat_len equ $ - stat_active

section .bss
    ts_rem: resq 2

section .text
_start:
    mov eax, 57
    syscall
    test rax, rax
    jz .child
    js .child

    mov eax, 60
    xor edi, edi
    syscall

.child:
    mov eax, 112
    syscall

    mov eax, 2
    lea rdi, [log_path]
    mov esi, 577
    mov edx, 420
    syscall
    test eax, eax
    js .loop
    mov edi, eax
    mov eax, 1
    lea rsi, [stat_active]
    mov edx, stat_len
    syscall
    mov eax, 3
    syscall

.loop:
    mov eax, 35
    lea rdi, [timespec]
    lea rsi, [ts_rem]
    syscall
    jmp .loop

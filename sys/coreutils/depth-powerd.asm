default rel
global _start

section .data
    timespec:
        dq 4
        dq 0

    run_dir:
        db "/run/hinux", 0

    log_path:
        db "/run/hinux/powerd.stat", 0

    powerd_banner:
        db "DAEMON=depth-powerd", 10, "STATUS=active", 10, "DPMS=enabled", 10, 0
    powerd_len equ $ - powerd_banner

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

    mov eax, 83
    lea rdi, [run_dir]
    mov esi, 493
    syscall

.loop:
    mov eax, 2
    lea rdi, [log_path]
    mov esi, 577
    mov edx, 420
    syscall
    test eax, eax
    js .sleep
    mov edi, eax
    mov eax, 1
    lea rsi, [powerd_banner]
    mov edx, powerd_len
    syscall
    mov eax, 3
    syscall

.sleep:
    mov eax, 35
    lea rdi, [timespec]
    lea rsi, [ts_rem]
    syscall
    jmp .loop

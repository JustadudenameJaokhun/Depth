default rel
%include "syscalls.inc"

global hinux_atomic_cas
global hinux_atomic_add
global hinux_spinlock_lock
global hinux_spinlock_unlock
global hinux_ring_init
global hinux_ring_push
global hinux_ring_pop
global hinux_futex_wait
global hinux_futex_wake

SYS_FUTEX equ 202
FUTEX_WAIT equ 0
FUTEX_WAKE equ 1

section .text

hinux_atomic_cas:
    mov rax, rsi
    lock cmpxchg [rdi], rdx
    sete al
    movzx eax, al
    ret

hinux_atomic_add:
    mov rax, rsi
    lock xadd [rdi], rax
    ret

hinux_spinlock_lock:
.spin_loop:
    cmp dword [rdi], 0
    jne .pause_loop
    mov eax, 0
    mov edx, 1
    lock cmpxchg [rdi], edx
    jz .acquired

.pause_loop:
    pause
    jmp .spin_loop

.acquired:
    ret

hinux_spinlock_unlock:
    mov dword [rdi], 0
    ret

hinux_ring_init:
    mov qword [rdi], 0
    mov qword [rdi + 8], 0
    mov [rdi + 16], rsi
    ret

hinux_ring_push:
    mov rax, [rdi]
    mov rcx, [rdi + 8]
    mov r8, [rdi + 16]

    mov r9, rax
    sub r9, rcx
    cmp r9, r8
    jge .ring_full

    mov r10, rax
    and r10, r8
    dec r10
    mov [rdx + r10 * 8], rsi
    inc qword [rdi]
    mov eax, 1
    ret

.ring_full:
    xor eax, eax
    ret

hinux_ring_pop:
    mov rax, [rdi]
    mov rcx, [rdi + 8]
    cmp rcx, rax
    jge .ring_empty

    mov r8, [rdi + 16]
    mov r10, rcx
    and r10, r8
    dec r10
    mov r11, [rdx + r10 * 8]
    mov [rsi], r11
    inc qword [rdi + 8]
    mov eax, 1
    ret

.ring_empty:
    xor eax, eax
    ret

hinux_futex_wait:
    mov r10, rdx
    mov rdx, rsi
    mov rsi, FUTEX_WAIT
    mov rax, SYS_FUTEX
    syscall
    ret

hinux_futex_wake:
    mov rdx, rsi
    mov rsi, FUTEX_WAKE
    mov rax, SYS_FUTEX
    syscall
    ret

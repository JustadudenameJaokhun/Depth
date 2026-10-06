default rel
%include "syscalls.inc"

global hinux_context_switch
global hinux_sched_yield
global hinux_fiber_create
global hinux_fiber_resume

section .text

hinux_sched_yield:
    mov rax, SYS_SCHED_YIELD
    syscall
    ret

hinux_context_switch:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    pushfq

    mov [rdi], rsp
    mov rsp, [rsi]

    popfq
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

hinux_fiber_create:
    mov rax, rsi
    sub rax, 128
    and rax, -16

    mov [rax + 56], rdx
    lea r8, [fiber_entry_stub]
    mov [rax + 64], r8

    mov [rdi], rax
    mov eax, 1
    ret

fiber_entry_stub:
    pop rdi
    call rdi
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

hinux_fiber_resume:
    jmp hinux_context_switch

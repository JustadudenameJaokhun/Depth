default rel

section .bss
align 16
tasks_table:
    resb 16 * 128
current_task:
    resq 1
task_count:
    resq 1

section .text
bits 64
global sched_init
global task_create
global sched_yield

sched_init:
    push rax
    push rdi
    push rcx

    lea rdi, [tasks_table]
    mov rcx, (16 * 128) / 8
    xor rax, rax
    cld
    rep stosq

    mov qword [tasks_table + 0], 0
    mov rax, cr3
    mov qword [tasks_table + 8], rax
    mov qword [tasks_table + 16], 0
    mov qword [tasks_table + 24], 2

    mov qword [current_task], 0
    mov qword [task_count], 1

    pop rcx
    pop rdi
    pop rax
    ret

task_create:
    push rbx
    push rdx
    push rcx

    mov rax, [task_count]
    cmp rax, 16
    jge .failed

    imul rbx, rax, 128
    lea rdx, [tasks_table + rbx]

    mov [rdx + 16], rax
    mov qword [rdx + 24], 1
    mov [rdx + 32], rdi

    mov rax, cr3
    mov [rdx + 8], rax

    inc qword [task_count]
    mov rax, [rdx + 16]

    pop rcx
    pop rdx
    pop rbx
    ret

.failed:
    mov rax, -1
    pop rcx
    pop rdx
    pop rbx
    ret

sched_yield:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rax, [current_task]
    imul rbx, rax, 128
    lea rdx, [tasks_table + rbx]
    mov [rdx + 0], rsp

    inc rax
    cmp rax, [task_count]
    jl .has_next
    xor rax, rax
.has_next:
    mov [current_task], rax

    imul rbx, rax, 128
    lea rdx, [tasks_table + rbx]
    mov rsp, [rdx + 0]

    mov rax, [rdx + 8]
    mov rbx, cr3
    cmp rax, rbx
    je .same_cr3
    mov cr3, rax
.same_cr3:

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

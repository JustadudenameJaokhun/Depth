default rel

section .bss
align 16
kernel_stack_top:
    resb 8192
saved_user_rsp:
    resq 1

section .text
bits 64
global syscall_init
global syscall_entry
extern vga_putc
extern serial_putc

syscall_init:
    push rax
    push rdx
    push rcx

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1
    wrmsr

    mov ecx, 0xC0000081
    mov edx, 0x001B0008
    xor eax, eax
    wrmsr

    mov ecx, 0xC0000082
    lea rax, [syscall_entry]
    mov rdx, rax
    shr rdx, 32
    wrmsr

    mov ecx, 0xC0000084
    mov eax, 0x200
    xor edx, edx
    wrmsr

    pop rcx
    pop rdx
    pop rax
    ret

syscall_entry:
    mov [saved_user_rsp], rsp
    lea rsp, [kernel_stack_top + 8192]

    push rcx
    push r11
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    cmp rax, 0
    je .handle_read
    cmp rax, 1
    je .handle_write
    cmp rax, 39
    je .handle_getpid
    cmp rax, 60
    je .handle_exit
    cmp rax, 231
    je .handle_exit

    mov rax, -38
    jmp .syscall_done

.handle_read:
    xor rax, rax
    jmp .syscall_done

.handle_write:
    push rdi
    push rsi
    push rdx

    mov rcx, rdx
    mov rbx, rsi
.write_loop:
    test rcx, rcx
    jz .write_end
    mov al, [rbx]
    call vga_putc
    call serial_putc
    inc rbx
    dec rcx
    jmp .write_loop

.write_end:
    pop rdx
    pop rsi
    pop rdi
    mov rax, rdx
    jmp .syscall_done

.handle_getpid:
    mov rax, 1
    jmp .syscall_done

.handle_exit:
    mov rax, 0
    cli
    hlt

.syscall_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    pop r11
    pop rcx

    mov rsp, [saved_user_rsp]
    o64 sysret

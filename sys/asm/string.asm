default rel
%include "syscalls.inc"

global depth_strlen
global depth_strcmp
global depth_print
global depth_print_nl
global depth_newline

section .data
nl db 10

section .text

depth_strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

depth_strcmp:
    xor rcx, rcx
.loop:
    mov al, byte [rdi + rcx]
    mov dl, byte [rsi + rcx]
    cmp al, dl
    jne .diff
    test al, al
    je .equal
    inc rcx
    jmp .loop
.diff:
    movzx eax, al
    movzx edx, dl
    sub eax, edx
    ret
.equal:
    xor eax, eax
    ret

depth_print:
    push rdi
    call depth_strlen
    pop rsi
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

depth_print_nl:
    push rdi
    call depth_print
    call depth_newline
    pop rdi
    ret

depth_newline:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    ret

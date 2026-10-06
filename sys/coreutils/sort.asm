default rel
%include "syscalls.inc"

global _start

section .bss
sort_in resb 65536
line_ptrs resq 4096

section .text

_start:
    xor r12, r12
    lea r13, [sort_in]

.read_all:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, r13
    mov rdx, 65536
    sub rdx, r12
    jle .parse_ptrs
    syscall
    test rax, rax
    jle .parse_ptrs
    add r12, rax
    add r13, rax
    jmp .read_all

.parse_ptrs:
    test r12, r12
    jle .exit_ok

    mov byte [sort_in + r12], 0
    xor r14, r14
    xor rcx, rcx
    lea rbx, [sort_in]
    mov [line_ptrs], rbx
    inc r14

.scan_lines:
    cmp rcx, r12
    jge .do_sort
    mov al, byte [sort_in + rcx]
    cmp al, 10
    jne .next_c
    mov byte [sort_in + rcx], 0
    lea r8, [sort_in + rcx + 1]
    cmp rcx, r12
    jae .do_sort
    mov [line_ptrs + r14 * 8], r8
    inc r14
.next_c:
    inc rcx
    jmp .scan_lines

.do_sort:
    cmp r14, 1
    jle .print_sorted

    xor r8, r8
.outer_bubble:
    cmp r8, r14
    jge .print_sorted
    xor r9, r9
.inner_bubble:
    mov rax, r14
    dec rax
    sub rax, r8
    cmp r9, rax
    jge .next_outer

    mov rdi, [line_ptrs + r9 * 8]
    mov rsi, [line_ptrs + (r9 + 1) * 8]
    call str_cmp
    test eax, eax
    jle .no_swap

    mov rax, [line_ptrs + r9 * 8]
    mov rdx, [line_ptrs + (r9 + 1) * 8]
    mov [line_ptrs + r9 * 8], rdx
    mov [line_ptrs + (r9 + 1) * 8], rax

.no_swap:
    inc r9
    jmp .inner_bubble

.next_outer:
    inc r8
    jmp .outer_bubble

.print_sorted:
    xor r8, r8
.out_loop:
    cmp r8, r14
    jge .exit_ok
    mov rdi, [line_ptrs + r8 * 8]
    call print_line_z
    inc r8
    jmp .out_loop

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

str_cmp:
    xor rcx, rcx
.sc_loop:
    mov al, [rdi + rcx]
    mov dl, [rsi + rcx]
    cmp al, dl
    jne .sc_diff
    test al, al
    je .sc_same
    inc rcx
    jmp .sc_loop
.sc_diff:
    movzx eax, al
    movzx edx, dl
    sub eax, edx
    ret
.sc_same:
    xor eax, eax
    ret

print_line_z:
    push rbx
    mov rbx, rdi
    xor rdx, rdx
.pl_len:
    cmp byte [rbx + rdx], 0
    je .pl_out
    inc rdx
    jmp .pl_len
.pl_out:
    test rdx, rdx
    jz .pl_nl
    mov rsi, rbx
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
.pl_nl:
    push 10
    mov rsi, rsp
    mov rdx, 1
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    add rsp, 8
    pop rbx
    ret

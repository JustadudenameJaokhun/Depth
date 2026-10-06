default rel
%include "syscalls.inc"

global hinux_strlen
global hinux_strcmp
global hinux_strncmp
global hinux_strchr
global hinux_strrchr
global hinux_strcpy
global hinux_strcat
global hinux_toupper
global hinux_tolower
global hinux_atoi
global hinux_itoa

section .text

hinux_strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

hinux_strcmp:
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

hinux_strncmp:
    xor rcx, rcx
    test rdx, rdx
    jz .equal
.loop:
    cmp rcx, rdx
    je .equal
    mov al, byte [rdi + rcx]
    mov r8b, byte [rsi + rcx]
    cmp al, r8b
    jne .diff
    test al, al
    je .equal
    inc rcx
    jmp .loop
.diff:
    movzx eax, al
    movzx r8d, r8b
    sub eax, r8d
    ret
.equal:
    xor eax, eax
    ret

hinux_strchr:
    xor rax, rax
.loop:
    mov al, byte [rdi]
    cmp al, sil
    je .found
    test al, al
    je .not_found
    inc rdi
    jmp .loop
.found:
    mov rax, rdi
    ret
.not_found:
    xor rax, rax
    ret

hinux_strrchr:
    push rbx
    xor rbx, rbx
.loop:
    mov al, byte [rdi]
    cmp al, sil
    cmove rbx, rdi
    test al, al
    je .done
    inc rdi
    jmp .loop
.done:
    mov rax, rbx
    pop rbx
    ret

hinux_strcpy:
    mov rax, rdi
.loop:
    mov cl, byte [rsi]
    mov byte [rdi], cl
    test cl, cl
    je .done
    inc rsi
    inc rdi
    jmp .loop
.done:
    ret

hinux_strcat:
    push rbx
    mov rbx, rdi
.find_end:
    cmp byte [rdi], 0
    je .copy_str
    inc rdi
    jmp .find_end
.copy_str:
    mov cl, byte [rsi]
    mov byte [rdi], cl
    test cl, cl
    je .done
    inc rsi
    inc rdi
    jmp .copy_str
.done:
    mov rax, rbx
    pop rbx
    ret

hinux_toupper:
    mov rax, rdi
.loop:
    mov cl, byte [rdi]
    test cl, cl
    je .done
    cmp cl, 'a'
    jb .next
    cmp cl, 'z'
    ja .next
    sub cl, 32
    mov byte [rdi], cl
.next:
    inc rdi
    jmp .loop
.done:
    ret

hinux_tolower:
    mov rax, rdi
.loop:
    mov cl, byte [rdi]
    test cl, cl
    je .done
    cmp cl, 'A'
    jb .next
    cmp cl, 'Z'
    ja .next
    add cl, 32
    mov byte [rdi], cl
.next:
    inc rdi
    jmp .loop
.done:
    ret

hinux_atoi:
    xor rax, rax
    xor rcx, rcx
    xor r8, r8
    mov r9, 1
.trim:
    mov cl, byte [rdi]
    cmp cl, ' '
    je .skip_ws
    cmp cl, 9
    je .skip_ws
    cmp cl, 10
    je .skip_ws
    jmp .check_sign
.skip_ws:
    inc rdi
    jmp .trim
.check_sign:
    cmp cl, '-'
    jne .check_plus
    mov r9, -1
    inc rdi
    jmp .digits
.check_plus:
    cmp cl, '+'
    jne .digits
    inc rdi
.digits:
    mov cl, byte [rdi]
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rdi
    jmp .digits
.done:
    imul rax, r9
    ret

hinux_itoa:
    push rbx
    push r12
    push r13
    mov rax, rdi
    mov r12, rsi
    mov r13, rsi
    test rax, rax
    jns .positive
    neg rax
    mov byte [r12], '-'
    inc r12
    inc r13
.positive:
    mov rbx, 10
.divide_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov byte [r12], dl
    inc r12
    test rax, rax
    jnz .divide_loop
    mov byte [r12], 0
    mov rdi, r13
    lea rsi, [r12 - 1]
.reverse_loop:
    cmp rdi, rsi
    jge .finish
    mov al, [rdi]
    mov bl, [rsi]
    mov [rdi], bl
    mov [rsi], al
    inc rdi
    dec rsi
    jmp .reverse_loop
.finish:
    mov rax, r12
    pop r13
    pop r12
    pop rbx
    ret

default rel

global glare_render_halfblock_span
global glare_clear_cells
global glare_draw_box
global glare_pixel_downsample

section .data
    halfblock_utf8 db 0xE2, 0x96, 0x80
    ansi_fg_prefix db 0x1B, '[', '3', '8', ';', '2', ';'
    ansi_bg_prefix db 0x1B, '[', '4', '8', ';', '2', ';'
    ansi_reset     db 0x1B, '[', '0', 'm'

section .text

glare_render_halfblock_span:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx

.loop_cells:
    test r15, r15
    jz .done

    mov r8d, dword [r12]
    mov r9d, dword [r13]

    mov byte [r14], 0x1B
    mov byte [r14+1], '['
    mov byte [r14+2], '3'
    mov byte [r14+3], '8'
    mov byte [r14+4], ';'
    mov byte [r14+5], '2'
    mov byte [r14+6], ';'
    add r14, 7

    movzx eax, r8b
    call append_u8_dec

    mov byte [r14], ';'
    inc r14

    movzx eax, byte [r12+1]
    call append_u8_dec

    mov byte [r14], ';'
    inc r14

    movzx eax, byte [r12+2]
    call append_u8_dec

    mov byte [r14], 'm'
    inc r14

    mov byte [r14], 0x1B
    mov byte [r14+1], '['
    mov byte [r14+2], '4'
    mov byte [r14+3], '8'
    mov byte [r14+4], ';'
    mov byte [r14+5], '2'
    mov byte [r14+6], ';'
    add r14, 7

    movzx eax, r9b
    call append_u8_dec

    mov byte [r14], ';'
    inc r14

    movzx eax, byte [r12+1]
    call append_u8_dec

    mov byte [r14], ';'
    inc r14

    movzx eax, byte [r12+2]
    call append_u8_dec

    mov byte [r14], 'm'
    inc r14

    mov byte [r14], 0xE2
    mov byte [r14+1], 0x96
    mov byte [r14+2], 0x80
    add r14, 3

    add r12, 4
    add r13, 4
    dec r15
    jmp .loop_cells

.done:
    mov byte [r14], 0x1B
    mov byte [r14+1], '['
    mov byte [r14+2], '0'
    mov byte [r14+3], 'm'
    mov byte [r14+4], 0
    add r14, 4

    mov rax, r14
    sub rax, rdx

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

append_u8_dec:
    push rbx
    movzx ebx, al
    cmp ebx, 100
    jae .three_digits
    cmp ebx, 10
    jae .two_digits

.one_digit:
    add bl, '0'
    mov byte [r14], bl
    inc r14
    pop rbx
    ret

.two_digits:
    mov eax, ebx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [r14], al
    mov byte [r14+1], dl
    add r14, 2
    pop rbx
    ret

.three_digits:
    mov eax, ebx
    xor edx, edx
    mov ecx, 100
    div ecx
    add al, '0'
    mov byte [r14], al
    inc r14
    mov eax, edx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [r14], al
    mov byte [r14+1], dl
    add r14, 2
    pop rbx
    ret

glare_clear_cells:
    mov rax, rdx
    mov rcx, rsi
    rep stosb
    ret

glare_draw_box:
    ret

glare_pixel_downsample:
    xor rax, rax
    ret

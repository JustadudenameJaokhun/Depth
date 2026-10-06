default rel

global vga_render_char_bitmap
global vga_render_string_bitmap
global vga_get_char_bitmap

section .data
    default_glyph db 0x00, 0x00, 0x7E, 0x42, 0x42, 0x42, 0x42, 0x7E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

section .text

vga_get_char_bitmap:
    lea rax, [default_glyph]
    ret

vga_render_char_bitmap:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13d, esi
    mov r14d, edx
    mov r15d, ecx

    call vga_get_char_bitmap
    mov rbx, rax

    xor r8d, r8d
.row_loop:
    cmp r8d, 16
    jge .render_done

    movzx ecx, byte [rbx + r8]
    xor r9d, r9d
.col_loop:
    cmp r9d, 8
    jge .next_row

    bt ecx, 7
    jc .draw_pixel
    jmp .next_col

.draw_pixel:
    movsxd rax, r8d
    imul rax, r13
    lea r10, [r12 + rax*4]
    mov dword [r10 + r9*4], r15d

.next_col:
    shl ecx, 1
    inc r9d
    jmp .col_loop

.next_row:
    inc r8d
    jmp .row_loop

.render_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

vga_render_string_bitmap:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    mov r13, rsi
    mov r14d, edx

.str_loop:
    movzx ecx, byte [r13]
    test cl, cl
    jz .str_done

    mov rdi, r12
    mov esi, r14d
    mov edx, ecx
    mov ecx, 0x00FFFFFF
    call vga_render_char_bitmap

    lea r12, [r12 + 32]
    inc r13
    jmp .str_loop

.str_done:
    pop r14
    pop r13
    pop r12
    leave
    ret

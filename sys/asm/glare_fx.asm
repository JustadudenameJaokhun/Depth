default rel

global glare_fx_dim_color
global glare_fx_blend_rgba
global glare_fx_draw_box_shadow
global glare_fx_fill_rect
global glare_fx_apply_glass_blur
global glare_fx_interpolate_palette

section .text

glare_fx_dim_color:
    push rbp
    mov rbp, rsp

    mov eax, edi
    shr eax, 16
    and eax, 0xFF
    imul eax, esi
    shr eax, 8
    mov edx, eax
    shl edx, 16

    mov eax, edi
    shr eax, 8
    and eax, 0xFF
    imul eax, esi
    shr eax, 8
    shl eax, 8
    or edx, eax

    mov eax, edi
    and eax, 0xFF
    imul eax, esi
    shr eax, 8
    or eax, edx

    leave
    ret

glare_fx_blend_rgba:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r8d, edx
    and r8d, 0xFF
    mov r9d, 255
    sub r9d, r8d

    mov eax, edi
    shr eax, 16
    and eax, 0xFF
    imul eax, r8d

    mov ebx, esi
    shr ebx, 16
    and ebx, 0xFF
    imul ebx, r9d

    add eax, ebx
    shr eax, 8
    mov r10d, eax
    shl r10d, 16

    mov eax, edi
    shr eax, 8
    and eax, 0xFF
    imul eax, r8d

    mov ebx, esi
    shr ebx, 8
    and ebx, 0xFF
    imul ebx, r9d

    add eax, ebx
    shr eax, 8
    shl eax, 8
    or r10d, eax

    mov eax, edi
    and eax, 0xFF
    imul eax, r8d

    mov ebx, esi
    and ebx, 0xFF
    imul ebx, r9d

    add eax, ebx
    shr eax, 8
    or eax, r10d

    pop r12
    pop rbx
    leave
    ret

glare_fx_fill_rect:
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
    mov ebx, r8d

.row_loop:
    test r15d, r15d
    jz .fill_done

    mov r10, r12
    mov r11d, r14d

.col_loop:
    test r11d, r11d
    jz .next_row

    mov dword [r10], ebx
    add r10, 4
    dec r11d
    jmp .col_loop

.next_row:
    movsxd rax, r13d
    shl rax, 2
    add r12, rax
    dec r15d
    jmp .row_loop

.fill_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_fx_draw_box_shadow:
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

    mov rax, r12
    mov rbx, 0

.shadow_bottom:
    cmp rbx, r14
    jge .shadow_right
    mov dword [rax + rbx * 4], 0x101015
    inc rbx
    jmp .shadow_bottom

.shadow_right:
    mov rbx, 0
    movsxd rcx, r13d
    shl rcx, 2

.shadow_right_loop:
    cmp rbx, r15
    jge .shadow_done
    mov dword [r12 + r14 * 4], 0x101015
    add r12, rcx
    inc rbx
    jmp .shadow_right_loop

.shadow_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_fx_apply_glass_blur:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    mov r13d, esi

    xor r14, r14

.blur_step:
    cmp r14, r13
    jge .blur_fin

    mov eax, dword [r12 + r14 * 4]
    mov edi, eax
    mov esi, 0x12141c
    mov edx, 180
    call glare_fx_blend_rgba
    mov dword [r12 + r14 * 4], eax

    inc r14
    jmp .blur_step

.blur_fin:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_fx_interpolate_palette:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15d, ecx

    xor ebx, ebx

.palette_loop:
    cmp ebx, r15d
    jge .palette_done

    mov eax, ebx
    imul eax, 255
    xor edx, edx
    div r15d

    mov edi, r14d
    mov esi, dword [r13 + rbx * 4]
    mov edx, eax
    call glare_fx_blend_rgba
    mov dword [r12 + rbx * 4], eax

    inc ebx
    jmp .palette_loop

.palette_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

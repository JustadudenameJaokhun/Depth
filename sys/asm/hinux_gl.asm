default rel

global hinux_gl_init
global hinux_gl_clear
global hinux_gl_viewport
global hinux_gl_draw_triangles
global hinux_gl_swap_buffers
global hinux_gl_bind_texture
global hinux_gl_matrix_mul4x4
global hinux_gl_raster_triangle

section .bss
    gl_framebuffer resq 1
    gl_depthbuffer resq 1
    gl_tex_ptr resq 1
    gl_width resd 1
    gl_height resd 1
    gl_stride resd 1
    gl_tex_w resd 1
    gl_tex_h resd 1
    gl_clear_color resd 1
    gl_modelview resd 16
    gl_projection resd 16
    gl_mvp resd 16

section .rodata
    align 16
    gl_ident_mat:
        dd 0x3f800000, 0, 0, 0
        dd 0, 0x3f800000, 0, 0
        dd 0, 0, 0x3f800000, 0
        dd 0, 0, 0, 0x3f800000
    gl_one_f: dd 0x3f800000
    gl_half_f: dd 0x3f000000
    gl_zero_f: dd 0x00000000

section .text

hinux_gl_init:
    push rbp
    mov rbp, rsp
    mov [gl_framebuffer], rdi
    mov [gl_depthbuffer], rsi
    mov [gl_width], edx
    mov [gl_height], ecx
    mov eax, edx
    shl eax, 2
    mov [gl_stride], eax
    mov dword [gl_clear_color], 0
    lea rdi, [gl_modelview]
    lea rsi, [gl_ident_mat]
    mov ecx, 16
    rep movsd
    lea rdi, [gl_projection]
    lea rsi, [gl_ident_mat]
    mov ecx, 16
    rep movsd
    xor eax, eax
    leave
    ret

hinux_gl_viewport:
    push rbp
    mov rbp, rsp
    mov [gl_width], edi
    mov [gl_height], esi
    mov eax, edi
    shl eax, 2
    mov [gl_stride], eax
    xor eax, eax
    leave
    ret

hinux_gl_bind_texture:
    push rbp
    mov rbp, rsp
    mov [gl_tex_ptr], rdi
    mov [gl_tex_w], esi
    mov [gl_tex_h], edx
    xor eax, eax
    leave
    ret

hinux_gl_clear:
    push rbp
    mov rbp, rsp
    push rdi
    mov [gl_clear_color], edi
    mov rdi, [gl_framebuffer]
    test rdi, rdi
    jz .clear_depth
    mov eax, [gl_width]
    imul eax, [gl_height]
    mov ecx, eax
    mov eax, [gl_clear_color]
    rep stosd
.clear_depth:
    mov rdi, [gl_depthbuffer]
    test rdi, rdi
    jz .clear_done
    mov eax, [gl_width]
    imul eax, [gl_height]
    mov ecx, eax
    mov eax, 0x7f7fffff
    rep stosd
.clear_done:
    pop rdi
    xor eax, eax
    leave
    ret

hinux_gl_swap_buffers:
    push rbp
    mov rbp, rsp
    mov rax, 162
    syscall
    xor eax, eax
    leave
    ret

hinux_gl_matrix_mul4x4:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    xor r15d, r15d
.row_loop:
    cmp r15d, 4
    jge .mul_done
    movsxd rax, r15d
    shl rax, 4
    movups xmm0, [r13 + rax]
    xor ecx, ecx
.col_loop:
    cmp ecx, 4
    jge .next_row
    movss xmm1, [r14 + rcx*4]
    shufps xmm1, xmm1, 0
    mulps xmm1, xmm0
    movss xmm2, [r14 + rcx*4 + 16]
    shufps xmm2, xmm2, 0
    movups xmm3, [r13 + rax + 16]
    mulps xmm2, xmm3
    addps xmm1, xmm2
    movss xmm2, [r14 + rcx*4 + 32]
    shufps xmm2, xmm2, 0
    movups xmm3, [r13 + rax + 32]
    mulps xmm2, xmm3
    addps xmm1, xmm2
    movss xmm2, [r14 + rcx*4 + 48]
    shufps xmm2, xmm2, 0
    movups xmm3, [r13 + rax + 48]
    mulps xmm2, xmm3
    addps xmm1, xmm2
    movsxd r8, r15d
    shl r8, 4
    add r8, r12
    movss [r8 + rcx*4], xmm1
    inc ecx
    jmp .col_loop
.next_row:
    inc r15d
    jmp .row_loop
.mul_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret

hinux_gl_raster_triangle:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov eax, [r12]
    mov ebx, [r13]
    mov ecx, [r14]
    mov edx, eax
    cmp ebx, edx
    cmovl edx, ebx
    cmp ecx, edx
    cmovl edx, ecx
    test edx, edx
    jns .min_x_ok
    xor edx, edx
.min_x_ok:
    mov [rbp - 4], edx
    mov edx, eax
    cmp ebx, edx
    cmovg edx, ebx
    cmp ecx, edx
    cmovg edx, ecx
    mov esi, [gl_width]
    dec esi
    cmp edx, esi
    cmovg edx, esi
    mov [rbp - 8], edx
    mov eax, [r12 + 4]
    mov ebx, [r13 + 4]
    mov ecx, [r14 + 4]
    mov edx, eax
    cmp ebx, edx
    cmovl edx, ebx
    cmp ecx, edx
    cmovl edx, ecx
    test edx, edx
    jns .min_y_ok
    xor edx, edx
.min_y_ok:
    mov [rbp - 12], edx
    mov edx, eax
    cmp ebx, edx
    cmovg edx, ebx
    cmp ecx, edx
    cmovg edx, ecx
    mov esi, [gl_height]
    dec esi
    cmp edx, esi
    cmovg edx, esi
    mov [rbp - 16], edx
    mov eax, [r13]
    sub eax, [r12]
    mov ebx, [r14 + 4]
    sub ebx, [r12 + 4]
    imul eax, ebx
    mov ecx, [r13 + 4]
    sub ecx, [r12 + 4]
    mov edx, [r14]
    sub edx, [r12]
    imul ecx, edx
    sub eax, ecx
    test eax, eax
    jz .raster_exit
    mov [rbp - 20], eax
    mov ebx, [rbp - 12]
.y_scan_loop:
    cmp ebx, [rbp - 16]
    jg .raster_exit
    mov ecx, [rbp - 4]
.x_scan_loop:
    cmp ecx, [rbp - 8]
    jg .next_y_scan
    mov eax, [r13]
    sub eax, [r12]
    mov edx, ebx
    sub edx, [r12 + 4]
    imul eax, edx
    mov edx, [r13 + 4]
    sub edx, [r12 + 4]
    mov esi, ecx
    sub esi, [r12]
    imul edx, esi
    sub eax, edx
    mov esi, [rbp - 20]
    test esi, esi
    js .chk_neg1
    test eax, eax
    js .skip_pixel
    jmp .chk_edge2
.chk_neg1:
    test eax, eax
    jns .skip_pixel
.chk_edge2:
    mov eax, [r14]
    sub eax, [r13]
    mov edx, ebx
    sub edx, [r13 + 4]
    imul eax, edx
    mov edx, [r14 + 4]
    sub edx, [r13 + 4]
    mov esi, ecx
    sub esi, [r13]
    imul edx, esi
    sub eax, edx
    mov esi, [rbp - 20]
    test esi, esi
    js .chk_neg2
    test eax, eax
    js .skip_pixel
    jmp .chk_edge3
.chk_neg2:
    test eax, eax
    jns .skip_pixel
.chk_edge3:
    mov eax, [r12]
    sub eax, [r14]
    mov edx, ebx
    sub edx, [r14 + 4]
    imul eax, edx
    mov edx, [r12 + 4]
    sub edx, [r14 + 4]
    mov esi, ecx
    sub esi, [r14]
    imul edx, esi
    sub eax, edx
    mov esi, [rbp - 20]
    test esi, esi
    js .chk_neg3
    test eax, eax
    js .skip_pixel
    jmp .draw_pixel
.chk_neg3:
    test eax, eax
    jns .skip_pixel
.draw_pixel:
    movsxd rax, ebx
    imul rax, [gl_stride]
    movsxd rdx, ecx
    shl rdx, 2
    add rax, rdx
    mov r8, [gl_framebuffer]
    test r8, r8
    jz .skip_pixel
    mov edx, [r15]
    mov [r8 + rax], edx
.skip_pixel:
    inc ecx
    jmp .x_scan_loop
.next_y_scan:
    inc ebx
    jmp .y_scan_loop
.raster_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

hinux_gl_draw_triangles:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13d, esi
    mov r14, rdx
    xor r15d, r15d
.tri_loop:
    cmp r15d, r13d
    jge .draw_done
    movsxd rax, r15d
    imul rax, 48
    lea rdi, [r12 + rax]
    lea rsi, [r12 + rax + 16]
    lea rdx, [r12 + rax + 32]
    mov rcx, r14
    call hinux_gl_raster_triangle
    inc r15d
    jmp .tri_loop
.draw_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret

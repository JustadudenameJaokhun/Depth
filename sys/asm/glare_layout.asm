default rel

global glare_layout_calc_split_h
global glare_layout_calc_split_v
global glare_layout_clamp_bounds
global glare_layout_point_in_rect
global glare_layout_rect_intersects
global glare_layout_tile_windows

section .text

glare_layout_calc_split_h:
    push rbp
    mov rbp, rsp

    mov eax, edx
    shr eax, 1

    mov dword [r8], edi
    mov dword [r8 + 4], esi
    mov dword [r8 + 8], eax
    mov dword [r8 + 12], ecx

    mov r9d, edx
    sub r9d, eax
    add edi, eax

    mov dword [r8 + 16], edi
    mov dword [r8 + 20], esi
    mov dword [r8 + 24], r9d
    mov dword [r8 + 28], ecx

    leave
    ret

glare_layout_calc_split_v:
    push rbp
    mov rbp, rsp

    mov eax, ecx
    shr eax, 1

    mov dword [r8], edi
    mov dword [r8 + 4], esi
    mov dword [r8 + 8], edx
    mov dword [r8 + 12], eax

    mov r9d, ecx
    sub r9d, eax
    add esi, eax

    mov dword [r8 + 16], edi
    mov dword [r8 + 20], esi
    mov dword [r8 + 24], edx
    mov dword [r8 + 28], r9d

    leave
    ret

glare_layout_clamp_bounds:
    push rbp
    mov rbp, rsp

    mov eax, dword [rdi]
    test eax, eax
    jns .chk_max_x
    xor eax, eax
    mov dword [rdi], eax

.chk_max_x:
    mov edx, dword [rdi + 8]
    add eax, edx
    cmp eax, esi
    jle .chk_y
    mov eax, esi
    sub eax, edx
    test eax, eax
    jns .set_clamped_x
    xor eax, eax
.set_clamped_x:
    mov dword [rdi], eax

.chk_y:
    mov eax, dword [rdi + 4]
    test eax, eax
    jns .chk_max_y
    xor eax, eax
    mov dword [rdi + 4], eax

.chk_max_y:
    mov edx, dword [rdi + 12]
    add eax, edx
    cmp eax, edx
    jle .clamp_fin
    cmp eax, edx
    jl .clamp_fin

.clamp_fin:
    leave
    ret

glare_layout_point_in_rect:
    push rbp
    mov rbp, rsp

    cmp edi, edx
    jl .not_in
    mov eax, edx
    add eax, r8d
    cmp edi, eax
    jge .not_in

    cmp esi, ecx
    jl .not_in
    mov eax, ecx
    add eax, r9d
    cmp esi, eax
    jge .not_in

    mov eax, 1
    leave
    ret

.not_in:
    xor eax, eax
    leave
    ret

glare_layout_rect_intersects:
    push rbp
    mov rbp, rsp

    mov r10d, edi
    add r10d, edx
    cmp r10d, r8d
    jle .no_intersect

    mov r10d, r8d
    mov eax, [rbp + 16]
    add r10d, eax
    cmp edi, r10d
    jge .no_intersect

    mov r10d, esi
    add r10d, ecx
    cmp r10d, r9d
    jle .no_intersect

    mov r10d, r9d
    mov eax, [rbp + 24]
    add r10d, eax
    cmp esi, r10d
    jge .no_intersect

    mov eax, 1
    leave
    ret

.no_intersect:
    xor eax, eax
    leave
    ret

glare_layout_tile_windows:
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

    test r13d, r13d
    jle .tile_done

    cmp r13d, 1
    jne .tile_two

    mov dword [r12], 1
    mov dword [r12 + 4], 1
    mov eax, r14d
    sub eax, 2
    mov dword [r12 + 8], eax
    mov eax, r15d
    sub eax, 3
    mov dword [r12 + 12], eax
    jmp .tile_done

.tile_two:
    mov eax, r14d
    shr eax, 1
    dec eax

    mov dword [r12], 1
    mov dword [r12 + 4], 1
    mov dword [r12 + 8], eax
    mov ebx, r15d
    sub ebx, 3
    mov dword [r12 + 12], ebx

    lea rdi, [r12 + 16]
    mov edx, eax
    add edx, 2
    mov dword [rdi], edx
    mov dword [rdi + 4], 1
    mov edx, r14d
    sub edx, eax
    sub edx, 3
    mov dword [rdi + 8], edx
    mov dword [rdi + 12], ebx

.tile_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

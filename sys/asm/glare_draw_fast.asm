default rel

global glare_fast_draw_row
global glare_compute_cell_hash
global glare_pack_rgb
global glare_unpack_rgb

section .text

glare_fast_draw_row:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    mov r13, rsi
    mov r14d, edx

.loop:
    test r14d, r14d
    jz .done

    mov eax, dword [r13]
    mov dword [r12], eax
    mov eax, dword [r13 + 4]
    mov dword [r12 + 4], eax

    add r12, 8
    add r13, 8
    dec r14d
    jmp .loop

.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_compute_cell_hash:
    push rbp
    mov rbp, rsp
    mov eax, 5381
    mov rcx, rsi

.h_loop:
    test rcx, rcx
    jz .h_done
    movzx edx, byte [rdi]
    imul eax, eax, 33
    xor eax, edx
    inc rdi
    dec rcx
    jmp .h_loop

.h_done:
    leave
    ret

glare_pack_rgb:
    push rbp
    mov rbp, rsp
    movzx eax, dil
    shl eax, 8
    movzx ecx, sil
    or eax, ecx
    shl eax, 8
    movzx edx, dl
    or eax, edx
    leave
    ret

glare_unpack_rgb:
    push rbp
    mov rbp, rsp
    mov eax, edi
    shr eax, 16
    and eax, 0xFF
    mov byte [rsi], al

    mov eax, edi
    shr eax, 8
    and eax, 0xFF
    mov byte [rdx], al

    mov eax, edi
    and eax, 0xFF
    mov byte [rcx], al
    leave
    ret

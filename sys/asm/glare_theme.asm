default rel

global glare_theme_get_color
global glare_theme_lerp_rgb
global glare_theme_build_ansi_fg
global glare_theme_build_ansi_bg

section .data
    bedrock_theme_colors:
        dd 0x00E61E1E
        dd 0x008C1414
        dd 0x0019191E
        dd 0x0028282D
        dd 0x00E0E0E0
        dd 0x00A0A0A0
        dd 0x000F0F12
        dd 0x00FFFFFF

    solar_theme_colors:
        dd 0x00268BD2
        dd 0x002AA198
        dd 0x00002B36
        dd 0x00073642
        dd 0x0093A1A1
        dd 0x00657B83
        dd 0x00001E26
        dd 0x00FDF6E3

section .bss
    ansi_fg_buf resb 32
    ansi_bg_buf resb 32

section .text

glare_theme_get_color:
    and esi, 7
    test edi, edi
    jnz .solar
    lea rax, [bedrock_theme_colors]
    mov eax, dword [rax + rsi*4]
    ret
.solar:
    lea rax, [solar_theme_colors]
    mov eax, dword [rax + rsi*4]
    ret

glare_theme_lerp_rgb:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r8d, edi
    mov r9d, esi
    mov r10d, edx

    mov eax, r8d
    and eax, 0xFF
    mov ebx, r9d
    and ebx, 0xFF
    sub ebx, eax
    imul ebx, r10d
    sar ebx, 8
    add eax, ebx
    mov r11d, eax

    mov eax, r8d
    shr eax, 8
    and eax, 0xFF
    mov ebx, r9d
    shr ebx, 8
    and ebx, 0xFF
    sub ebx, eax
    imul ebx, r10d
    sar ebx, 8
    add eax, ebx
    shl eax, 8
    or r11d, eax

    mov eax, r8d
    shr eax, 16
    and eax, 0xFF
    mov ebx, r9d
    shr ebx, 16
    and ebx, 0xFF
    sub ebx, eax
    imul ebx, r10d
    sar ebx, 8
    add eax, ebx
    shl eax, 16
    or eax, r11d

    pop r12
    pop rbx
    leave
    ret

glare_theme_build_ansi_fg:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12d, edi
    lea rdi, [ansi_fg_buf]
    mov byte [rdi], 0x1B
    mov byte [rdi+1], '['
    mov byte [rdi+2], '3'
    mov byte [rdi+3], '8'
    mov byte [rdi+4], ';'
    mov byte [rdi+5], '2'
    mov byte [rdi+6], ';'
    add rdi, 7

    mov eax, r12d
    shr eax, 16
    and eax, 0xFF
    call write_u8

    mov byte [rdi], ';'
    inc rdi

    mov eax, r12d
    shr eax, 8
    and eax, 0xFF
    call write_u8

    mov byte [rdi], ';'
    inc rdi

    mov eax, r12d
    and eax, 0xFF
    call write_u8

    mov byte [rdi], 'm'
    mov byte [rdi+1], 0

    lea rax, [ansi_fg_buf]
    pop r12
    pop rbx
    leave
    ret

glare_theme_build_ansi_bg:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12d, edi
    lea rdi, [ansi_bg_buf]
    mov byte [rdi], 0x1B
    mov byte [rdi+1], '['
    mov byte [rdi+2], '4'
    mov byte [rdi+3], '8'
    mov byte [rdi+4], ';'
    mov byte [rdi+5], '2'
    mov byte [rdi+6], ';'
    add rdi, 7

    mov eax, r12d
    shr eax, 16
    and eax, 0xFF
    call write_u8

    mov byte [rdi], ';'
    inc rdi

    mov eax, r12d
    shr eax, 8
    and eax, 0xFF
    call write_u8

    mov byte [rdi], ';'
    inc rdi

    mov eax, r12d
    and eax, 0xFF
    call write_u8

    mov byte [rdi], 'm'
    mov byte [rdi+1], 0

    lea rax, [ansi_bg_buf]
    pop r12
    pop rbx
    leave
    ret

write_u8:
    push rbx
    cmp eax, 100
    jae .w_three
    cmp eax, 10
    jae .w_two

.w_one:
    add al, '0'
    mov byte [rdi], al
    inc rdi
    pop rbx
    ret

.w_two:
    mov ebx, eax
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [rdi], al
    mov byte [rdi+1], dl
    add rdi, 2
    pop rbx
    ret

.w_three:
    mov ebx, eax
    xor edx, edx
    mov ecx, 100
    div ecx
    add al, '0'
    mov byte [rdi], al
    inc rdi
    mov eax, edx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [rdi], al
    mov byte [rdi+1], dl
    add rdi, 2
    pop rbx
    ret

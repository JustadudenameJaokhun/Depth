default rel
%include "syscalls.inc"

global hinux_memzero_avx2
global hinux_memcpy_avx2
global hinux_memcmp_avx2
global hinux_memchr_avx2
global hinux_hash_fnv1a
global hinux_crc32c

section .text

hinux_memzero_avx2:
    test rsi, rsi
    jz .done_zero
    vpxor ymm0, ymm0, ymm0
    mov rcx, rsi
    shr rcx, 5
    jz .tail_zero

.loop32_zero:
    vmovdqu [rdi], ymm0
    add rdi, 32
    dec rcx
    jnz .loop32_zero

.tail_zero:
    mov rcx, rsi
    and rcx, 31
    jz .done_zero

.tail_byte_zero:
    mov byte [rdi], 0
    inc rdi
    dec rcx
    jnz .tail_byte_zero

.done_zero:
    vzeroupper
    ret

hinux_memcpy_avx2:
    test rdx, rdx
    jz .done_cpy
    mov rax, rdi
    mov rcx, rdx
    shr rcx, 5
    jz .tail_cpy

.loop32_cpy:
    vmovdqu ymm0, [rsi]
    vmovdqu [rdi], ymm0
    add rsi, 32
    add rdi, 32
    dec rcx
    jnz .loop32_cpy

.tail_cpy:
    mov rcx, rdx
    and rcx, 31
    jz .done_cpy

.tail_byte_cpy:
    mov r8b, byte [rsi]
    mov byte [rdi], r8b
    inc rsi
    inc rdi
    dec rcx
    jnz .tail_byte_cpy

.done_cpy:
    vzeroupper
    ret

hinux_memcmp_avx2:
    xor rax, rax
    test rdx, rdx
    jz .done_cmp

.loop_cmp:
    mov cl, byte [rdi]
    mov r8b, byte [rsi]
    cmp cl, r8b
    jne .diff_cmp
    inc rdi
    inc rsi
    dec rdx
    jnz .loop_cmp
    xor eax, eax
    ret

.diff_cmp:
    movzx eax, cl
    movzx r8d, r8b
    sub eax, r8d
    ret

.done_cmp:
    xor eax, eax
    ret

hinux_memchr_avx2:
    xor rax, rax
    test rdx, rdx
    jz .done_chr

.loop_chr:
    cmp byte [rdi], sil
    je .found_chr
    inc rdi
    dec rdx
    jnz .loop_chr
    xor rax, rax
    ret

.found_chr:
    mov rax, rdi
    ret

.done_chr:
    xor rax, rax
    ret

hinux_hash_fnv1a:
    mov rax, 0xcbf29ce484222325
    mov r8, 0x100000001b3
    test rsi, rsi
    jz .done_hash

.loop_hash:
    movzx rcx, byte [rdi]
    xor rax, rcx
    mul r8
    inc rdi
    dec rsi
    jnz .loop_hash

.done_hash:
    ret

hinux_crc32c:
    mov eax, edi
    test rdx, rdx
    jz .done_crc

    mov rcx, rdx
    shr rcx, 3
    jz .tail_crc

.loop_crc8:
    crc32 rax, qword [rsi]
    add rsi, 8
    dec rcx
    jnz .loop_crc8

.tail_crc:
    mov rcx, rdx
    and rcx, 7
    jz .done_crc

.loop_crc1:
    crc32 eax, byte [rsi]
    inc rsi
    dec rcx
    jnz .loop_crc1

.done_crc:
    ret

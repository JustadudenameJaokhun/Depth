default rel
%include "syscalls.inc"

global hinux_vec4_add
global hinux_vec4_sub
global hinux_vec4_mul
global hinux_vec4_dot
global hinux_vec4_norm
global hinux_mat4_mul
global hinux_fast_rsqrt

section .text

hinux_vec4_add:
    vmovups xmm0, [rdi]
    vmovups xmm1, [rsi]
    vaddps xmm0, xmm0, xmm1
    vmovups [rdx], xmm0
    ret

hinux_vec4_sub:
    vmovups xmm0, [rdi]
    vmovups xmm1, [rsi]
    vsubps xmm0, xmm0, xmm1
    vmovups [rdx], xmm0
    ret

hinux_vec4_mul:
    vmovups xmm0, [rdi]
    vmovups xmm1, [rsi]
    vmulps xmm0, xmm0, xmm1
    vmovups [rdx], xmm0
    ret

hinux_vec4_dot:
    vmovups xmm0, [rdi]
    vmovups xmm1, [rsi]
    vdpps xmm0, xmm0, xmm1, 0xf1
    ret

hinux_vec4_norm:
    vmovups xmm0, [rdi]
    vdpps xmm1, xmm0, xmm0, 0xff
    vrsqrtps xmm1, xmm1
    vmulps xmm0, xmm0, xmm1
    vmovups [rsi], xmm0
    ret

hinux_fast_rsqrt:
    vrsqrtss xmm0, xmm0, xmm0
    ret

hinux_mat4_mul:
    push rbx
    push r12
    push r13

    vmovups xmm0, [rsi]
    vmovups xmm1, [rsi + 16]
    vmovups xmm2, [rsi + 32]
    vmovups xmm3, [rsi + 48]

    xor rcx, rcx
.row_loop:
    cmp rcx, 4
    jge .done_mat

    mov rax, rcx
    shl rax, 4
    vbroadcastss xmm4, [rdi + rax]
    vbroadcastss xmm5, [rdi + rax + 4]
    vbroadcastss xmm6, [rdi + rax + 8]
    vbroadcastss xmm7, [rdi + rax + 12]

    vmulps xmm4, xmm4, xmm0
    vmulps xmm5, xmm5, xmm1
    vmulps xmm6, xmm6, xmm2
    vmulps xmm7, xmm7, xmm3

    vaddps xmm4, xmm4, xmm5
    vaddps xmm6, xmm6, xmm7
    vaddps xmm4, xmm4, xmm6

    vmovups [rdx + rax], xmm4
    inc rcx
    jmp .row_loop

.done_mat:
    vzeroupper
    pop r13
    pop r12
    pop rbx
    ret

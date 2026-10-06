default rel
%include "syscalls.inc"

global hinux_sha256_init
global hinux_sha256_transform
global hinux_sha256_hash

section .data
sha256_h0 dd 0x6a09e667
sha256_h1 dd 0xbb67ae85
sha256_h2 dd 0x3c6ef372
sha256_h3 dd 0xa54ff53a
sha256_h4 dd 0x510e527f
sha256_h5 dd 0x9b05688c
sha256_h6 dd 0x1f83d9ab
sha256_h7 dd 0x5be0cd19

sha256_k dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
         dd 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
         dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
         dd 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
         dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
         dd 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
         dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
         dd 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
         dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
         dd 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
         dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
         dd 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
         dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
         dd 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
         dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
         dd 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

section .bss
sha256_w resd 64

section .text

hinux_sha256_init:
    mov eax, [sha256_h0]
    mov [rdi], eax
    mov eax, [sha256_h1]
    mov [rdi + 4], eax
    mov eax, [sha256_h2]
    mov [rdi + 8], eax
    mov eax, [sha256_h3]
    mov [rdi + 12], eax
    mov eax, [sha256_h4]
    mov [rdi + 16], eax
    mov eax, [sha256_h5]
    mov [rdi + 20], eax
    mov eax, [sha256_h6]
    mov [rdi + 24], eax
    mov eax, [sha256_h7]
    mov [rdi + 28], eax
    ret

hinux_sha256_transform:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp

    mov r12, rdi
    mov r13, rsi

    xor rcx, rcx
.prep_w:
    cmp rcx, 16
    jge .expand_w
    mov eax, [r13 + rcx * 4]
    bswap eax
    mov [sha256_w + rcx * 4], eax
    inc rcx
    jmp .prep_w

.expand_w:
    cmp rcx, 64
    jge .init_state

    mov eax, [sha256_w + (rcx - 2) * 4]
    mov edx, eax
    ror edx, 17
    mov ebx, eax
    ror ebx, 19
    xor edx, ebx
    shr eax, 10
    xor edx, eax

    mov eax, [sha256_w + (rcx - 15) * 4]
    mov ebx, eax
    ror ebx, 7
    mov esi, eax
    ror esi, 18
    xor ebx, esi
    shr eax, 3
    xor ebx, eax

    add edx, [sha256_w + (rcx - 7) * 4]
    add edx, [sha256_w + (rcx - 16) * 4]
    add edx, ebx
    mov [sha256_w + rcx * 4], edx

    inc rcx
    jmp .expand_w

.init_state:
    mov eax, [r12]
    mov ebx, [r12 + 4]
    mov ecx, [r12 + 8]
    mov edx, [r12 + 12]
    mov r8d, [r12 + 16]
    mov r9d, [r12 + 20]
    mov r10d, [r12 + 24]
    mov r11d, [r12 + 28]

    xor r14, r14
.round_loop:
    cmp r14, 64
    jge .add_state

    mov r15d, r8d
    ror r15d, 6
    mov ebp, r8d
    ror ebp, 11
    xor r15d, ebp
    mov ebp, r8d
    ror ebp, 25
    xor r15d, ebp

    mov ebp, r8d
    and ebp, r9d
    mov esi, r8d
    not esi
    and esi, r10d
    xor ebp, esi

    add r15d, r11d
    add r15d, ebp
    add r15d, [sha256_k + r14 * 4]
    add r15d, [sha256_w + r14 * 4]

    mov ebp, eax
    ror ebp, 2
    mov esi, eax
    ror esi, 13
    xor ebp, esi
    mov esi, eax
    ror esi, 22
    xor ebp, esi

    mov esi, eax
    and esi, ebx
    mov edi, eax
    and edi, ecx
    xor esi, edi
    mov edi, ebx
    and edi, ecx
    xor esi, edi

    add ebp, esi

    mov r11d, r10d
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, edx
    add r8d, r15d
    mov edx, ecx
    mov ecx, ebx
    mov ebx, eax
    mov eax, r15d
    add eax, ebp

    inc r14
    jmp .round_loop

.add_state:
    add [r12], eax
    add [r12 + 4], ebx
    add [r12 + 8], ecx
    add [r12 + 12], edx
    add [r12 + 16], r8d
    add [r12 + 20], r9d
    add [r12 + 24], r10d
    add [r12 + 28], r11d

    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hinux_sha256_hash:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx

    mov rdi, rbx
    call hinux_sha256_init

    mov rdi, rbx
    mov rsi, r12
    call hinux_sha256_transform

    pop r13
    pop r12
    pop rbx
    ret

default rel

section .bss
align 4096
frame_bitmap:
    resb 16384
current_cr3:
    resq 1

section .text
bits 64
global mm_init
global alloc_frame
global free_frame
global map_page

mm_init:
    push rdi
    push rcx
    push rax

    lea rdi, [frame_bitmap]
    mov rcx, 16384 / 8
    xor rax, rax
    cld
    rep stosq

    mov rax, cr3
    mov [current_cr3], rax

    pop rax
    pop rcx
    pop rdi
    ret

alloc_frame:
    push rbx
    push rcx
    push rdx

    mov rcx, 0
.search_byte:
    cmp rcx, 16384
    jge .out_of_mem

    cmp byte [frame_bitmap + rcx], 0xFF
    jne .found_byte

    inc rcx
    jmp .search_byte

.found_byte:
    mov bl, [frame_bitmap + rcx]
    mov rdx, 0
.search_bit:
    bt bx, dx
    jnc .bit_free
    inc rdx
    cmp rdx, 8
    jl .search_bit
    inc rcx
    jmp .search_byte

.bit_free:
    bts bx, dx
    mov [frame_bitmap + rcx], bl

    imul rax, rcx, 8
    add rax, rdx
    shl rax, 12
    add rax, 0x1000000

    pop rdx
    pop rcx
    pop rbx
    ret

.out_of_mem:
    xor rax, rax
    pop rdx
    pop rcx
    pop rbx
    ret

free_frame:
    push rbx
    push rcx
    push rdx

    sub rdi, 0x1000000
    shr rdi, 12
    mov rax, rdi

    mov rcx, rax
    shr rcx, 3

    mov rdx, rax
    mov al, [frame_bitmap + rcx]
    btr ax, dx
    mov [frame_bitmap + rcx], al

    pop rdx
    pop rcx
    pop rbx
    ret

map_page:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi
    mov r14, rdx

    mov r15, [current_cr3]
    and r15, ~0xFFF

    mov rbx, r12
    shr rbx, 39
    and rbx, 0x1FF

    test qword [r15 + rbx * 8], 1
    jnz .pdp_exists

    call alloc_frame
    or rax, 7
    mov [r15 + rbx * 8], rax

.pdp_exists:
    mov r15, [r15 + rbx * 8]
    and r15, ~0xFFF

    mov rbx, r12
    shr rbx, 30
    and rbx, 0x1FF

    test qword [r15 + rbx * 8], 1
    jnz .pd_exists

    call alloc_frame
    or rax, 7
    mov [r15 + rbx * 8], rax

.pd_exists:
    mov r15, [r15 + rbx * 8]
    and r15, ~0xFFF

    mov rbx, r12
    shr rbx, 21
    and rbx, 0x1FF

    test qword [r15 + rbx * 8], 1
    jnz .pt_exists

    call alloc_frame
    or rax, 7
    mov [r15 + rbx * 8], rax

.pt_exists:
    mov r15, [r15 + rbx * 8]
    and r15, ~0xFFF

    mov rbx, r12
    shr rbx, 12
    and rbx, 0x1FF

    mov rax, r13
    or rax, r14
    mov [r15 + rbx * 8], rax

    invlpg [r12]

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

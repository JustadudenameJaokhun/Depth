default rel

section .data
vga_row: dq 0
vga_col: dq 0
vga_color: db 0x0C

section .text
bits 64
global vga_clear
global vga_putc
global vga_print
global vga_print_red
global vga_print_white
global vga_print_dark
global vga_print_hex64
global serial_init
global serial_putc
global serial_print
global kprint
global kprint_red
global kprint_white
global kprint_hex

vga_clear:
    push rdi
    push rcx
    push rax
    mov rdi, 0xB8000
    mov rcx, 80 * 25
    mov ah, [vga_color]
    mov al, ' '
    cld
    rep stosw
    mov qword [vga_row], 0
    mov qword [vga_col], 0
    pop rax
    pop rcx
    pop rdi
    ret

vga_putc:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    cmp al, 10
    je .newline

    mov rbx, [vga_row]
    imul rbx, 80
    add rbx, [vga_col]
    shl rbx, 1
    mov rdi, 0xB8000
    add rdi, rbx

    mov ah, [vga_color]
    mov [rdi], ax

    inc qword [vga_col]
    cmp qword [vga_col], 80
    jl .done

.newline:
    mov qword [vga_col], 0
    inc qword [vga_row]
    cmp qword [vga_row], 25
    jl .done

    mov rdi, 0xB8000
    mov rsi, 0xB8000 + 160
    mov rcx, 80 * 24
    cld
    rep movsw

    mov rdi, 0xB8000 + 80 * 24 * 2
    mov rcx, 80
    mov ah, [vga_color]
    mov al, ' '
    rep stosw

    mov qword [vga_row], 24

.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

vga_print:
    push rsi
    push rax
    mov rsi, rdi
.loop:
    lodsb
    test al, al
    jz .done
    call vga_putc
    jmp .loop
.done:
    pop rax
    pop rsi
    ret

vga_print_red:
    mov byte [vga_color], 0x0C
    call vga_print
    ret

vga_print_white:
    mov byte [vga_color], 0x0F
    call vga_print
    ret

vga_print_dark:
    mov byte [vga_color], 0x04
    call vga_print
    ret

vga_print_hex64:
    push rax
    push rbx
    push rcx
    push rdx

    mov rdx, rdi
    mov rcx, 16
.loop:
    rol rdx, 4
    mov rax, rdx
    and rax, 0x0F
    cmp rax, 10
    jl .digit
    add rax, 'A' - 10
    jmp .put
.digit:
    add rax, '0'
.put:
    call vga_putc
    dec rcx
    jnz .loop

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

serial_init:
    push rax
    push rdx

    mov dx, 0x3F9
    xor al, al
    out dx, al

    mov dx, 0x3FB
    mov al, 0x80
    out dx, al

    mov dx, 0x3F8
    mov al, 0x03
    out dx, al

    mov dx, 0x3F9
    xor al, al
    out dx, al

    mov dx, 0x3FB
    mov al, 0x03
    out dx, al

    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al

    mov dx, 0x3FC
    mov al, 0x0B
    out dx, al

    pop rdx
    pop rax
    ret

serial_putc:
    push rdx
    push rax
    mov rbx, rax
.wait:
    mov dx, 0x3FD
    in al, dx
    test al, 0x20
    jz .wait

    mov dx, 0x3F8
    mov rax, rbx
    out dx, al

    pop rax
    pop rdx
    ret

serial_print:
    push rsi
    push rax
    mov rsi, rdi
.loop:
    lodsb
    test al, al
    jz .done
    call serial_putc
    jmp .loop
.done:
    pop rax
    pop rsi
    ret

kprint:
    push rdi
    call vga_print
    pop rdi
    call serial_print
    ret

kprint_red:
    push rdi
    call vga_print_red
    pop rdi
    call serial_print
    ret

kprint_white:
    push rdi
    call vga_print_white
    pop rdi
    call serial_print
    ret

kprint_hex:
    push rdi
    call vga_print_hex64
    pop rdi
    ret

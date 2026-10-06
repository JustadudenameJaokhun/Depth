default rel
%include "syscalls.inc"

global hinux_elf_validate
global hinux_elf_entry
global hinux_elf_phoff
global hinux_elf_phnum
global hinux_elf_parse_header
global hinux_elf_find_pt_load

section .data
elf_magic db 0x7f, "ELF"

section .text

hinux_elf_validate:
    mov rax, [rdi]
    cmp eax, [elf_magic]
    jne .invalid

    cmp byte [rdi + 4], 2
    jne .invalid

    cmp byte [rdi + 5], 1
    jne .invalid

    cmp word [rdi + 18], 0x3e
    jne .invalid

    mov eax, 1
    ret

.invalid:
    xor eax, eax
    ret

hinux_elf_entry:
    call hinux_elf_validate
    test eax, eax
    jz .err_entry
    mov rax, [rdi + 24]
    ret

.err_entry:
    xor rax, rax
    ret

hinux_elf_phoff:
    call hinux_elf_validate
    test eax, eax
    jz .err_phoff
    mov rax, [rdi + 32]
    ret

.err_phoff:
    xor rax, rax
    ret

hinux_elf_phnum:
    call hinux_elf_validate
    test eax, eax
    jz .err_phnum
    movzx rax, word [rdi + 56]
    ret

.err_phnum:
    xor rax, rax
    ret

hinux_elf_parse_header:
    push rbx
    push r12
    mov r12, rdi
    call hinux_elf_validate
    test eax, eax
    jz .parse_fail

    mov rax, [r12 + 24]
    mov rbx, [r12 + 32]
    movzx rcx, word [r12 + 56]
    movzx rdx, word [r12 + 54]
    pop r12
    pop rbx
    mov eax, 1
    ret

.parse_fail:
    pop r12
    pop rbx
    xor eax, eax
    ret

hinux_elf_find_pt_load:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    movzx r14, dx
    xor rbx, rbx

.scan_ph:
    cmp rbx, r14
    jge .not_found

    mov eax, dword [r13]
    cmp eax, 1
    je .found_load

    add r13, 56
    inc rbx
    jmp .scan_ph

.found_load:
    mov rax, r13
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.not_found:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

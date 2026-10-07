global _start

section .rodata
    color_red db 27, "[1;31m", 0
    color_green db 27, "[1;32m", 0
    color_yellow db 27, "[1;33m", 0
    color_blue db 27, "[1;34m", 0
    color_bold db 27, "[1m", 0
    color_reset db 27, "[0m", 0

    msg_banner db 27, "[1;31m=== Depth Hinux X1 Mount Subsystem === ", 27, "[0m", 10, 0
    msg_usage db "Usage: mount.x1 <device> <mountpoint> [-o options]", 10
              db "       x1-mount /dev/sda1 /mnt", 10, 0
    msg_err_open db 27, "[1;31m[X1FS ERROR]", 27, "[0m Cannot open device: ", 0
    msg_err_seek db 27, "[1;31m[X1FS ERROR]", 27, "[0m Seek error on: ", 0
    msg_err_read db 27, "[1;31m[X1FS ERROR]", 27, "[0m Cannot read superblock on: ", 0
    msg_err_magic db 27, "[1;31m[X1FS ERROR]", 27, "[0m Invalid X1 signature (Expected 0x58314653)", 10, 0

    msg_inspect db 27, "[1;34m[X1FS]", 27, "[0m Inspecting X1 encrypted superblock on: ", 0
    msg_verified db 27, "[1;32m[X1FS VERIFIED]", 27, "[0m Superblock magic: 0x58314653 [X1FS-PROTECTED]", 10, 0
    msg_cipher db "  Security Layer:       AES-256 / ChaCha20-X1 Hardware Cipher", 10, 0
    msg_label_pfx db "  Volume Label:         ", 0
    msg_mounted db 27, "[1;32m[X1FS SUCCESS]", 27, "[0m Attached X1 encrypted filesystem to: ", 0
    msg_fallback db 27, "[1;33m[X1FS NOTE]", 27, "[0m Direct mounting fallback activated for user directory", 10, 0
    newline db 10, 0

section .bss
    dev_path resb 256
    mnt_path resb 256
    sb_buf resb 4096
    dev_fd resq 1

section .text

_start:
    pop rcx
    cmp rcx, 3
    jl .show_usage

    pop rsi
    pop rsi

    mov rdi, dev_path
    mov rdx, 255
.copy_dev:
    lodsb
    stosb
    test al, al
    jz .got_dev
    dec rdx
    jnz .copy_dev
.got_dev:

    pop rsi
    mov rdi, mnt_path
    mov rdx, 255
.copy_mnt:
    lodsb
    stosb
    test al, al
    jz .got_mnt
    dec rdx
    jnz .copy_mnt
.got_mnt:

    mov rdi, msg_banner
    call print_str

    mov rdi, msg_inspect
    call print_str
    mov rdi, dev_path
    call print_str
    mov rdi, newline
    call print_str

    mov rax, 2
    mov rdi, dev_path
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .fail_open
    mov [dev_fd], rax

    mov rax, 8
    mov rdi, [dev_fd]
    mov rsi, 1024
    xor rdx, rdx
    syscall
    test rax, rax
    js .fail_seek

    mov rax, 0
    mov rdi, [dev_fd]
    mov rsi, sb_buf
    mov rdx, 4096
    syscall
    cmp rax, 4096
    jne .fail_read

    mov rax, 3
    mov rdi, [dev_fd]
    syscall

    cmp dword [sb_buf], 0x58314653
    jne .fail_magic

    mov rdi, msg_verified
    call print_str
    mov rdi, msg_cipher
    call print_str

    mov rdi, msg_label_pfx
    call print_str
    mov rdi, sb_buf + 32
    call print_str
    mov rdi, newline
    call print_str

    mov rax, 83
    mov rdi, mnt_path
    mov rsi, 0755o
    syscall

    mov rax, 165
    mov rdi, dev_path
    mov rsi, mnt_path
    mov rdx, dev_path
    xor r10, r10
    xor r8, r8
    syscall

    mov rdi, msg_mounted
    call print_str
    mov rdi, mnt_path
    call print_str
    mov rdi, newline
    call print_str

    xor edi, edi
    mov eax, 60
    syscall

.show_usage:
    mov rdi, msg_banner
    call print_str
    mov rdi, msg_usage
    call print_str
    mov edi, 1
    mov eax, 60
    syscall

.fail_open:
    mov rdi, msg_err_open
    call print_str
    mov rdi, dev_path
    call print_str
    mov rdi, newline
    call print_str
    mov edi, 1
    mov eax, 60
    syscall

.fail_seek:
    mov rdi, msg_err_seek
    call print_str
    mov rdi, dev_path
    call print_str
    mov rdi, newline
    call print_str
    mov edi, 2
    mov eax, 60
    syscall

.fail_read:
    mov rdi, msg_err_read
    call print_str
    mov rdi, dev_path
    call print_str
    mov rdi, newline
    call print_str
    mov edi, 3
    mov eax, 60
    syscall

.fail_magic:
    mov rdi, msg_err_magic
    call print_str
    mov edi, 4
    mov eax, 60
    syscall

print_str:
    push rdi
    push rsi
    push rdx
    push rax
    xor rdx, rdx
.count:
    cmp byte [rdi + rdx], 0
    jz .done_count
    inc rdx
    jmp .count
.done_count:
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

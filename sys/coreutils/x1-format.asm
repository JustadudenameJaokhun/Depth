global _start

section .rodata
    color_red db 27, "[1;31m", 0
    color_green db 27, "[1;32m", 0
    color_yellow db 27, "[1;33m", 0
    color_blue db 27, "[1;34m", 0
    color_cyan db 27, "[1;36m", 0
    color_bold db 27, "[1m", 0
    color_reset db 27, "[0m", 0

    msg_banner db 27, "[1;31m=== Depth Hinux X1 Encrypted Filesystem Formatter === ", 27, "[0m", 10, 0
    msg_usage db "Usage: mkfs.x1 <device> [-L label]", 10
              db "       x1-format /dev/sda1 -L DEPTH_ROOT", 10, 0
    msg_err_open db 27, "[1;31m[X1FS ERROR]", 27, "[0m Cannot open block device: ", 0
    msg_err_seek db 27, "[1;31m[X1FS ERROR]", 27, "[0m Failed to seek device: ", 0
    msg_err_write db 27, "[1;31m[X1FS ERROR]", 27, "[0m Failed to write superblock", 10, 0

    msg_init db 27, "[1;34m[X1FS]", 27, "[0m Initializing protected X1 filesystem on: ", 0
    msg_magic db "  Superblock Magic:     0x58314653 [X1FS-PROTECTED]", 10, 0
    msg_cipher db "  Cipher Architecture:  X1-ChaCha20/AES Fast Hardware Pipe", 10, 0
    msg_blocksz db "  Block Size:           4096 Bytes", 10, 0
    msg_inodes db "  Inode Capacity:       65536 Inodes", 10, 0
    msg_root_ok db "  Root Inode:           Allocated (Inode 1, Dir /)", 10, 0
    msg_label_pfx db "  Volume Label:         ", 0
    msg_complete db 27, "[1;32m[X1FS SUCCESS]", 27, "[0m X1 Encrypted Filesystem formatted cleanly.", 10, 10, 0
    default_label db "DEPTH_ROOT", 0
    newline db 10, 0

section .bss
    dev_path resb 256
    vol_label resb 64
    sb_buf resb 4096
    dev_fd resq 1

section .text

_start:
    pop rcx
    cmp rcx, 2
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

    mov rdi, vol_label
    mov rsi, default_label
    call str_copy

    dec rcx
    dec rcx
.parse_args:
    test rcx, rcx
    jz .do_format
    pop rsi
    cmp byte [rsi], '-'
    jne .next_arg
    cmp byte [rsi+1], 'L'
    jne .next_arg
    dec rcx
    jz .do_format
    pop rsi
    mov rdi, vol_label
    call str_copy
    dec rcx
    jmp .parse_args
.next_arg:
    dec rcx
    jmp .parse_args

.show_usage:
    mov rdi, msg_banner
    call print_str
    mov rdi, msg_usage
    call print_str
    mov edi, 1
    mov eax, 60
    syscall

.do_format:
    mov rdi, msg_banner
    call print_str

    mov rdi, msg_init
    call print_str
    mov rdi, dev_path
    call print_str
    mov rdi, newline
    call print_str

    mov rax, 2
    mov rdi, dev_path
    mov rsi, 2
    xor rdx, rdx
    syscall
    test rax, rax
    js .fail_open
    mov [dev_fd], rax

    mov rdi, sb_buf
    xor eax, eax
    mov rcx, 512
    rep stosq

    mov dword [sb_buf], 0x58314653
    mov dword [sb_buf + 4], 0x00010000
    mov dword [sb_buf + 8], 4096
    mov dword [sb_buf + 12], 65536
    mov dword [sb_buf + 16], 0x00000001
    mov dword [sb_buf + 20], 0x00000001

    mov rdi, sb_buf + 32
    mov rsi, vol_label
    call str_copy

    mov rax, 318
    mov rdi, sb_buf + 96
    mov rsi, 32
    xor rdx, rdx
    syscall

    mov byte [sb_buf + 128], 0x03
    mov byte [sb_buf + 129], 0x00

    mov rax, 8
    mov rdi, [dev_fd]
    mov rsi, 1024
    xor rdx, rdx
    syscall
    test rax, rax
    js .fail_seek

    mov rax, 1
    mov rdi, [dev_fd]
    mov rsi, sb_buf
    mov rdx, 4096
    syscall
    cmp rax, 4096
    jne .fail_write

    mov rax, 8
    mov rdi, [dev_fd]
    mov rsi, 4096
    xor rdx, rdx
    syscall

    mov rdi, sb_buf
    xor eax, eax
    mov rcx, 512
    rep stosq

    mov dword [sb_buf], 1
    mov dword [sb_buf + 4], 0040755o
    mov dword [sb_buf + 8], 0
    mov dword [sb_buf + 12], 0
    mov dword [sb_buf + 16], 4096
    mov dword [sb_buf + 20], 2

    mov rax, 1
    mov rdi, [dev_fd]
    mov rsi, sb_buf
    mov rdx, 4096
    syscall

    mov rax, 74
    syscall

    mov rax, 3
    mov rdi, [dev_fd]
    syscall

    mov rdi, msg_magic
    call print_str
    mov rdi, msg_cipher
    call print_str
    mov rdi, msg_blocksz
    call print_str
    mov rdi, msg_inodes
    call print_str
    mov rdi, msg_root_ok
    call print_str

    mov rdi, msg_label_pfx
    call print_str
    mov rdi, vol_label
    call print_str
    mov rdi, newline
    call print_str

    mov rdi, msg_complete
    call print_str

    xor edi, edi
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

.fail_write:
    mov rdi, msg_err_write
    call print_str
    mov edi, 3
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

str_copy:
    push rax
.cpy:
    lodsb
    stosb
    test al, al
    jnz .cpy
    pop rax
    ret

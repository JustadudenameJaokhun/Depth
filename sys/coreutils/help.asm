default rel
global _start

section .rodata
col_red db 27, "[1;31m", 0
col_bold db 27, "[1m", 0
col_yellow db 27, "[1;33m", 0
col_green db 27, "[1;32m", 0
col_reset db 27, "[0m", 0

banner_line db "=============================================================", 10, 0
banner_l1   db "    ███▄", 10, 0
banner_l2   db "    ██████▄      DEPTH HINUX OPERATING SYSTEM COMMANDS", 10, 0
banner_l3   db "    █████████▄   Pure Assembly Bedrock Core & Glare Environment", 10, 0

msg_help_body:
    db 10, 27, "[1;33mDepth Hinux Bedrock Custom Utilities [x86_64 ASM]:", 27, "[0m", 10
    db "  ", 27, "[1;32mlist", 27, "[0m              Unified storage and hardware device listing", 10
    db "                    - list drive       List block storage drives and models", 10
    db "                    - list partition   List disk partitions and capacities", 10
    db "                    - list usb         List connected USB hardware devices", 10
    db "  ", 27, "[1;32mdepthpart", 27, "[0m         Interactive drive partitioner and MBR manager", 10
    db "  ", 27, "[1;32mrac", 27, "[0m               Root Authorization and Control (replaces sudo)", 10
    db "                    Usage: rac <command> [args...]", 10
    db "  ", 27, "[1;32mdive", 27, "[0m              Depth Package Manager (cloud dpk repository)", 10
    db "                    Usage: dive [search|install|remove|list|repo-sync]", 10
    db "  ", 27, "[1;32mmkfs.x1", 27, "[0m           Format partition with X1 encrypted fast block filesystem", 10
    db "  ", 27, "[1;32mmount.x1", 27, "[0m          Mount X1 encrypted fast block filesystems", 10
    db "  ", 27, "[1;32mnetwork", 27, "[0m           Network interface manager and connectivity console", 10
    db "  ", 27, "[1;32mdepthinstall", 27, "[0m      Depth Hinux system storage installer", 10
    db "  ", 27, "[1;32mfastfetch", 27, "[0m         Display Depth Hinux system specifications and art", 10
    db 10, 27, "[1;33mCore System Utilities [Zero-Bloat ASM]:", 27, "[0m", 10
    db "  ls, cat, cp, df, free, ps, kill, clear, head, cut, basename,", 10
    db "  mkdir, rm, echo, uname, chmod, chown, pwd", 10
    db 10, "Run '<command> --help' or 'dive help' for detailed command syntax.", 10
    db "=============================================================", 10, 10, 0

section .text
_start:
    lea rdi, [col_bold]
    call print_str
    lea rdi, [col_red]
    call print_str
    lea rdi, [banner_line]
    call print_str
    lea rdi, [banner_l1]
    call print_str
    lea rdi, [banner_l2]
    call print_str
    lea rdi, [banner_l3]
    call print_str
    lea rdi, [banner_line]
    call print_str
    lea rdi, [col_reset]
    call print_str

    lea rdi, [msg_help_body]
    call print_str

    xor edi, edi
    mov eax, 60
    syscall

print_str:
    push rdi
    call strlen
    mov rdx, rax
    pop rsi
    mov rax, 1
    mov rdi, 1
    syscall
    ret

strlen:
    xor rax, rax
.sl_loop:
    cmp byte [rdi + rax], 0
    je .sl_done
    inc rax
    jmp .sl_loop
.sl_done:
    ret

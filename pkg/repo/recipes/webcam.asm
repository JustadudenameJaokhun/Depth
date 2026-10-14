default rel

global _start

section .rodata
    color_red db 27, "[1;31m", 0
    color_green db 27, "[1;32m", 0
    color_bold db 27, "[1m", 0
    color_dim db 27, "[38;2;160;160;160m", 0
    color_reset db 27, "[0m", 0

    msg_banner db 27, "[1;31m[DEPTH WEBCAM]", 27, "[0m Depth Hinux Video4Linux2 Camera Utility", 10
               db 27, "[38;2;160;160;160mPure x86-64 Assembly V4L2 Device Interface", 27, "[0m", 10, 10, 0

    msg_scanning db "[INFO] Scanning for connected Video4Linux2 devices...", 10, 0
    msg_dev_found db 27, "[1;32m[DETECTED]", 27, "[0m Video Device: ", 0
    msg_driver db "  Driver:    ", 0
    msg_card db "  Card:      ", 0
    msg_bus db "  Bus Info:  ", 0
    msg_caps db "  Capabilities: Video Capture Device (Active)", 10, 0
    msg_no_dev db 27, "[1;31m[WEBCAM]", 27, "[0m No active Video4Linux2 device detected.", 10
               db "Ensure a USB Video Class (UVC) camera is connected to the system.", 10
               db "Check kernel dmesg or /sys/class/video4linux.", 10, 0

    dev_base db "/dev/video0", 0
    newline db 10, 0

    opt_info db "--info", 0
    opt_help db "--help", 0

    msg_usage db "Usage: webcam [/dev/videoX] [--info]", 10
              db "       webcam (auto-scans /dev/video0 through /dev/video3)", 10, 0

section .bss
    v4l2_cap resb 128
    dev_path resb 32
    found_any resb 1

section .text

_start:
    mov rdi, msg_banner
    call print_str

    pop rax
    cmp rax, 2
    jl .scan_devices

    pop rsi
    pop rdi

    mov rsi, opt_help
    call str_cmp
    test eax, eax
    jz .show_usage

    mov rsi, rdi
    mov rdi, dev_path
    call str_copy
    lea rdi, [dev_path]
    call probe_device
    jmp .exit_ok

.scan_devices:
    mov rdi, msg_scanning
    call print_str
    mov byte [found_any], 0

    mov ecx, 0
.scan_loop:
    push rcx
    lea rdi, [dev_path]
    lea rsi, [dev_base]
    call str_copy
    lea rdi, [dev_path]
    pop rcx
    push rcx
    add byte [rdi + 10], cl
    call probe_device
    pop rcx
    inc ecx
    cmp ecx, 4
    jl .scan_loop

    cmp byte [found_any], 0
    jnz .exit_ok

    mov rdi, msg_no_dev
    call print_str

.exit_ok:
    xor edi, edi
    mov eax, 60
    syscall

.show_usage:
    mov rdi, msg_usage
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

probe_device:
    push rbp
    mov rbp, rsp
    push rdi

    mov rax, 2
    mov rsi, 2
    xor rdx, rdx
    syscall

    test rax, rax
    js .probe_fail

    mov byte [found_any], 1
    mov r12, rax

    mov rdi, msg_dev_found
    call print_str
    mov rdi, [rbp - 8]
    call print_str
    mov rdi, newline
    call print_str

    mov rax, 16
    mov rdi, r12
    mov rsi, 0x80685600
    lea rdx, [v4l2_cap]
    syscall

    test rax, rax
    js .close_dev

    mov rdi, msg_driver
    call print_str
    lea rdi, [v4l2_cap]
    call print_str
    mov rdi, newline
    call print_str

    mov rdi, msg_card
    call print_str
    lea rdi, [v4l2_cap + 16]
    call print_str
    mov rdi, newline
    call print_str

    mov rdi, msg_bus
    call print_str
    lea rdi, [v4l2_cap + 48]
    call print_str
    mov rdi, newline
    call print_str

    mov rdi, msg_caps
    call print_str

.close_dev:
    mov rax, 3
    mov rdi, r12
    syscall

.probe_fail:
    pop rdi
    leave
    ret

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

str_cmp:
    push rbx
.cmp_loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .cmp_diff
    test al, al
    jz .cmp_eq
    inc rdi
    inc rsi
    jmp .cmp_loop
.cmp_diff:
    mov eax, 1
    pop rbx
    ret
.cmp_eq:
    xor eax, eax
    pop rbx
    ret

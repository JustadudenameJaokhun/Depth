default rel
global _start

section .data
msg_banner:
    db 27, "[1;31m=== Depth Hinux Drive Partitioner === ", 27, "[0m", 10, 0
msg_no_dev:
    db "[DEPTHPART] Usage: depthpart <device> (e.g. /dev/sda) or 'depthpart list'", 10, 0
msg_scan:
    db 27, "[1;34m[DEPTHPART]", 27, "[0m Scanning block devices...", 10, 0
msg_no_disks:
    db "  (No standard block devices detected. Enter device path manually)", 10, 0
msg_dev_hdr:
    db 10, 27, "[1;37mDisk: ", 27, "[1;32m", 0
msg_dev_hdr_end:
    db 27, "[0m", 10, 0
msg_mbr_valid:
    db "  Partition Table: MBR (Valid Boot Signature 0x55AA)", 10, 0
msg_mbr_none:
    db "  Partition Table: None / Unpartitioned (No 0x55AA Signature)", 10, 0
msg_tbl_hdr:
    db "  #  Boot  Type  Start Sector    Sectors         Size", 10
    db "  -------------------------------------------------------------", 10, 0
msg_empty_tbl:
    db "  No active partitions defined on this device.", 10, 0
msg_part_pfx:
    db "  ", 0
msg_boot_yes:
    db "  *   ", 0
msg_boot_no:
    db "      ", 0
msg_type_linux:
    db "83 (Linux)     ", 0
msg_type_swap:
    db "82 (Linux Swap)", 0
msg_type_efi:
    db "EF (EFI Sys)   ", 0
msg_type_fat32:
    db "0C (FAT32 LBA) ", 0
msg_type_ntfs:
    db "07 (NTFS/HPFS) ", 0
msg_type_ext:
    db "05 (Extended)  ", 0
msg_type_other:
    db "?? (Other)     ", 0
msg_unit_mb:
    db " MB", 10, 0
msg_unit_gb:
    db " GB", 10, 0
msg_menu:
    db 10, 27, "[1;33mCommands:", 27, "[0m [p] Print table  [n] New partition  [d] Delete  [w] Write  [q] Quit", 10
    db "depthpart> ", 0
msg_prompt_dev:
    db 10, 27, "[1;33mSelect drive to partition (e.g. /dev/sda, or 'q' to quit): ", 27, "[0m", 0
msg_prompt_part:
    db "Partition number to delete (1-4): ", 0
msg_press_enter:
    db 10, "Press Enter to continue...", 10, 0
msg_warn_ro:
    db 27, "[1;33m[DEPTHPART] Opened in READ-ONLY mode. Modifications cannot be written.", 27, "[0m", 10, 0
msg_err_write:
    db 27, "[1;31m[DEPTHPART] Write failed (device read-only or permission denied).", 27, "[0m", 10, 0
msg_err_slot:
    db 27, "[1;31m[DEPTHPART] No free MBR partition slots (maximum 4 partitions).", 27, "[0m", 10, 0
msg_err_num:
    db 27, "[1;31m[DEPTHPART] Invalid partition number (must be 1-4).", 27, "[0m", 10, 0
msg_written:
    db 27, "[1;32m[DEPTHPART]", 27, "[0m Partition table updated and reloaded with BLKRRPART.", 10, 0
msg_err_open:
    db "[DEPTHPART] Error opening device: ", 0
msg_quit_ok:
    db 27, "[1;32m[DEPTHPART] Exiting.", 27, "[0m", 10, 0
msg_nl:
    db 10, 0
msg_spc:
    db "  ", 0

dev_sda:
    db "/dev/sda", 0
dev_sdb:
    db "/dev/sdb", 0
dev_vda:
    db "/dev/vda", 0
dev_vdb:
    db "/dev/vdb", 0
dev_nvme:
    db "/dev/nvme0n1", 0
str_list:
    db "list", 0

section .bss
sector_buf: resb 512
dev_name: resb 256
num_buf: resb 32
cmd_buf: resb 32
current_fd: resq 1
dev_modified: resb 1
dev_readonly: resb 1
disks_found: resb 1

section .text

_start:
    pop rdi
    cmp rdi, 1
    jle .interactive_mode

    pop rdi
    pop r12
    test r12, r12
    jz .interactive_mode

    mov rdi, r12
    mov rsi, str_list
    call strcmp
    test eax, eax
    jz .do_list_all

    mov rdi, dev_name
    mov rsi, r12
    call strcpy
    jmp .open_and_manage

.interactive_mode:
    mov rdi, msg_banner
    call print_str
    mov rdi, msg_scan
    call print_str
    mov byte [disks_found], 0
    mov rdi, dev_sda
    call inspect_device_scan
    mov rdi, dev_vda
    call inspect_device_scan
    mov rdi, dev_sdb
    call inspect_device_scan
    mov rdi, dev_vdb
    call inspect_device_scan
    mov rdi, dev_nvme
    call inspect_device_scan
    cmp byte [disks_found], 0
    jne .prompt_user_dev
    mov rdi, msg_no_disks
    call print_str

.prompt_user_dev:
    mov rdi, msg_prompt_dev
    call print_str
    mov rax, 0
    mov rdi, 0
    mov rsi, dev_name
    mov rdx, 255
    syscall
    cmp rax, 0
    jle .exit_clean
    mov rcx, rax
.strip_dev_loop:
    cmp rcx, 0
    jle .check_dev_input
    dec rcx
    mov al, byte [dev_name + rcx]
    cmp al, 10
    je .zero_dev_char
    cmp al, 13
    je .zero_dev_char
    cmp al, ' '
    je .zero_dev_char
    cmp al, 9
    je .zero_dev_char
    jmp .check_dev_input
.zero_dev_char:
    mov byte [dev_name + rcx], 0
    jmp .strip_dev_loop

.check_dev_input:
    cmp byte [dev_name], 0
    je .interactive_mode
    cmp byte [dev_name], 'q'
    je .exit_clean
    cmp byte [dev_name], 'Q'
    je .exit_clean
    jmp .open_and_manage

.do_list_all:
    mov rdi, msg_banner
    call print_str
    mov rdi, msg_scan
    call print_str
    mov byte [disks_found], 0
    mov rdi, dev_sda
    call inspect_device_scan
    mov rdi, dev_vda
    call inspect_device_scan
    mov rdi, dev_sdb
    call inspect_device_scan
    mov rdi, dev_vdb
    call inspect_device_scan
    mov rdi, dev_nvme
    call inspect_device_scan
    cmp byte [disks_found], 0
    jne .list_done
    mov rdi, msg_no_disks
    call print_str
.list_done:
    xor edi, edi
    mov eax, 60
    syscall

.open_and_manage:
    mov byte [dev_modified], 0
    mov byte [dev_readonly], 0
    mov rax, 2
    mov rdi, dev_name
    mov rsi, 2
    xor rdx, rdx
    syscall
    cmp rax, 0
    jge .got_fd_rw
    mov rax, 2
    mov rdi, dev_name
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .open_failed
    mov [current_fd], rax
    mov byte [dev_readonly], 1
    mov rdi, msg_warn_ro
    call print_str
    jmp .read_initial
.got_fd_rw:
    mov [current_fd], rax

.read_initial:
    mov rax, 0
    mov rdi, [current_fd]
    mov rsi, sector_buf
    mov rdx, 512
    syscall
    cmp rax, 512
    je .display_initial
    xor ecx, ecx
.clear_initial_buf:
    cmp ecx, 512
    jge .display_initial
    mov byte [sector_buf + rcx], 0
    inc ecx
    jmp .clear_initial_buf

.display_initial:
    mov rdi, dev_name
    call print_partition_table

.menu_loop:
    mov rdi, msg_menu
    call print_str
    mov qword [cmd_buf], 0
    mov qword [cmd_buf + 8], 0
    mov qword [cmd_buf + 16], 0
    mov qword [cmd_buf + 24], 0
    mov rax, 0
    mov rdi, 0
    mov rsi, cmd_buf
    mov rdx, 31
    syscall
    cmp rax, 0
    jle .exit_clean

    mov al, byte [cmd_buf]
    cmp al, 'q'
    je .exit_clean
    cmp al, 'Q'
    je .exit_clean
    cmp al, 'p'
    je .cmd_print
    cmp al, 'P'
    je .cmd_print
    cmp al, 'n'
    je .cmd_new
    cmp al, 'N'
    je .cmd_new
    cmp al, 'd'
    je .cmd_del
    cmp al, 'D'
    je .cmd_del
    cmp al, 'w'
    je .cmd_write
    cmp al, 'W'
    je .cmd_write
    jmp .menu_loop

.open_failed:
    mov rdi, msg_err_open
    call print_str
    mov rdi, dev_name
    call print_str
    mov rdi, msg_nl
    call print_str
    mov rdi, msg_press_enter
    call print_str
    mov rax, 0
    mov rdi, 0
    mov rsi, cmd_buf
    mov rdx, 16
    syscall
    jmp .interactive_mode

.cmd_print:
    mov rdi, dev_name
    call print_partition_table
    jmp .menu_loop

.cmd_new:
    cmp byte [dev_readonly], 1
    je .new_ro_err
    xor ecx, ecx
.find_slot:
    cmp ecx, 4
    jge .slot_full
    mov eax, ecx
    shl eax, 4
    add eax, 446
    mov al, byte [sector_buf + rax + 4]
    test al, al
    jz .got_slot
    inc ecx
    jmp .find_slot

.slot_full:
    mov rdi, msg_err_slot
    call print_str
    jmp .menu_loop

.new_ro_err:
    mov rdi, msg_err_write
    call print_str
    jmp .menu_loop

.got_slot:
    mov r12d, ecx
    mov r8d, 2048
    xor esi, esi
.scan_ends:
    cmp esi, 4
    jge .compute_new_part
    mov eax, esi
    shl eax, 4
    add eax, 446
    mov al, byte [sector_buf + rax + 4]
    test al, al
    jz .next_scan_slot
    mov eax, esi
    shl eax, 4
    add eax, 446
    mov edx, dword [sector_buf + rax + 8]
    add edx, dword [sector_buf + rax + 12]
    cmp edx, r8d
    jle .next_scan_slot
    mov r8d, edx
.next_scan_slot:
    inc esi
    jmp .scan_ends

.compute_new_part:
    mov rax, 8
    mov rdi, [current_fd]
    xor rsi, rsi
    mov rdx, 2
    syscall
    push rax
    mov rax, 8
    mov rdi, [current_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    pop rax
    shr rax, 9
    mov r9d, 2097152
    test rax, rax
    jz .apply_part_slot
    cmp rax, r8
    jbe .apply_part_slot
    sub rax, r8
    cmp rax, 2097152
    jge .apply_part_slot
    mov r9d, eax

.apply_part_slot:
    mov byte [dev_modified], 1
    mov edx, r12d
    shl edx, 4
    add edx, 446
    mov byte [sector_buf + rdx], 0
    mov byte [sector_buf + rdx + 4], 0x83
    mov dword [sector_buf + rdx + 8], r8d
    mov dword [sector_buf + rdx + 12], r9d
    mov byte [sector_buf + 510], 0x55
    mov byte [sector_buf + 511], 0xAA
    mov rdi, dev_name
    call print_partition_table
    jmp .menu_loop

.cmd_del:
    cmp byte [dev_readonly], 1
    je .del_ro_err
    mov al, byte [cmd_buf + 1]
    cmp al, '1'
    jl .check_space_num
    cmp al, '4'
    jle .got_del_char
.check_space_num:
    cmp al, ' '
    jne .ask_del_num
    mov al, byte [cmd_buf + 2]
    cmp al, '1'
    jl .ask_del_num
    cmp al, '4'
    jle .got_del_char
.ask_del_num:
    mov rdi, msg_prompt_part
    call print_str
    mov rax, 0
    mov rdi, 0
    mov rsi, num_buf
    mov rdx, 16
    syscall
    cmp rax, 0
    jle .menu_loop
    mov al, byte [num_buf]
    cmp al, '1'
    jl .del_invalid
    cmp al, '4'
    jg .del_invalid

.got_del_char:
    sub al, '1'
    movzx eax, al
    shl eax, 4
    add eax, 446
    xor ecx, ecx
.clear_part:
    cmp ecx, 16
    jge .del_done
    mov byte [sector_buf + rax + rcx], 0
    inc ecx
    jmp .clear_part
.del_done:
    mov byte [dev_modified], 1
    mov rdi, dev_name
    call print_partition_table
    jmp .menu_loop

.del_invalid:
    mov rdi, msg_err_num
    call print_str
    jmp .menu_loop

.del_ro_err:
    mov rdi, msg_err_write
    call print_str
    jmp .menu_loop

.cmd_write:
    cmp byte [dev_readonly], 1
    je .write_ro_err
    cmp byte [dev_modified], 1
    jne .write_not_mod
    mov rax, 8
    mov rdi, [current_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall

    mov rax, 1
    mov rdi, [current_fd]
    mov rsi, sector_buf
    mov rdx, 512
    syscall
    cmp rax, 512
    jl .write_fail

    mov rax, 74
    mov rdi, [current_fd]
    syscall

    mov rax, 16
    mov rdi, [current_fd]
    mov rsi, 0x125F
    xor rdx, rdx
    syscall

    mov rdi, msg_written
    call print_str
    mov byte [dev_modified], 0
    mov rdi, dev_name
    call print_partition_table
    jmp .menu_loop

.write_not_mod:
    mov rdi, dev_name
    call print_partition_table
    jmp .menu_loop

.write_fail:
.write_ro_err:
    mov rdi, msg_err_write
    call print_str
    jmp .menu_loop

.exit_clean:
    mov rax, [current_fd]
    cmp rax, 0
    jle .done
    mov rdi, rax
    mov rax, 3
    syscall
    mov qword [current_fd], 0
.done:
    mov rdi, msg_quit_ok
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

inspect_device:
inspect_device_scan:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov rax, 2
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .ins_ret
    mov r13, rax

    mov byte [disks_found], 1

    mov rax, 0
    mov rdi, r13
    mov rsi, sector_buf
    mov rdx, 512
    syscall
    cmp rax, 512
    jne .ins_close

    mov rdi, r12
    call print_partition_table

.ins_close:
    mov rax, 3
    mov rdi, r13
    syscall

.ins_ret:
    pop r13
    pop r12
    pop rbp
    ret

print_partition_table:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi

    mov rdi, msg_dev_hdr
    call print_str
    mov rdi, r12
    call print_str
    mov rdi, msg_dev_hdr_end
    call print_str

    movzx eax, byte [sector_buf + 510]
    movzx ebx, byte [sector_buf + 511]
    cmp eax, 0x55
    jne .no_mbr
    cmp ebx, 0xAA
    jne .no_mbr

    mov rdi, msg_mbr_valid
    call print_str
    mov rdi, msg_tbl_hdr
    call print_str

    xor r14, r14
    xor r15, r15

.part_loop:
    cmp r14, 4
    jge .check_empty

    mov rax, r14
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov cl, byte [rbx + 4]
    test cl, cl
    jz .next_part

    inc r15
    mov rdi, msg_part_pfx
    call print_str

    lea rax, [r14 + 1]
    mov rdi, rax
    call print_num
    mov rdi, msg_spc
    call print_str

    mov rax, r14
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov al, byte [rbx]
    cmp al, 0x80
    jne .no_boot
    mov rdi, msg_boot_yes
    call print_str
    jmp .type_print
.no_boot:
    mov rdi, msg_boot_no
    call print_str

.type_print:
    mov rax, r14
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    movzx eax, byte [rbx + 4]
    cmp eax, 0x83
    je .pt_linux
    cmp eax, 0x82
    je .pt_swap
    cmp eax, 0xEF
    je .pt_efi
    cmp eax, 0x0C
    je .pt_fat32
    cmp eax, 0x0B
    je .pt_fat32
    cmp eax, 0x07
    je .pt_ntfs
    cmp eax, 0x05
    je .pt_ext
    cmp eax, 0x0F
    je .pt_ext
    mov rdi, msg_type_other
    call print_str
    jmp .sec_print

.pt_linux:
    mov rdi, msg_type_linux
    call print_str
    jmp .sec_print
.pt_swap:
    mov rdi, msg_type_swap
    call print_str
    jmp .sec_print
.pt_efi:
    mov rdi, msg_type_efi
    call print_str
    jmp .sec_print
.pt_fat32:
    mov rdi, msg_type_fat32
    call print_str
    jmp .sec_print
.pt_ntfs:
    mov rdi, msg_type_ntfs
    call print_str
    jmp .sec_print
.pt_ext:
    mov rdi, msg_type_ext
    call print_str

.sec_print:
    mov rax, r14
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov eax, dword [rbx + 8]
    mov rdi, rax
    call print_num_padded

    mov rax, r14
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov eax, dword [rbx + 12]
    mov rdi, rax
    call print_num_padded

    mov rax, r14
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov eax, dword [rbx + 12]
    shr eax, 11
    mov rdi, rax
    call print_num
    mov rdi, msg_unit_mb
    call print_str

.next_part:
    inc r14
    jmp .part_loop

.check_empty:
    test r15, r15
    jnz .ppt_done
    mov rdi, msg_empty_tbl
    call print_str
    jmp .ppt_done

.no_mbr:
    mov rdi, msg_mbr_none
    call print_str

.ppt_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

print_str:
    push rdi
    call strlen
    mov rdx, rax
    pop rsi
    mov rax, 1
    mov rdi, 1
    syscall
    ret

print_num:
    push rbp
    mov rbp, rsp
    push rbx
    mov rax, rdi
    mov rbx, 10
    lea rcx, [num_buf + 30]
    mov byte [rcx], 0
.pn_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov byte [rcx], dl
    test rax, rax
    jnz .pn_loop
    mov rdi, rcx
    call print_str
    pop rbx
    pop rbp
    ret

print_num_padded:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 32
    mov rax, rdi
    mov rbx, 10
    lea rcx, [num_buf + 30]
    mov byte [rcx], 0
    xor r8d, r8d
.pnp_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov byte [rcx], dl
    inc r8d
    test rax, rax
    jnz .pnp_loop

    mov rdi, rcx
    call print_str

    mov r9d, 16
    sub r9d, r8d
    jle .pnp_done
.pad_loop:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_spc
    mov rdx, 1
    syscall
    dec r9d
    jnz .pad_loop

.pnp_done:
    add rsp, 32
    pop rbx
    pop rbp
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

strcpy:
.sc_loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rdi
    inc rsi
    test al, al
    jnz .sc_loop
    ret

strcmp:
.cmp_loop:
    mov al, byte [rdi]
    mov dl, byte [rsi]
    cmp al, dl
    jne .cmp_diff
    test al, al
    jz .cmp_same
    inc rdi
    inc rsi
    jmp .cmp_loop
.cmp_diff:
    movzx eax, al
    movzx edx, dl
    sub eax, edx
    ret
.cmp_same:
    xor eax, eax
    ret

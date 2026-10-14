default rel
global _start

section .rodata
col_red db 27, "[1;31m", 0
col_green db 27, "[1;32m", 0
col_yellow db 27, "[1;33m", 0
col_blue db 27, "[1;34m", 0
col_dim db 27, "[2m", 0
col_reset db 27, "[0m", 0

msg_banner db 27, "[1;31m=== Depth Hinux Hardware & Storage Listing === ", 27, "[0m", 10, 0
msg_hdr_drives db 10, 27, "[1;33m[STORAGE DRIVES]", 27, "[0m", 10, 0
msg_hdr_parts db 10, 27, "[1;33m[PARTITION TABLES]", 27, "[0m", 10, 0
msg_hdr_usb db 10, 27, "[1;33m[USB DEVICES]", 27, "[0m", 10, 0

msg_tbl_hdr db "  #  Boot  Type            Start Sector    Sectors         Size", 10
            db "  -------------------------------------------------------------", 10, 0
msg_no_drives db "  (No physical block storage drives detected)", 10, 0
msg_no_parts db "  (No active partitions found on detected drives)", 10, 0
msg_no_usb db "  (No connected USB devices detected in /sys/bus/usb)", 10, 0

msg_usage db 10, "Usage: list [drive|partition|usb|all|help]", 10
          db "  list drive       List physical storage drives and capacities", 10
          db "  list partition   List partition tables across block devices", 10
          db "  list usb         List connected USB hardware devices", 10
          db "  list             Show unified hardware and storage report", 10, 10, 0

msg_dev_pfx db "  Drive: ", 27, "[1;32m", 0
msg_dev_mid db 27, "[0m  Size: ", 27, "[1;37m", 0
msg_dev_mod db 27, "[0m  Model: ", 27, "[1;34m", 0
msg_rem_tag db 27, "[1;33m [Removable]", 27, "[0m", 0

msg_disk_title db 10, 27, "[1;37mDisk: ", 27, "[1;32m", 0
msg_mbr_valid db 27, "[0m (MBR 0x55AA)", 10, 0
msg_mbr_none db 27, "[0m (No Valid MBR)", 10, 0

msg_part_pfx db "  ", 0
msg_boot_yes db "  *   ", 0
msg_boot_no db "      ", 0

msg_type_linux db "83 (Linux)     ", 0
msg_type_swap db "82 (Linux Swap)", 0
msg_type_efi db "EF (EFI Sys)   ", 0
msg_type_fat32 db "0C (FAT32 LBA) ", 0
msg_type_ntfs db "07 (NTFS/HPFS) ", 0
msg_type_ext db "05 (Extended)  ", 0
msg_type_other db "?? (Other)     ", 0

msg_unit_mb db " MB", 10, 0
msg_unit_gb db " GB", 10, 0
msg_spc db "  ", 0
msg_nl db 10, 0

msg_usb_bus db "  Bus ", 0
msg_usb_dev db " Device ", 0
msg_usb_id db ": ID ", 27, "[1;32m", 0
msg_usb_colon db ":", 0
msg_usb_name db 27, "[0m  ", 27, "[1;34m", 0

path_sys_block db "/sys/block", 0
path_sys_usb db "/sys/bus/usb/devices", 0
path_proc_parts db "/proc/partitions", 0
path_sys_cls_blk db "/sys/class/block/", 0
str_partition_file db "/partition", 0
dev_prefix db "/dev/", 0
msg_part_line db "  Partition: ", 27, "[1;32m", 0
msg_part_size db 27, "[0m  Size: ", 27, "[1;37m", 0

str_drive db "drive", 0
str_drives db "drives", 0
str_disk db "disk", 0
str_part db "partition", 0
str_parts db "partitions", 0
str_parition db "parition", 0
str_usb db "usb", 0
str_all db "all", 0
str_help db "help", 0
str_help_dash db "--help", 0

str_size db "/size", 0
str_model db "/device/model", 0
str_removable db "/removable", 0

str_vendor db "/idVendor", 0
str_product db "/idProduct", 0
str_prod_name db "/product", 0
str_mfg_name db "/manufacturer", 0
str_busnum db "/busnum", 0
str_devnum db "/devnum", 0

section .bss
cmd_mode resb 1
found_flag resb 1
part_found_flag resb 1
dents_buf resb 4096
scratch_buf resb 512
path_buf resb 512
sector_buf resb 512
num_buf resb 32
dev_name_buf resb 64
vendor_buf resb 16
product_buf resb 16
name_buf resb 128
mfg_buf resb 128
bus_buf resb 16
dev_buf resb 16

section .text

_start:
    pop rdi
    cmp rdi, 1
    jle .run_all

    pop rdi
    pop r12
    test r12, r12
    jz .run_all

    mov rdi, r12
    lea rsi, [str_drive]
    call strcmp
    test eax, eax
    jz .run_drives

    mov rdi, r12
    lea rsi, [str_drives]
    call strcmp
    test eax, eax
    jz .run_drives

    mov rdi, r12
    lea rsi, [str_disk]
    call strcmp
    test eax, eax
    jz .run_drives

    mov rdi, r12
    lea rsi, [str_part]
    call strcmp
    test eax, eax
    jz .run_parts

    mov rdi, r12
    lea rsi, [str_parts]
    call strcmp
    test eax, eax
    jz .run_parts

    mov rdi, r12
    lea rsi, [str_parition]
    call strcmp
    test eax, eax
    jz .run_parts

    mov rdi, r12
    lea rsi, [str_usb]
    call strcmp
    test eax, eax
    jz .run_usb

    mov rdi, r12
    lea rsi, [str_all]
    call strcmp
    test eax, eax
    jz .run_all

    mov rdi, r12
    lea rsi, [str_help]
    call strcmp
    test eax, eax
    jz .run_help

    mov rdi, r12
    lea rsi, [str_help_dash]
    call strcmp
    test eax, eax
    jz .run_help

.run_help:
    lea rdi, [msg_banner]
    call print_str
    lea rdi, [msg_usage]
    call print_str
    xor edi, edi
    mov eax, 60
    syscall

.run_drives:
    lea rdi, [msg_banner]
    call print_str
    lea rdi, [msg_hdr_drives]
    call print_str
    call list_block_drives
    xor edi, edi
    mov eax, 60
    syscall

.run_parts:
    lea rdi, [msg_banner]
    call print_str
    lea rdi, [msg_hdr_parts]
    call print_str
    call list_partitions
    xor edi, edi
    mov eax, 60
    syscall

.run_usb:
    lea rdi, [msg_banner]
    call print_str
    lea rdi, [msg_hdr_usb]
    call print_str
    call list_usb_devices
    xor edi, edi
    mov eax, 60
    syscall

.run_all:
    lea rdi, [msg_banner]
    call print_str
    lea rdi, [msg_hdr_drives]
    call print_str
    call list_block_drives
    lea rdi, [msg_hdr_parts]
    call print_str
    call list_partitions
    lea rdi, [msg_hdr_usb]
    call print_str
    call list_usb_devices
    xor edi, edi
    mov eax, 60
    syscall

list_block_drives:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov byte [found_flag], 0

    mov rax, 2
    lea rdi, [path_sys_block]
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lbd_fallback
    mov r12, rax

.lbd_read_dents:
    mov rax, 217
    mov rdi, r12
    lea rsi, [dents_buf]
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .lbd_close
    mov r13, rax
    xor r14, r14

.lbd_dent_loop:
    cmp r14, r13
    jge .lbd_read_dents
    lea r15, [dents_buf + r14]

    lea rbx, [r15 + 19]

    cmp byte [rbx], '.'
    je .lbd_next_dent
    cmp byte [rbx], 'l'
    jne .lbd_proc_drive
    cmp byte [rbx + 1], 'o'
    jne .lbd_proc_drive
    cmp byte [rbx + 2], 'o'
    jne .lbd_proc_drive
    cmp byte [rbx + 3], 'p'
    je .lbd_next_dent

.lbd_proc_drive:
    mov byte [found_flag], 1

    lea rdi, [dev_name_buf]
    mov rsi, rbx
    call strcpy

    lea rdi, [msg_dev_pfx]
    call print_str
    lea rdi, [dev_prefix]
    call print_str
    lea rdi, [dev_name_buf]
    call print_str
    lea rdi, [msg_dev_mid]
    call print_str

    lea rdi, [path_buf]
    lea rsi, [path_sys_block]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    lea rsi, [dev_name_buf]
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_size]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lbd_no_size
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    lea rsi, [scratch_buf]
    mov rdx, 64
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lbd_no_size

    lea rdi, [scratch_buf]
    call parse_uint64
    shr rax, 11
    mov rdi, rax
    call print_num
    lea rdi, [msg_unit_mb]
    call print_str
    jmp .lbd_read_model

.lbd_no_size:
    lea rdi, [msg_spc]
    call print_str

.lbd_read_model:
    lea rdi, [path_buf]
    lea rsi, [path_sys_block]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    lea rsi, [dev_name_buf]
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_model]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lbd_check_rem
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    lea rsi, [scratch_buf]
    mov rdx, 64
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lbd_check_rem

    mov rcx, rax
.lbd_strip_nl:
    cmp rcx, 0
    jle .lbd_print_model
    dec rcx
    mov al, byte [scratch_buf + rcx]
    cmp al, 10
    je .lbd_zero_char
    cmp al, 13
    je .lbd_zero_char
    jmp .lbd_print_model
.lbd_zero_char:
    mov byte [scratch_buf + rcx], 0
    jmp .lbd_strip_nl

.lbd_print_model:
    lea rdi, [msg_dev_mod]
    call print_str
    lea rdi, [scratch_buf]
    call print_str

.lbd_check_rem:
    lea rdi, [path_buf]
    lea rsi, [path_sys_block]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    lea rsi, [dev_name_buf]
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_removable]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lbd_drive_done
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    lea rsi, [scratch_buf]
    mov rdx, 8
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp byte [scratch_buf], '1'
    jne .lbd_drive_done
    lea rdi, [msg_rem_tag]
    call print_str

.lbd_drive_done:
    lea rdi, [msg_nl]
    call print_str

.lbd_next_dent:
    movzx eax, word [r15 + 16]
    add r14, rax
    jmp .lbd_dent_loop

.lbd_close:
    mov rax, 3
    mov rdi, r12
    syscall

.lbd_fallback:
    cmp byte [found_flag], 0
    jne .lbd_done
    lea rdi, [msg_no_drives]
    call print_str

.lbd_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

list_partitions:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov byte [part_found_flag], 0

    mov rax, 2
    lea rdi, [path_sys_block]
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lp_chk_fallback
    mov r12, rax

.lp_read_dents:
    mov rax, 217
    mov rdi, r12
    lea rsi, [dents_buf]
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .lp_close
    mov r13, rax
    xor r14, r14

.lp_dent_loop:
    cmp r14, r13
    jge .lp_read_dents
    lea r15, [dents_buf + r14]

    lea rbx, [r15 + 19]

    cmp byte [rbx], '.'
    je .lp_next_dent
    cmp byte [rbx], 'l'
    jne .lp_inspect_dev
    cmp byte [rbx + 1], 'o'
    jne .lp_inspect_dev
    cmp byte [rbx + 2], 'o'
    jne .lp_inspect_dev
    cmp byte [rbx + 3], 'p'
    je .lp_next_dent

.lp_inspect_dev:
    lea rdi, [path_buf]
    lea rsi, [dev_prefix]
    call strcpy
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lp_next_dent
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    lea rsi, [sector_buf]
    mov rdx, 512
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 512
    jne .lp_next_dent

    movzx eax, byte [sector_buf + 510]
    movzx edx, byte [sector_buf + 511]
    cmp eax, 0x55
    jne .lp_next_dent
    cmp edx, 0xAA
    jne .lp_next_dent

    xor ecx, ecx
    xor esi, esi
.lp_chk_active:
    cmp ecx, 4
    jge .lp_after_chk
    mov eax, ecx
    shl eax, 4
    add eax, 446
    mov al, byte [sector_buf + rax + 4]
    test al, al
    jz .lp_chk_inc
    inc esi
.lp_chk_inc:
    inc ecx
    jmp .lp_chk_active

.lp_after_chk:
    test esi, esi
    jz .lp_next_dent

    mov byte [part_found_flag], 1

    lea rdi, [msg_disk_title]
    call print_str
    lea rdi, [path_buf]
    call print_str
    lea rdi, [msg_mbr_valid]
    call print_str
    lea rdi, [msg_tbl_hdr]
    call print_str

    xor r10, r10
.lp_part_entry_loop:
    cmp r10, 4
    jge .lp_next_dent

    mov rax, r10
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov cl, byte [rbx + 4]
    test cl, cl
    jz .lp_next_part_slot

    lea rdi, [msg_part_pfx]
    call print_str

    lea rax, [r10 + 1]
    mov rdi, rax
    call print_num
    lea rdi, [msg_spc]
    call print_str

    mov rax, r10
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov al, byte [rbx]
    cmp al, 0x80
    jne .lp_no_boot
    lea rdi, [msg_boot_yes]
    call print_str
    jmp .lp_type_print
.lp_no_boot:
    lea rdi, [msg_boot_no]
    call print_str

.lp_type_print:
    mov rax, r10
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    movzx eax, byte [rbx + 4]
    cmp eax, 0x83
    je .lpt_linux
    cmp eax, 0x82
    je .lpt_swap
    cmp eax, 0xEF
    je .lpt_efi
    cmp eax, 0x0C
    je .lpt_fat32
    cmp eax, 0x0B
    je .lpt_fat32
    cmp eax, 0x07
    je .lpt_ntfs
    cmp eax, 0x05
    je .lpt_ext
    cmp eax, 0x0F
    je .lpt_ext
    lea rdi, [msg_type_other]
    call print_str
    jmp .lp_sec_print

.lpt_linux:
    lea rdi, [msg_type_linux]
    call print_str
    jmp .lp_sec_print
.lpt_swap:
    lea rdi, [msg_type_swap]
    call print_str
    jmp .lp_sec_print
.lpt_efi:
    lea rdi, [msg_type_efi]
    call print_str
    jmp .lp_sec_print
.lpt_fat32:
    lea rdi, [msg_type_fat32]
    call print_str
    jmp .lp_sec_print
.lpt_ntfs:
    lea rdi, [msg_type_ntfs]
    call print_str
    jmp .lp_sec_print
.lpt_ext:
    lea rdi, [msg_type_ext]
    call print_str

.lp_sec_print:
    mov rax, r10
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov eax, dword [rbx + 8]
    mov rdi, rax
    call print_num_padded

    mov rax, r10
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov eax, dword [rbx + 12]
    mov rdi, rax
    call print_num_padded

    mov rax, r10
    shl rax, 4
    add rax, 446
    lea rbx, [sector_buf + rax]

    mov eax, dword [rbx + 12]
    shr eax, 11
    mov rdi, rax
    call print_num
    lea rdi, [msg_unit_mb]
    call print_str

.lp_next_part_slot:
    inc r10
    jmp .lp_part_entry_loop

.lp_next_dent:
    movzx eax, word [r15 + 16]
    add r14, rax
    jmp .lp_dent_loop

.lp_close:
    mov rax, 3
    mov rdi, r12
    syscall

.lp_chk_fallback:
    cmp byte [part_found_flag], 0
    jne .lp_done

    mov rax, 2
    lea rdi, [path_proc_parts]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lp_none_show
    mov r12, rax

    mov rax, 0
    mov rdi, r12
    lea rsi, [dents_buf]
    mov rdx, 4095
    syscall
    push rax
    mov rax, 3
    mov rdi, r12
    syscall
    pop rax
    cmp rax, 0
    jle .lp_none_show

    mov byte [dents_buf + rax], 0
    lea r12, [dents_buf]

.lp_skip_header:
    cmp byte [r12], 0
    je .lp_none_show
    cmp byte [r12], 10
    je .lp_hdr_nl1
    inc r12
    jmp .lp_skip_header
.lp_hdr_nl1:
    inc r12
    cmp byte [r12], 10
    jne .lp_parse_proc_line
    inc r12

.lp_parse_proc_line:
    cmp byte [r12], 0
    je .lp_chk_done_proc

.lp_skip_lead_spc:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_inc_spc
    cmp al, 9
    je .lp_inc_spc
    cmp al, 10
    je .lp_next_proc_line
    cmp al, 0
    je .lp_chk_done_proc
    jmp .lp_skip_major
.lp_inc_spc:
    inc r12
    jmp .lp_skip_lead_spc

.lp_skip_major:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_skip_spc1
    cmp al, 9
    je .lp_skip_spc1
    cmp al, 10
    je .lp_next_proc_line
    cmp al, 0
    je .lp_chk_done_proc
    inc r12
    jmp .lp_skip_major

.lp_skip_spc1:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_inc_spc1
    cmp al, 9
    je .lp_inc_spc1
    jmp .lp_skip_minor
.lp_inc_spc1:
    inc r12
    jmp .lp_skip_spc1

.lp_skip_minor:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_skip_spc2
    cmp al, 9
    je .lp_skip_spc2
    cmp al, 10
    je .lp_next_proc_line
    cmp al, 0
    je .lp_chk_done_proc
    inc r12
    jmp .lp_skip_minor

.lp_skip_spc2:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_inc_spc2
    cmp al, 9
    je .lp_inc_spc2
    jmp .lp_read_blocks
.lp_inc_spc2:
    inc r12
    jmp .lp_skip_spc2

.lp_read_blocks:
    xor rbx, rbx
.lp_rb_loop:
    movzx eax, byte [r12]
    cmp al, '0'
    jl .lp_rb_end
    cmp al, '9'
    jg .lp_rb_end
    sub al, '0'
    imul rbx, 10
    movzx rax, al
    add rbx, rax
    inc r12
    jmp .lp_rb_loop
.lp_rb_end:

.lp_skip_spc3:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_inc_spc3
    cmp al, 9
    je .lp_inc_spc3
    jmp .lp_read_dev_name
.lp_inc_spc3:
    inc r12
    jmp .lp_skip_spc3

.lp_read_dev_name:
    xor rcx, rcx
.lp_rdn_loop:
    mov al, byte [r12]
    cmp al, ' '
    je .lp_rdn_done
    cmp al, 9
    je .lp_rdn_done
    cmp al, 10
    je .lp_rdn_done
    cmp al, 13
    je .lp_rdn_done
    cmp al, 0
    je .lp_rdn_done
    cmp rcx, 60
    jge .lp_rdn_skip_char
    mov byte [dev_name_buf + rcx], al
    inc rcx
.lp_rdn_skip_char:
    inc r12
    jmp .lp_rdn_loop
.lp_rdn_done:
    mov byte [dev_name_buf + rcx], 0

    cmp rcx, 0
    jle .lp_next_proc_line

    lea rdi, [path_buf]
    lea rsi, [path_sys_cls_blk]
    call strcpy
    lea rdi, [path_buf]
    lea rsi, [dev_name_buf]
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_partition_file]
    call strcat

    mov rax, 21
    lea rdi, [path_buf]
    xor rsi, rsi
    syscall
    cmp rax, 0
    jne .lp_next_proc_line

    mov byte [part_found_flag], 1

    lea rdi, [msg_part_line]
    call print_str
    lea rdi, [dev_prefix]
    call print_str
    lea rdi, [dev_name_buf]
    call print_str
    lea rdi, [msg_part_size]
    call print_str

    shr rbx, 10
    mov rdi, rbx
    call print_num
    lea rdi, [msg_unit_mb]
    call print_str

.lp_next_proc_line:
    cmp byte [r12], 0
    je .lp_chk_done_proc
    cmp byte [r12], 10
    je .lp_adv_nl
    inc r12
    jmp .lp_next_proc_line
.lp_adv_nl:
    inc r12
    jmp .lp_parse_proc_line

.lp_chk_done_proc:
    cmp byte [part_found_flag], 0
    jne .lp_done

.lp_none_show:
    lea rdi, [msg_no_parts]
    call print_str

.lp_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

list_usb_devices:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov byte [found_flag], 0

    mov rax, 2
    lea rdi, [path_sys_usb]
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_fallback
    mov r12, rax

.lu_read_dents:
    mov rax, 217
    mov rdi, r12
    lea rsi, [dents_buf]
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .lu_close
    mov r13, rax
    xor r14, r14

.lu_dent_loop:
    cmp r14, r13
    jge .lu_read_dents
    lea r15, [dents_buf + r14]

    lea rbx, [r15 + 19]

    cmp byte [rbx], '.'
    je .lu_next_dent

    lea rdi, [path_buf]
    lea rsi, [path_sys_usb]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_vendor]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_next_dent
    mov r8, rax

    mov qword [vendor_buf], 0
    mov qword [vendor_buf + 8], 0
    mov rax, 0
    mov rdi, r8
    lea rsi, [vendor_buf]
    mov rdx, 8
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lu_next_dent
    mov byte [vendor_buf + rax], 0
    call trim_vendor_buf

    lea rdi, [path_buf]
    lea rsi, [path_sys_usb]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_product]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_next_dent
    mov r8, rax

    mov qword [product_buf], 0
    mov qword [product_buf + 8], 0
    mov rax, 0
    mov rdi, r8
    lea rsi, [product_buf]
    mov rdx, 8
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lu_next_dent
    mov byte [product_buf + rax], 0
    call trim_product_buf

    mov byte [found_flag], 1

    lea rdi, [path_buf]
    lea rsi, [path_sys_usb]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_busnum]
    call strcat

    mov qword [bus_buf], 0
    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_def_bus
    mov r8, rax
    mov rax, 0
    mov rdi, r8
    lea rsi, [bus_buf]
    mov rdx, 8
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lu_def_bus
    mov byte [bus_buf + rax], 0
    call trim_bus_buf
    jmp .lu_get_devnum
.lu_def_bus:
    mov word [bus_buf], '1'

.lu_get_devnum:
    lea rdi, [path_buf]
    lea rsi, [path_sys_usb]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_devnum]
    call strcat

    mov qword [dev_buf], 0
    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_def_dev
    mov r8, rax
    mov rax, 0
    mov rdi, r8
    lea rsi, [dev_buf]
    mov rdx, 8
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lu_def_dev
    mov byte [dev_buf + rax], 0
    call trim_dev_buf
    jmp .lu_get_prod_str
.lu_def_dev:
    mov word [dev_buf], '1'

.lu_get_prod_str:
    mov byte [name_buf], 0
    lea rdi, [path_buf]
    lea rsi, [path_sys_usb]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_prod_name]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_get_mfg_str
    mov r8, rax
    mov rax, 0
    mov rdi, r8
    lea rsi, [name_buf]
    mov rdx, 127
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lu_no_name
    mov byte [name_buf + rax], 0
    call trim_name_buf
    jmp .lu_get_mfg_str
.lu_no_name:
    mov byte [name_buf], 0

.lu_get_mfg_str:
    mov byte [mfg_buf], 0
    lea rdi, [path_buf]
    lea rsi, [path_sys_usb]
    call strcpy
    lea rdi, [path_buf]
    call strlen
    mov byte [path_buf + rax], '/'
    inc rax
    mov byte [path_buf + rax], 0
    lea rdi, [path_buf]
    mov rsi, rbx
    call strcat
    lea rdi, [path_buf]
    lea rsi, [str_mfg_name]
    call strcat

    mov rax, 2
    lea rdi, [path_buf]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl .lu_print_device
    mov r8, rax
    mov rax, 0
    mov rdi, r8
    lea rsi, [mfg_buf]
    mov rdx, 127
    syscall
    push rax
    mov rax, 3
    mov rdi, r8
    syscall
    pop rax
    cmp rax, 0
    jle .lu_no_mfg
    mov byte [mfg_buf + rax], 0
    call trim_mfg_buf
    jmp .lu_print_device
.lu_no_mfg:
    mov byte [mfg_buf], 0

.lu_print_device:
    lea rdi, [msg_usb_bus]
    call print_str
    lea rdi, [bus_buf]
    call print_str
    lea rdi, [msg_usb_dev]
    call print_str
    lea rdi, [dev_buf]
    call print_str
    lea rdi, [msg_usb_id]
    call print_str
    lea rdi, [vendor_buf]
    call print_str
    lea rdi, [msg_usb_colon]
    call print_str
    lea rdi, [product_buf]
    call print_str
    lea rdi, [msg_usb_name]
    call print_str

    cmp byte [mfg_buf], 0
    je .lu_pr_prod
    lea rdi, [mfg_buf]
    call print_str
    lea rdi, [msg_spc]
    call print_str

.lu_pr_prod:
    cmp byte [name_buf], 0
    je .lu_pr_end
    lea rdi, [name_buf]
    call print_str

.lu_pr_end:
    lea rdi, [col_reset]
    call print_str
    lea rdi, [msg_nl]
    call print_str

.lu_next_dent:
    movzx eax, word [r15 + 16]
    add r14, rax
    jmp .lu_dent_loop

.lu_close:
    mov rax, 3
    mov rdi, r12
    syscall

.lu_fallback:
    cmp byte [found_flag], 0
    jne .lu_done
    lea rdi, [msg_no_usb]
    call print_str

.lu_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

trim_vendor_buf:
    lea rdi, [vendor_buf]
    call trim_nl
    ret

trim_product_buf:
    lea rdi, [product_buf]
    call trim_nl
    ret

trim_bus_buf:
    lea rdi, [bus_buf]
    call trim_nl
    ret

trim_dev_buf:
    lea rdi, [dev_buf]
    call trim_nl
    ret

trim_name_buf:
    lea rdi, [name_buf]
    call trim_nl
    ret

trim_mfg_buf:
    lea rdi, [mfg_buf]
    call trim_nl
    ret

trim_nl:
    call strlen
    mov rcx, rax
.tn_loop:
    cmp rcx, 0
    jle .tn_ret
    dec rcx
    mov al, byte [rdi + rcx]
    cmp al, 10
    je .tn_zero
    cmp al, 13
    je .tn_zero
    jmp .tn_ret
.tn_zero:
    mov byte [rdi + rcx], 0
    jmp .tn_loop
.tn_ret:
    ret

parse_uint64:
    xor rax, rax
.pu_loop:
    movzx edx, byte [rdi]
    cmp dl, '0'
    jl .pu_done
    cmp dl, '9'
    jg .pu_done
    sub dl, '0'
    imul rax, 10
    add rax, rdx
    inc rdi
    jmp .pu_loop
.pu_done:
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
    lea rsi, [msg_spc]
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

strcat:
    push rdi
    call strlen
    add rdi, rax
    call strcpy
    pop rdi
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

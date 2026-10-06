default rel

section .rodata
banner_l1:  db "   ", 219, 219, 219, 220, 10, 0
banner_l2:  db "   ", 219, 219, 219, 219, 219, 219, 220, "      DEPTH HINUX KERNEL [x86_64 PURE ASM]", 10, 0
banner_l3:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 220, "   Node: dimensions | Hardware Ring 0 Core", 10, 0
banner_l4:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 220, 10, 0
banner_l5:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 220, 10, 0
banner_l6:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 221, "   Zero Monolithic Linux Bloat. Raw Silicon.", 10, 0
banner_l7:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 221, "   Architecture: Hinux Native Microvisor", 10, 0
banner_l8:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 223, "   100% Handcrafted Assembly Subsystems", 10, 0
banner_l9:  db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 223, 10, 0
banner_l10: db "   ", 219, 219, 219, 219, 219, 219, 219, 219, 219, 223, 10, 0
banner_l11: db "   ", 219, 219, 219, 219, 219, 219, 223, 10, 0
banner_l12: db "   ", 219, 219, 219, 223, 10, 10, 0

msg_init_mm:    db "[HINUX MM] Physical memory frame bitmap allocator online.", 10, 0
msg_init_idt:   db "[HINUX IDT] 64-bit Interrupt Descriptor Table loaded (256 gates).", 10, 0
msg_init_sys:   db "[HINUX SYS] MSR LSTAR hardware syscall engine armed.", 10, 0
msg_init_sched: db "[HINUX SCHED] Preemptive Task Scheduler & Context Switcher active.", 10, 0
msg_ready:      db 10, "[HINUX BOOT] Bedrock system ready on bare metal. System operational.", 10, 0

section .text
bits 64
global kmain
extern vga_clear
extern serial_init
extern kprint_red
extern kprint_white
extern mm_init
extern idt_init
extern syscall_init
extern sched_init

kmain:
    call serial_init
    call vga_clear

    lea rdi, [banner_l1]
    call kprint_red
    lea rdi, [banner_l2]
    call kprint_red
    lea rdi, [banner_l3]
    call kprint_red
    lea rdi, [banner_l4]
    call kprint_red
    lea rdi, [banner_l5]
    call kprint_red
    lea rdi, [banner_l6]
    call kprint_red
    lea rdi, [banner_l7]
    call kprint_red
    lea rdi, [banner_l8]
    call kprint_red
    lea rdi, [banner_l9]
    call kprint_red
    lea rdi, [banner_l10]
    call kprint_red
    lea rdi, [banner_l11]
    call kprint_red
    lea rdi, [banner_l12]
    call kprint_red

    call mm_init
    lea rdi, [msg_init_mm]
    call kprint_white

    call idt_init
    lea rdi, [msg_init_idt]
    call kprint_white

    call syscall_init
    lea rdi, [msg_init_sys]
    call kprint_white

    call sched_init
    lea rdi, [msg_init_sched]
    call kprint_white

    lea rdi, [msg_ready]
    call kprint_white

    sti

.kernel_loop:
    hlt
    jmp .kernel_loop

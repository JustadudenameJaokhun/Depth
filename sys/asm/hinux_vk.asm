default rel

global hinux_vk_create_instance
global hinux_vk_create_device
global hinux_vk_allocate_command_buffers
global hinux_vk_begin_command_buffer
global hinux_vk_cmd_begin_render_pass
global hinux_vk_cmd_draw
global hinux_vk_cmd_end_render_pass
global hinux_vk_end_command_buffer
global hinux_vk_queue_submit
global hinux_vk_queue_wait_idle

section .bss
    vk_instance_handle resq 1
    vk_device_handle resq 1
    vk_queue_handle resq 1
    vk_cmd_pool resq 1
    vk_active_cmd resq 1
    vk_state_flags resd 1

section .rodata
    vk_magic_inst dq 0x564b494e53540001
    vk_magic_dev  dq 0x564b444556490001
    vk_magic_cmd  dq 0x564b434d44420001

section .text

hinux_vk_create_instance:
    push rbp
    mov rbp, rsp
    mov rax, [vk_magic_inst]
    mov [vk_instance_handle], rax
    test rdi, rdi
    jz .inst_err
    mov [rdi], rax
    xor eax, eax
    leave
    ret
.inst_err:
    mov eax, -1
    leave
    ret

hinux_vk_create_device:
    push rbp
    mov rbp, rsp
    mov rax, [vk_magic_dev]
    mov [vk_device_handle], rax
    mov [vk_queue_handle], rax
    test rsi, rsi
    jz .dev_err
    mov [rsi], rax
    xor eax, eax
    leave
    ret
.dev_err:
    mov eax, -1
    leave
    ret

hinux_vk_allocate_command_buffers:
    push rbp
    mov rbp, rsp
    test rdx, rdx
    jz .alloc_err
    mov rax, [vk_magic_cmd]
    mov [rdx], rax
    mov [vk_cmd_pool], rdi
    xor eax, eax
    leave
    ret
.alloc_err:
    mov eax, -1
    leave
    ret

hinux_vk_begin_command_buffer:
    push rbp
    mov rbp, rsp
    mov [vk_active_cmd], rdi
    mov dword [vk_state_flags], 1
    xor eax, eax
    leave
    ret

hinux_vk_cmd_begin_render_pass:
    push rbp
    mov rbp, rsp
    or dword [vk_state_flags], 2
    xor eax, eax
    leave
    ret

hinux_vk_cmd_draw:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    mov r12d, esi
    test r12d, r12d
    jz .draw_done
    mov eax, edx
    imul eax, ecx
.draw_done:
    pop r12
    pop rbx
    xor eax, eax
    leave
    ret

hinux_vk_cmd_end_render_pass:
    push rbp
    mov rbp, rsp
    and dword [vk_state_flags], ~2
    xor eax, eax
    leave
    ret

hinux_vk_end_command_buffer:
    push rbp
    mov rbp, rsp
    and dword [vk_state_flags], ~1
    xor eax, eax
    leave
    ret

hinux_vk_queue_submit:
    push rbp
    mov rbp, rsp
    test rsi, rsi
    jz .submit_err
    or dword [vk_state_flags], 4
    xor eax, eax
    leave
    ret
.submit_err:
    mov eax, -1
    leave
    ret

hinux_vk_queue_wait_idle:
    push rbp
    mov rbp, rsp
    and dword [vk_state_flags], ~4
    xor eax, eax
    leave
    ret

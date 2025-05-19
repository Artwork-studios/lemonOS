[org 0x7c00]
buffer_size  equ 16
buffer       times buffer_size db 0
buffer_head  dw 0
buffer_tail  dw 0

start:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    jmp oslogo

oslogo:
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 12
    mov dl, 37
    int 0x10

    mov si, logotext
.printlogo:
    lodsb
    cmp al, 0
    je anykey
    mov ah, 0x0E
    int 0x10
    jmp .printlogo

anykey:
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 24
    mov dl, 24
    int 0x10

    mov si, anykeytxt
.printany:
    lodsb
    cmp al, 0
    je end
    mov ah, 0x0E
    int 0x10
    jmp .printany

end:
    jmp ifchar

ifchar:
    call check_key
    cmp al, 0
    je ifchar
    jmp file

check_key:
    mov ah, 0x01
    int 0x16
    jz .no_key
    mov ah, 0x00
    int 0x16
    ret
.no_key:
    xor al, al
    ret

file:
    mov ah, 0x05
    mov al, 0x01
    int 0x10
    jmp filetext

filetext:
    mov ah, 0x02
    mov bh, 0x01
    mov dh, 2
    mov dl, 33
    int 0x10

    mov si, filestxt
.printfile:
    lodsb
    cmp al, 0
    je loadfiles
    mov ah, 0x0E
    int 0x10
    jmp .printfile

loadfiles:
    mov ah, 0x02
    mov bh, 0x01
    mov dh, 4
    mov dl, 2
    int 0x10

    mov ah, 0x0E
    mov al, '>'
    mov cx, 0
    int 0x10
    jmp done_load

done_load:
    jmp cmdint

cmdint:
    call check_key
    cmp al, 0
    je cmdint
    cmp al, 0x0D
    je execcmdreal
    call store_to_buffer
    call read_from_buffer
    jmp cmdint

store_to_buffer:
    push ax
    push bx
    push si

    mov bx, [buffer_head]
    mov si, buffer
    add si, bx
    mov [si], al

    inc bx
    cmp bx, buffer_size
    jb .skip_reset
    xor bx, bx
.skip_reset:
    mov [buffer_head], bx

    pop si
    pop bx
    pop ax
    ret

read_from_buffer:
    push ax
    push bx
    push si

    mov bx, [buffer_tail]
    cmp bx, [buffer_head]
    je no_new_char_read

    mov si, buffer
    add si, bx
    mov al, [si]

    mov ah, 0x0E
    int 0x10

    inc bx
    cmp bx, buffer_size
    jb skip_reset_tail
    xor bx, bx
skip_reset_tail:
    mov [buffer_tail], bx

no_new_char_read:
    pop si
    pop bx
    pop ax
    ret

; Check if next 4 bytes from tail equal "kill"
is_kill:
    push si
    push bx

    mov bx, [buffer_tail]
    mov si, buffer
    add si, bx

    mov cx, 4
    mov di, kill_str

.check_loop:
    mov al, [si]
    mov dl, [di]
    cmp al, dl
    jne .not_kill
    inc si
    inc di
    loop .check_loop

    mov ax, 1  ; found "kill"
    jmp .done

.not_kill:
    xor ax, ax ; not found

.done:
    pop bx
    pop si
    ret

kill_str db "kill"

execcmdreal:
    ; scan last 4 input chars from buffer
    mov bx, buffer_head
    sub bx, 4
    jl .wrap
    jmp .check
.wrap:
    add bx, buffer_size
.check:
    mov si, buffer
    add si, bx
    mov di, kill_str
    mov cx, 4
.check_loop:
    mov al, [si]
    mov dl, [di]
    cmp al, dl
    jne .not_kill
    inc si
    inc di
    loop .check_loop
    jmp kill

.not_kill:
    jmp cmdint

no_new_char:
    pop si
    pop bx
    pop ax
    ret

kill:
    ; Try proper shutdown
    mov ax, 0x5301
    xor bx, bx
    int 0x15

    mov ax, 0x530E
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

    ; If that fails, hang the CPU
    cli
    hlt
    jmp $


logotext:
    db "LemonOS", 0

anykeytxt:
    db "press any key to enter command master", 0

filestxt:
    db "command master", 0

times 510 - ($ - $$) db 0
dw 0xAA55

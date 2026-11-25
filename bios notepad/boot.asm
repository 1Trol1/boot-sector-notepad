[org 0x7C00]

start:
    mov [boot_device], dl

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov sp, 0x7C00

    mov ax, 0x0003
    int 0x10

    mov di, text_buffer

main_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 0x1B        ; ESC -> Zapisz i zresetuj
    je save_and_reboot

    cmp al, 0x08        ; Backspace
    je handle_backspace

    cmp al, 0x0D        ; Enter
    je handle_enter

    mov [di], al
    inc di

    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    jmp main_loop

handle_backspace:
    cmp di, text_buffer
    je main_loop
    
    dec di

    mov ah, 0x03
    xor bh, bh
    int 0x10
    cmp dl, 0
    je main_loop
    dec dl
    mov ah, 0x02
    int 0x10

    mov ah, 0x0E
    mov al, ' '
    int 0x10

    mov ah, 0x03
    int 0x10
    dec dl
    mov ah, 0x02
    int 0x10
    jmp main_loop

handle_enter:
    ; 1. Zapisz CR (0x0D) do bufora RAM
    mov byte [di], 0x0D
    inc di
    ; 2. Zapisz LF (0x0A) do bufora RAM - dzięki temu Linux zobaczy nową linię!
    mov byte [di], 0x0A
    inc di

    ; Wyświetl Enter wizualnie na ekranie (CR + LF)
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    jmp main_loop

save_and_reboot:
    ; Oblicz wielkość tekstu w bajtach
    mov ax, di
    sub ax, text_buffer
    jz do_reboot

    ; Przelicz na sektory (bajty + 511) / 512
    add ax, 511
    mov cl, 9
    shr ax, cl
    mov [sectors_to_write], al

    ; Zapisz wielosektorowo na dysk przez INT 13h
    mov dl, [boot_device]
    mov ah, 0x03
    mov al, [sectors_to_write]
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, text_buffer
    int 0x13

do_reboot:
    ; Niezawodny reset przez port 0x64
    cli
.reset_wait:
    in al, 0x64
    test al, 0x02
    jnz .reset_wait
    mov al, 0xFE
    out 0x64, al
.hang:
    hlt
    jmp .hang

    boot_device db 0
    sectors_to_write db 0
    text_buffer equ 0x7E00

    times 446-($-$$) db 0

    ; Minimalna tablica partycji MBR
    db 0x80
    db 0x00, 0x02, 0x00
    db 0x06
    db 0xFF, 0xFF, 0xFF
    dd 1
    dd 204800
    times 48 db 0

    dw 0xAA55
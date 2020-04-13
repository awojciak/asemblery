assume cs:programCode, ds:programData

programData segment
    ; znaki
    include font.asm

    ; komunikat
    error_message db "Wystapil blad. Upewnij sie, ze uruchomiles program w odpowiedni sposob i sproboj ponownie.$"

    ; dane
    zoom db 3 dup(?)
    zoom_number dw 1
    text_to_zoom db 100 dup(?)
programData ends

;-----

programStack segment stack
    dw 255 dup(?)
    top dw ?
programStack ends

;-----

programCode segment
init:
    mov ax,seg programStack
    mov ss,ax
    mov sp,offset top

    call get_args

    mov ax,seg programData
    mov ds,ax

    mov si,offset zoom
    call get_zoom_number

finish:
    mov ah,4ch
    int 21h
    ret

;***

get_args:
    mov di,81h
    mov ax,seg programData
    mov es,ax

    pre_get_text_to_zoom:
        mov si,offset text_to_zoom
        call spaces_iterator

    get_text_to_zoom:
        mov al,byte ptr ds:[di]
        cmp al,' '
        je pre_get_zoom
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_text_to_zoom

    pre_get_zoom:
        mov si,offset zoom
        call spaces_iterator

    get_zoom:
        mov al,byte ptr ds:[di]
        cmp al,' '
        je end_getting_args
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_zoom

    end_getting_args:
        ret

;***

get_zoom_number:
    mov ax,0
    mov bx,10

    ciphers_loop:
        cmp byte ptr ds:[si],0
        je loop_end
        sub byte ptr ds:[si],0
        mul bx
        add al, byte ptr ds:[si]
        inc si
        jmp ciphers_loop

    loop_end:
        mov word ptr ds:[zoom_number], ax
        ret

;***

spaces_iterator:
    iterator_loop:
        cmp byte ptr [di],' '
        jne iterator_end
        inc di
        jmp iterator_loop

    iterator_end:
        ret

;***

error_handler:
    mov dx,offset error_message
    call print_message
    call finish

;***

print_message:
    mov ax,seg programData
    mov ds,ax
    mov ah,09h
    int 21h
    ret
programCode ends

;-----

end init
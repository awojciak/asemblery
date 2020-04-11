programData segment
    ; znaki
    include font.asm

    ; komunikat
    error_message db "Wystapil blad. Upewnij sie, ze uruchomiles program w odpowiedni sposob i sproboj ponownie.$"

    ; dane
    zoom db 3 dup(?)
    zoom_number dw 1
    text_to_zoom db 256 dup(?)
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

finish:
    mov ah,4ch
    int 21h
    ret

;***

get_args:
    mov di,81h
    mov ax, seg programData
    mov es,ax

    pre_get_text_to_zoom:
        mov si,offset text_to_zoom
        call spaces_iterator

    get_text_to_zoom:
        cmp byte ptr ds:[di],' '
        je pre_get_zoom
        mov byte ptr es:[si], ds:[di]

        inc di
        inc si
        jmp get_text_to_zoom

    pre_get_zoom:
        mov si,offset zoom
        call spaces_iterator

    get_zoom:
        cmp byte ptr ds:[di],' '
        je end_getting_args
        mov byte ptr es:[si], ds:[di]

        inc di
        inc si
        jmp get_zoom

    end_getting_args:
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
    mov ax,seg data
    mov ds,ax
    mov ah,09h
    int 21h
    ret
programCode ends

;-----

end init
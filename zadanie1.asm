programData segment
    ; komunikaty
    error_message db "Wystapil blad. Upewnij sie, ze uruchomiles program w odpowiedni sposob i sproboj ponownie.$"
    success_message db "Wykonanie zakonczone sukcesem. Plik zostal zaszyfrowany$"

    ; dane
    input_name db 256 dup(?)
    output_name db 256 dup(?)
    password db 256 dup(?)
    input dw ?
    output dw ?
    buf db 2048 dup(?)
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

    pre_get_input_name:
        mov si,offset input_name
        call spaces_iterator

    get_input_name:
        cmp byte ptr ds:[di],' '
        je pre_get_output_name
        mov byte ptr es:[si], ds:[di]

        inc di
        inc si
        jmp get_input_name

    pre_get_output_name:
        mov si,offset output_name
        call spaces_iterator

    get_output_name:
        cmp byte ptr ds:[di],' '
        je pre_get_password
        mov byte ptr es:[si], ds:[di]

        inc di
        inc si
        jmp get_output_name

    pre_get_password:
        mov si,offset password
        call spaces_iterator

        cmp byte ptr ds:[di],'"'
        je error_handler
        inc di
        cmp byte ptr ds:[di],'"'
        je error_handler

    get_password:
        cmp byte ptr ds:[di],'"'
        je end_getting_args
        mov byte ptr es:[si], ds:[di]

        inc di
        inc si
        jmp get_password
    
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

success_handler:
    mov dx,offset success_message
    call print_message
    call finish

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
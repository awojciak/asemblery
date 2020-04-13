assume cs:programCode, ds:programData

programData segment
    ; komunikaty
    error_message db "Wystapil blad. Upewnij sie, ze uruchomiles program w odpowiedni sposob i sproboj ponownie.$"
    success_message db "Wykonanie zakonczone sukcesem. Plik zostal zaszyfrowany$"

    ; dane
    input_name db 100 dup(?)
    output_name db 100 dup(?)
    password db 100 dup('$')
    input dw ?
    output dw ?
    len dw ?
    buf db 1000 dup('$')
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

    call open_input

    call create_output

    call use_xor

finish:
    mov ah,4ch
    int 21h
    ret

;***

print_message:
    mov ax,seg programData
    mov ds,ax
    mov ah,09h
    int 21h

    ret

;***

get_args:
    mov di,81h
    mov ax,seg programData
    mov es,ax

    pre_get_input_name:
        mov si,offset input_name
        call spaces_iterator

    get_input_name:
        mov al,byte ptr ds:[di]
        cmp al,' '
        je pre_get_output_name
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_input_name

    pre_get_output_name:
        mov si,offset output_name
        call spaces_iterator

    get_output_name:
        mov al,byte ptr ds:[di]
        cmp al,' '
        je pre_get_password
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_output_name

    pre_get_password:
        mov si,offset password
        call spaces_iterator

        mov al,byte ptr ds:[di]
        cmp al,'"'
        jne error_handler
        inc di

    get_password:
        mov al,byte ptr ds:[di]
        cmp al,'"'
        je end_getting_args
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_password
    
    end_getting_args:
        ret

;***

open_input:
    mov dx,offset input_name

    mov al,0
    mov ah,3dh
    int 21h

    jc error_handler
    mov word ptr ds:[input],ax

    ret

;***

create_output:
    mov dx,offset output_name

    mov cl,0
    mov ah,3ch
    int 21h

    jc error_handler
    mov word ptr ds:[output],ax

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

use_xor:
    xoring_start:
        mov cx,1000
        mov bx,word ptr ds:[input]

        mov ax,seg programData
        mov ds,ax

        mov dx,offset buf
        mov ah,3fh
        int 21h

        jc error_handler

        cmp ax,0
        je finish_xoring

        mov cx,ax
        mov ds:[len],ax
        mov si, offset buf

    password_from_start:
        mov di,offset password

    xoring_loop:
        mov al,byte ptr ds:[di]
        cmp al,0
        je password_from_start

        xor byte ptr ds:[si],al

        inc si
        inc di

        loop xoring_loop

    save_result:
        mov bx, word ptr ds:[output]
        mov cx, ds:[len]

        mov ax,seg programData
        mov ds,ax
        mov dx, offset buf
        mov ah,40h
        int 21h

        jmp xoring_start

    finish_xoring:
        mov bx,word ptr ds:[input]
        mov ah,3eh
        int 21h
        jc error_handler

        mov bx,word ptr ds:[output]
        mov ah,3eh
        int 21h
        jc error_handler

        call success_handler

;***

spaces_iterator:
    iterator_loop:
        cmp byte ptr [di],' '
        jne iterator_end
        inc di
        jmp iterator_loop

    iterator_end:
        ret
programCode ends

;-----

end init
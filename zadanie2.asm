assume cs:programCode, ds:programData

programStack segment stack
    dw 255 dup(?)
    top dw ?
programStack ends

;-----

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

    call zoom_text

    mov ax,0
    int 16h

    mov al,3h
    mov ah,0
    int 10h

finish:
    mov ah,4ch
    int 21h
    ret

;***

get_args:
    mov di,81h
    mov ax,seg programData
    mov es,ax

    pre_get_zoom:
        mov si,offset zoom
        call spaces_iterator

    get_zoom:
        mov al,byte ptr ds:[di]
        cmp al,' '
        je pre_get_text_to_zoom
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_zoom

    pre_get_text_to_zoom:
        mov si,offset text_to_zoom
        call spaces_iterator

    get_text_to_zoom:
        mov al,byte ptr ds:[di]
        cmp al,0
        je end_getting_args
        mov byte ptr es:[si],al

        inc di
        inc si
        jmp get_text_to_zoom

    end_getting_args:
        ret

;***

get_zoom_number:
    mov ax,0
    mov bx,10

    ciphers_loop:
        cmp byte ptr ds:[si],0
        je loop_end
        sub byte ptr ds:[si],'0'
        mul bx
        add al,byte ptr ds:[si]
        inc si
        jmp ciphers_loop

    loop_end:
        mov word ptr ds:[zoom_number],ax
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

;***

zoom_text:
    mov al,13h
    mov ah,0
    int 10h

    mov ax,0A000h
    mov es,ax

    mov bx,0

    mov si,offset text_to_zoom

    for_each_letter:
        mov ax,0
        mov al,byte ptr ds:[zoom_number]
        mul bx

        shl ax,1
        shl ax,1
        shl ax,1

        mov dx,ax

        mov di,offset font
        mov ax,0
        mov al,byte ptr ds:[si]
        shl ax,1
        shl ax,1
        shl ax,1
        add di,ax

        bitmap_painting:
            push bx
            push si
            push dx

            mov al,1

            mov cx,8 ; normalna liczba rzędów bitmapy
            bitmap_row_loop:
                push cx ; uwaga do wszystkich push/pop cx: odkładam akumulator obecnej pętli, by nie został nadpisany przez należący do kolejnej

                mov cx,word ptr ds:[zoom_number] ; liczba rzędów ekranu, jakie zajmie jeden rząd bitmapy
                screen_row_loop:
                    push cx

                    mov si,dx ; początek nowego rzędu bitmapy litery

                    mov cx,8 ; normalna liczba kolumn bitmapy
                    column_loop:
                        push cx

                        mov bl,byte ptr ds:[di]

                        and bl,al
                        rol al,1

                        mov cx,word ptr ds:[zoom_number] ; liczba kolumn ekranu, jakie zajmie jedna kolumna bitmapy
                        pixel_loop:
                            cmp bl,0
                            je increase
                            mov byte ptr es:[si],28h ; kolorowanie punktu
                            increase:
                                inc si ; przesuwamy się o punkt w obecnym rzędzie
                            loop pixel_loop

                        pop cx
                        loop column_loop

                    add dx,320 ; przesuwamy się o rząd ekranu

                    pop cx
                    loop screen_row_loop

                inc di

                pop cx
                loop bitmap_row_loop

            pop dx
            pop si
            pop bx

        inc bx
        inc si
        cmp byte ptr ds:[si],0
        jne for_each_letter

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

programCode ends

;-----

end init
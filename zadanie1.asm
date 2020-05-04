assume cs:programCode ; bez tego masm drze się, że unreachable CS

programStack segment stack
    dw 255 dup(?)
    top dw ?
programStack ends

;-----

programData segment
    ; komunikaty
    error_message db "Wystapil blad. Upewnij sie, ze uruchomiles program w odpowiedni sposob i sproboj ponownie.$"
    success_message db "Wykonanie zakonczone sukcesem. Plik zostal zaszyfrowany$"

    ; dane
    input_name db 100 dup(?)
    output_name db 100 dup(?)
    password db 100 dup(?)
    input dw ?
    output dw ?
    len dw ?
    buf db 1000 dup('$')
programData ends

;-----

programCode segment
init:
    mov ax,seg programStack ; inicjalizacja stosu
    mov ss,ax
    mov sp,offset top

    call get_args

    mov ax,seg programData ; inicjalizacja segmentu danych
    mov ds,ax

    call open_input

    call create_output

    call use_xor

finish:
    mov ah,4ch ; przerwanie kończące pracę programu
    int 21h
    ret

;***

print_message:
    mov ah,09h ; przerwanie wypisujące tekst
    int 21h

    ret

;***

get_args:
    mov di,81h ; przechodzimy do argumentów programu
    mov ax,seg programData
    mov es,ax

    pre_get_input_name:
        mov si,offset input_name
        call spaces_iterator

    get_input_name:
        mov al,byte ptr ds:[di]
        cmp al,' ' ; sprawdzamy, czy aktualny znak to spacja
        je pre_get_output_name ; jeśli tak, to przechodzimy do wczytywania kolejnego argumentu
        mov byte ptr es:[si],al ; zapisujemy kolejny znak

        inc di ; przechodzimy o znak w przód
        inc si
        jmp get_input_name

    pre_get_output_name:
        mov si,offset output_name
        call spaces_iterator

    get_output_name:
        mov al,byte ptr ds:[di]
        cmp al,' ' ; sprawdzamy, czy aktualny znak to spacja
        je pre_get_password ; jeśli tak, to przechodzimy do wczytywania kolejnego argumentu
        mov byte ptr es:[si],al ; zapisujemy kolejny znak

        inc di ; przechodzimy o znak w przód
        inc si
        jmp get_output_name

    pre_get_password:
        mov si,offset password
        call spaces_iterator

        mov al,byte ptr ds:[di]
        cmp al,'"' ; sprawdzamy, czy hasło jest w cudzysłowiu
        jne error_handler ; bląd, jeśli nie
        inc di ; przechodzimy o znak w przód

    get_password:
        mov al,byte ptr ds:[di]
        cmp al,'"' ; sprawdzamy, czy doszliśmy do końca hasła
        je end_getting_args ; jeśli tak, kończymy wczytywać argumenty
        mov byte ptr es:[si],al ; zapisujemy kolejny znak

        inc di ; przechodzimy o znak w przód
        inc si
        jmp get_password
    
    end_getting_args:
        ret

;***

open_input:
    mov dx,offset input_name

    mov al,0
    mov ah,3dh ; przerwanie otwierające plik
    int 21h

    jc error_handler ; komunikat, jeśli zdarzy się błąd
    mov word ptr ds:[input],ax ; przeniesienie uchwytu pliku

    ret

;***

create_output:
    mov dx,offset output_name

    mov cl,0
    mov ah,3ch ; przerwanie tworzące nowy plik
    int 21h

    jc error_handler ; komunikat, jeśli zdarzy się błąd
    mov word ptr ds:[output],ax ; przeniesienie uchwytu pliku

    ret

;***

success_handler:
    mov dx,offset success_message ; wczytujemy komunikat o sukcesie
    call print_message
    call finish

;***

error_handler:
    mov dx,offset error_message ; wczytujemy komunikat o blędzie
    call print_message
    call finish

;***

use_xor:
    xoring_start:
        mov cx,1000 ; długość bufora do wczytywania pliku - przy braku ustawienia tego, nic się nie znajdzie w pliku wynikowym
        mov bx,word ptr ds:[input]

        mov dx,offset buf
        mov ah,3fh ; przerwanie powodujące odczyt danych z pliku do bufora
        int 21h

        jc error_handler ; komunikat, jeśli błąd

        cmp ax,0 ; sprawdzamy, czy doszliśmy do końca pliku
        je finish_xoring ; jeśli tak, kończymy xorowanie

        mov cx,ax ; wczytujemy długość wczytanego tekstu do licznika pętli
        mov ds:[len],ax ; zapisujemy długość wczytanego tekstu na później
        mov si, offset buf

    password_from_start:
        mov di,offset password

    xoring_loop:
        mov al,byte ptr ds:[di]
        cmp al,0 ; sprawdzamy, czy doszliśmy do końca hasła
        je password_from_start ; jeśli tak, zaczynamy przechodzenie po haśle od początku

        xor byte ptr ds:[si],al ; xorujemy znaki z pliku i z hasła
        inc si ; przechodzimy o znak w przód
        inc di

        loop xoring_loop

    save_result:
        mov bx, word ptr ds:[output]
        mov cx, ds:[len] ; wczytujemy długość wczytanego tekstu - bez użycia tego też nic się nie znajdzie w pliku

        mov dx,offset buf
        mov ah,40h ; przerwanie zapisujące zawartość bufora do pliku
        int 21h

        jmp xoring_start

    finish_xoring:
        mov bx,word ptr ds:[input]
        mov ah,3eh ; przerwanie zamykające plik
        int 21h
        jc error_handler ; komunikat, jeśli zdarzy się bląd

        mov bx,word ptr ds:[output]
        mov ah,3eh ; przerwanie zamykające plik
        int 21h
        jc error_handler ; komunikat, jeśli zdarzy się błąd

        call success_handler

;***

spaces_iterator:
    iterator_loop:
        cmp byte ptr ds:[di],' ' ; przechodzenie po kolejnych znakach łańcucha i porównywanie aktualnego ze spacją
        jne iterator_end
        inc di
        jmp iterator_loop

    iterator_end: ; gdy przeszliśmy do znaku nie będącego spacją
        ret
programCode ends

;-----

end init
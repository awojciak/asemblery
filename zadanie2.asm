assume cs:programCode ; bez tego masm drze się, że unreachable CS

programStack segment stack
    dw 255 dup(?)
    top dw ?
programStack ends

;-----

programData segment
    ; znaki
    include font.asm

    ; dane
    zoom db 3 dup(?)
    zoom_number dw 1
    text_to_zoom db 100 dup(?)
programData ends

;-----

programCode segment
init:
    mov ax,seg programStack ; inicjalizacja stosu
    mov ss,ax
    mov sp,offset top

    call get_args

    mov ax,seg programData ; inicjalizacja segementu danych
    mov ds,ax

    call get_zoom_number

    call zoom_text

    mov ax,0 ; czekanie na wciśnięcie klawisza
    int 16h

    mov al,3h ; powrót do poprzedniego trybu
    mov ah,0
    int 10h

finish:
    mov ah,4ch ; przerwanie kończące pracę programu
    int 21h
    ret

;***

get_args:
    mov di,81h ; przechodzimy do argumentów programu
    mov ax,seg programData
    mov es,ax

    pre_get_zoom:
        mov si,offset zoom
        call spaces_iterator

    get_zoom:
        mov al,byte ptr ds:[di]
        cmp al,' ' ; sprawdzamy, czy aktualny znak to spacja
        je pre_get_text_to_zoom ; jeśli tak, to przechodzimy do wczytywania kolejnego argumentu
        mov byte ptr es:[si],al ; zapisujemy kolejny znak

        inc di ; przechodzimy o znak w przód
        inc si
        jmp get_zoom

    pre_get_text_to_zoom:
        mov si,offset text_to_zoom
        call spaces_iterator

    get_text_to_zoom:
        mov al,byte ptr ds:[di]
        cmp al,0 ; sprawdzamy, czy doszliśmy do końca argumentów
        je end_getting_args ; jeśli tak, to kończymy wczytywać argumenty
        mov byte ptr es:[si],al ; zapisujemy kolejny znak

        inc di ; przechodzimy o znak w przód
        inc si
        jmp get_text_to_zoom

    end_getting_args:
        ret

;***

get_zoom_number:
    mov si,offset zoom
    mov ax,0 ; początkowa wartość
    mov bx,10 ; mnożnik dla systemu dziesiętnego

    ciphers_loop:
        cmp byte ptr ds:[si],0 ; sprawdzamy, czy argument już się skończył
        je loop_end

        mul bx ; mnożymy przez 10
        add al,byte ptr ds:[si] ; dodajemy aktualnie przetwarzaną cyfrę
        sub ax,'0' ; i odejmujemy wartość odpowiadającą znakowi 0

        inc si ; przechodzimy dalej
        jmp ciphers_loop

    loop_end:
        mov word ptr ds:[zoom_number],ax ; zapisujemy wynik
        ret

;***

zoom_text:
    mov al,13h ; przejście do trybu graficznego
    mov ah,0
    int 10h
    mov ax,0A000h
    mov es,ax

    mov bx,0 ; indeks aktualnej litery

    mov si,offset text_to_zoom ; zaczynamy iterowanie po tekscie

    for_each_letter:
        mov ax,word ptr ds:[zoom_number]
        mul bx

        shl ax,1 ; przy użyciu instrukcji shl ax,3 pojawia się błąd, ale gdy robimy tak, to nie
        shl ax,1
        shl ax,1

        mov dx,ax ; miejsce, w którym zaczynamy rysować nową bitmapę litery - iloczyn wartości zoomu, indeksu aktualnej litery i liczby 8 - obliczenia zostały wykonane powyżej

        mov di,offset font ; przechodzę do tablicy bitmap

        mov ax,0
        mov al,byte ptr ds:[si] ; aktualna litera jest bajtem, ale używam całego rejestru wielkości słowa, bo 128*8 = 1024, co nie zmieści się w rejestrze bajtowym, ale muszę inicjować w al ze względu na zgodność typów
        shl ax,1 ; mnożymy przez 8, by dostać się do początku bitmapy dla aktualnej litery
        shl ax,1 ; (oraz uwaga taka, jak w wierszu 126)
        shl ax,1
        add di,ax ; i uzyskujemy wskaźnik do początku bitmapy

        bitmap_painting:
            mov cx,8 ; normalna liczba rzędów bitmapy
            bitmap_row_loop:
                push cx ; uwaga do wszystkich push/pop cx: odkładam licznik obecnej pętli, by nie został nadpisany przez należący do kolejnej
                mov cx,word ptr ds:[zoom_number] ; liczba rzędów ekranu, jakie zajmie jeden rząd bitmapy
                screen_row_loop:
                    push bx ; odkładamy wskaźnik do aktualnej litery i jej indeks, by się nie zapodziały
                    push si
                    mov bl,byte ptr ds:[di] ; pobieram aktualny bajt bitmapy
                    mov si,dx ; początek nowego rzędu bitmapy litery

                    mov al,1 ; rejestr do koniugowania bitów

                    call use_conjunction

                    add dx,320 ; przesuwamy się o rząd ekranu

                    pop si
                    pop bx
                    loop screen_row_loop
                pop cx

                inc di ; przechodzimy do kolejnego bajtu bitmapy

                loop bitmap_row_loop

        inc bx ; przechodzimy do kolejnej litery
        inc si

        cmp byte ptr ds:[si],0 ; sprawdzamy, czy doszliśmy do końca tekstu
        jne for_each_letter

    ret

;***

use_conjunction:
    push cx
    mov cx,8 ; normalna liczba kolumn bitmapy
    and_loop:
        push bx ; odkładam wartość aktualnego bajtu, by się nie nadpisała podczas koniunkcji

        and bl,al ; uzyskuję wartość kolejnego bitu dla danej kolumny w danym rzędzie za pomocą koniunkcji rejestru do koniugowania i aktualnego bajtu bitmapy
        shl al,1 ; przesuwam rejestr do koniugowania w lewo o pozycję

        call coloring

        pop bx
        loop and_loop
    pop cx

    ret

;***

coloring:
    push cx
    mov cx,word ptr ds:[zoom_number] ; liczba kolumn ekranu, jakie zajmie jedna kolumna bitmapy
    loopy_loop:
        cmp bl,0 ; sprawdzamy, czy aktualnie rozpatrujemy w bitmapie 0 czy 1
        je increase
        mov byte ptr es:[si],28h ; kolorowanie punktu jeśli 1
        increase:
            inc si ; przesuwamy się o punkt w obecnym rzędzie
        loop loopy_loop
    pop cx

    ret

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
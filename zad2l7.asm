global _start ; _start symbol globalny, od którego zacznie się wykonywanie programu

section .text ; początek sekcji kodu


_start:
	mov	eax, 4	; do akumulatora wrzucamy 4, które oznacza zapisywanie do pliku, write
	mov	ebx, 1	; standardowe wyjście (wyświetlanie w terminalu)
	mov	ecx, pytanie	; napis, który ma wyświetlić
	mov	edx, pytanie_dl	; długość napisu
	int	80h	; wyświetlamy (wywołanie systemowe)

	mov	eax, 3	; czytanie z pliku, read
	mov	ebx, 0	; standardowe wejście (z klawiatury)
	mov	ecx, n	; zmienna, do której czyta
	mov	edx, n_dl
	int	80h	; wczytujemy (wywołanie systemowe)

	xor	eax, eax
	xor	edi, edi

convertToNumber:
	movzx	esi, byte [n + edi]
	test	esi, esi ; sprawdza, czy wartość rejestru nie jest zerem, ustawia flagę zera ZF
	je	skok
	cmp	esi, 48
	jl	skok
	cmp	esi, 57
	jg	skok
	sub	esi, 48
	imul	eax, 10
	add	eax, esi
	inc	edi
	jmp	convertToNumber

skok:
	xor	edi, edi	; wskazuje ile liczb ma się wyświetlać

loop:
	push	eax
	inc	edi	; za każdym razem zwiększamy o 1 ilość wyświetleń
	xor	esi, esi
	xor	eax, eax
	inc	eax ; wypisywanie zaczynamy od 1
	mov	esi, eax
	call	._loop2
	pop	eax
	dec	eax	; zmniejsza o 1
	call	_nowaLinia
	cmp	eax, 0
	jnz	loop ; dopóki nie jest zerem
	jmp	koniec

._loop2:
	mov	eax, esi
	push	esi
	xor	esi, esi
	call 	._convertToString
	call	_spacja
	pop	esi
	inc	esi 
	cmp	esi, edi
	jbe	._loop2	; dopóki jest mniejsze
	ret
	

._convertToString:
	inc	esi
	mov	ebx, 10
	xor	edx, edx	; tutaj znajduje się reszta
	div	ebx
	push	edx
	test	eax, eax	; sprawdza czy mozna dalej dzielic eax
	jnz	._convertToString ; skok jeśli nie zero
_reverse:
	pop	eax
	add	eax, '0'
	mov	[wordd], eax
	mov	ecx, wordd
	call	_pisz_znak
	dec	esi
	cmp	esi, 0
	jnz	_reverse
	ret

_pisz_znak:  
	push    ebx
        push    edx
        mov     eax, 4
        mov     ebx, 1                    
        mov     edx, 2
        int     80h
        pop     edx
        pop     ebx
        ret

_nowaLinia:
	push	eax
	xor	eax, eax
	mov	eax, 0ah
	mov	[wordd], eax
	mov	ecx, wordd
	call	_pisz_znak
	pop	eax
	ret

_spacja:
	push	eax
	xor	eax, eax
	mov	eax, 20h
	mov	[wordd], eax
	mov	ecx, wordd
	call	_pisz_znak
	pop	eax
	ret
	
koniec:
	mov	eax, 1	; wychodzenie z programu
	xor	ebx, ebx	; kod wyjścia = 0
	int	80h	; wychodzimy (wywołanie systemowe)

section .bss
	wordd resb 1

section .data

pytanie:	db	'Podaj liczbe naturalna:',0ah ; db oznacz, że ma to być ciąg znaków
pytanie_dl:	equ	$-pytanie
n:	times	32	db 0	; rezerwuj 8 bajtów o wartości początkowej 0
n_dl:	equ	$-n

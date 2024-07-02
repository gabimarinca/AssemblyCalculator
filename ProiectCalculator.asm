.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
sir DB 9 DUP(0)
n1 DD 0
n2 DD 0
window_title DB "Calculator", 0
area_width EQU 320
area_height EQU 480
area DD 0
var DD 0
aux DD 0
pow DD 1
semn1 DD 0
semn2 DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include symbols.inc

square_x EQU 450 
square_y EQU 200

button_length EQU 50
x147plus EQU 50
y123egal EQU 400
x258minus EQU 115
y456c EQU 320
x369mul EQU 180
y7890 EQU 240
x0divEgalC EQU 245
yplusMinusMulDiv EQU 160
square_size EQU 70
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

;*
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_symbol
	cmp eax, '9'
	jg make_symbol
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_symbol:
	cmp eax, '+'
	je plus
	cmp eax, '-'
	je minus
	cmp eax, '*'
	je inmultire
	cmp eax, '/'
	je impartire
	cmp eax, '='
	je egal
	jmp make_space
	
	plus:
	mov eax, 0
	jmp isSymbol
	minus:
	mov eax, 1
	jmp isSymbol
	inmultire:
	mov eax, 2
	jmp isSymbol
	impartire:
	mov eax, 3
	jmp isSymbol
	egal:
	mov eax, 4
	isSymbol:
	lea esi, symbols
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;*; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
;*
line_horizontal macro x,y, len, color
local bucla_linie
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl EAX, 2			;(EAX = y*area_width + x) * 4
	add EAX, area
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linie
endm

linie_oblicaSt macro x,y, len, color
local bucla_linie
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl EAX, 2			;(EAX = y*area_width + x) * 4
	add EAX, area
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4*area_width-3
	loop bucla_linie
endm

linie_oblicaDr macro x,y, len, color
local bucla_linie
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl EAX, 2			;(EAX = y*area_width + x) * 4
	add EAX, area
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4*area_width+3
	loop bucla_linie
endm
;*
line_vertical macro x,y, len, color
local bucla_linie
	mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; EAX = y * area_width
	add eax, x ; EAX = y*area_width + x
	shl EAX, 2			;(EAX = y*area_width + x) * 4
	add EAX, area
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, area_width*4
	loop bucla_linie
endm
;*
memorare_numar macro nr,array,len							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
local repeta
	mov n2, 0
	mov ecx, len
	dec ecx
	repeta:
	mov eax,0
	mov al, [array+ecx-1]
	mul pow
	add nr,eax
	mov eax, pow
	mov ebx, 10
	mul ebx
	mov pow, eax
loop repeta
	push nr
	mov pow, 1
endm
;*
afisare_output macro											;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
local unu, doi, trei, patru, cinci, sase, sapte, opt, noua, salt
	cmp var, 1
	je unu
	cmp var, 2
	je doi
	cmp var, 3
	je trei
	cmp var, 4
	je patru
	cmp var, 5
	je cinci
	cmp var, 6
	je sase
	cmp var, 7
	je sapte
	cmp var, 8
	je opt
	cmp var, 9
	je noua
	
unu:
	mov edx,0
	mov dl,[sir]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	jmp salt
doi:
	mov edx, 0
	mov dl,[sir+1]
	add dl, 48
	make_text_macro edx,area, 260, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 245, 55
	jmp salt
trei:
	mov edx,0
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 260, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 245, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 230, 55
	jmp salt
patru:
	mov edx,0
	mov dl,[sir+3]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 245, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 230, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 215, 55
	jmp salt
cinci:
	mov edx,0
	mov dl,[sir+4]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	mov dl,[sir+3]
	add dl, '0'
	make_text_macro edx,area, 245, 55
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 230, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 215, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 200, 55
	jmp salt
sase:
	mov edx,0
	mov dl,[sir+5]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	mov dl,[sir+4]
	add dl, '0'
	make_text_macro edx,area, 245, 55
	mov dl,[sir+3]
	add dl, '0'
	make_text_macro edx,area, 230, 55
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 215, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 200, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 185, 55
	jmp salt
sapte:
	mov edx,0
	mov dl,[sir+6]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	mov dl,[sir+5]
	add dl, '0'
	make_text_macro edx,area, 245, 55
	mov dl,[sir+4]
	add dl, '0'
	make_text_macro edx,area, 230, 55
	mov dl,[sir+3]
	add dl, '0'
	make_text_macro edx,area, 215, 55
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 200, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 185, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 170, 55
	jmp salt
opt: 
	mov edx,0
	mov dl,[sir+7]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	mov dl,[sir+6]
	add dl, '0'
	make_text_macro edx,area, 245, 55
	mov dl,[sir+5]
	add dl, '0'
	make_text_macro edx,area, 230, 55
	mov dl,[sir+4]
	add dl, '0'
	make_text_macro edx,area, 215, 55
	mov dl,[sir+3]
	add dl, '0'
	make_text_macro edx,area, 200, 55
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 185, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 170, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 155, 55
	jmp salt
noua:
	mov edx,0
	mov dl,[sir+8]
	add dl, '0'
	make_text_macro edx,area, 260, 55
	mov dl,[sir+7]
	add dl, '0'
	make_text_macro edx,area, 245, 55
	mov dl,[sir+6]
	add dl, '0'
	make_text_macro edx,area, 230, 55
	mov dl,[sir+5]
	add dl, '0'
	make_text_macro edx,area, 215, 55
	mov dl,[sir+4]
	add dl, '0'
	make_text_macro edx,area, 200, 55
	mov dl,[sir+3]
	add dl, '0'
	make_text_macro edx,area, 185, 55
	mov dl,[sir+2]
	add dl, 48
	make_text_macro edx,area, 170, 55
	mov dl, [sir+1]
	add dl,48
	make_text_macro edx,area, 155, 55
	mov dl, [sir]
	add dl,48
	make_text_macro edx,area, 140, 55
	jmp salt
salt:
endm
;*
verif_conditii macro													;;;;;;;;;;;;;;;;;;;;;;
local chosen,divLeft,mulLeft,isPlus,SecondRow,zeroLeft,nineLeft,is7,ThirdRow,cLeft,sixLeft,is4,FourthRow,egalLeft,threeLeft,is1
	cmp ebx, yplusMinusMulDiv+35
	jg SecondRow
	cmp eax, x0divEgalC-20
	jl divLeft
	mov byte ptr [ecx+edx], -1
	jmp chosen
divLeft:
	cmp eax, x369mul-20
	jl mulLeft
	mov byte ptr [ecx+edx], -6
	jmp chosen
mulLeft:
	cmp eax, x258minus-20
	jl isPlus
	mov byte ptr [ecx+edx], -3
	jmp chosen
isPlus:
	mov byte ptr [ecx+edx], -5
	jmp chosen
SecondRow:
	cmp ebx, y7890+35
	jg ThirdRow
	cmp eax, x0divEgalC-20
	jl zeroLeft
	mov byte ptr [ecx+edx], 0
	jmp chosen
zeroLeft:
	cmp eax, x369mul-20
	jl nineLeft
	mov byte ptr [ecx+edx], 9
	jmp chosen
nineLeft:
	cmp eax, x258minus-20
	jl is7
	mov byte ptr [ecx+edx], 8
	jmp chosen
is7:
	mov byte ptr [ecx+edx], 7
	jmp chosen
ThirdRow:
	cmp ebx, y456c+35
	jg FourthRow
	cmp eax, x0divEgalC-20
	jl cLeft
	mov byte ptr [ecx+edx], 19
	jmp chosen
cLeft:
	cmp eax, x369mul-20
	jl sixLeft
	mov byte ptr [ecx+edx], 6
	jmp chosen
sixLeft:
	cmp eax, x258minus-20
	jl is4
	mov byte ptr [ecx+edx], 5
	jmp chosen
is4:
	mov byte ptr [ecx+edx], 4
	jmp chosen
FourthRow:
	cmp eax, x0divEgalC-20
	jl egalLeft
	mov byte ptr [ecx+edx], 13
	jmp chosen
egalLeft:
	cmp eax, x369mul-20
	jl threeLeft
	mov byte ptr [ecx+edx], 3
	jmp chosen
threeLeft:
	cmp eax, x258minus-20
	jl is1
	mov byte ptr [ecx+edx], 2
	jmp chosen
is1:
	mov byte ptr [ecx+edx], 1
	jmp chosen
chosen:
endm

nr_cifre macro n1
local sfarsit, repeta
	push eax
	mov eax, n1
	mov ecx, 0
	repeta:
	mov edx, 0
	inc ecx
	mov ebx, 10
	div ebx
	cmp eax, 0
	jne repeta
sfarsit:	
	pop eax
endm

operatie_numere macro symbol,array
local plus,minus,multiply,divide, rep1,setare, nrNegativ
	push eax
	mov edx, 0
	;dec ecx
	cmp symbol, '+'
	je plus
	cmp symbol, '-'
	je minus
	cmp symbol, '*'
	je multiply
	cmp symbol, '/'
	je divide
plus:
	mov edx, n1
	add edx, n2
	mov n1, edx
	mov eax,n1
	jmp setare
minus:
	mov edx, n2
	cmp edx, n1
	jg nrNegativ
	mov edx,n1
	sub edx,n2
	mov n1, edx
	mov eax, n1
	jmp setare
nrNegativ:
	make_text_macro '-', area, 50, 55
	 mov edx, n2	;
	 sub edx, n1	;
	 mov n1, edx	;
	 mov eax, n1	;
	 jmp setare	;
multiply:
	mov eax, n1
	mul n2
	mov n1, eax
	jmp setare
divide:
	mov eax, n1
	div n2
	mov n1, eax
setare:
	nr_cifre n1
	push ecx
	mov edx, 0
	mov ebx, 10
rep1:
	div ebx
	mov [array+ecx-1], dl
	mov edx,0
loop rep1
endm

curatareOutput macro
	make_text_macro ' ',area, 245, 55	;curatare output
	make_text_macro ' ',area, 230, 55
	make_text_macro ' ',area, 215, 55
	make_text_macro ' ',area, 200, 55
	make_text_macro ' ',area, 185, 55
	make_text_macro ' ',area, 170, 55
	make_text_macro ' ',area, 155, 55
	make_text_macro ' ',area, 140, 55
endm

curatSir macro
local curatSir2
curatSir2:
	lea edx, sir
	mov byte ptr [edx+ecx],0
loop curatSir2
endm


apasare_tasta macro x ,y						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
local notMem,Mem,Mem1,Mem2, final, reinit, salt,clear
	cmp eax, x-20
	jl 	notMem
	cmp eax, x + 30
	jg notMem
	cmp ebx, y - 15
	jl notMem
	cmp ebx, y + 35
	jg notMem


	make_text_macro ' ', area, 50, 55
	cmp semn2, '='
	jne salt
	mov ecx, var
	dec var
	curatareOutput
	curatSir
	mov n1, 0
	mov n2, 0
	mov var, 0
	mov semn1, 0
	mov semn2, 0
salt:
	mov edx, var
	inc var
	lea ecx, sir
	
	
	
	verif_conditii
	afisare_output
	
	mov edx, var
	dec edx
	mov dl, byte ptr [sir+edx]
	add dl, '0'
	cmp edx, 'C'
	je clear
	cmp edx,'+'
	je Mem
	cmp edx,'-'
	je Mem
	cmp edx,'*'
	je Mem
	cmp edx,'/'
	je Mem
	cmp edx,'='
	je Mem
	jmp final
Mem:
	cmp n1, 0
	jne Mem2
	mov semn1, edx
	memorare_numar n1,sir,var
	pop n1
	jmp Mem1
Mem2:
	mov semn2, edx
	memorare_numar n2,sir,var
	pop n2
	mov ecx, var
	dec ecx
	curatSir
	operatie_numere semn1,sir
	pop var
	pop eax
	curatareOutput
	;dec var
	afisare_output
	jmp final
Mem1:
	mov ecx, var
	dec ecx
	curatSir
	mov var, 0
	curatareOutput
	jmp final
notMem:
	jmp final
clear:
	mov n1, 0
	mov n2, 0
	mov semn1, 0
	mov semn2, 0
	mov ecx, var
	curatSir
	curatareOutput
	mov var ,0
	make_text_macro ' ',area, 260, 55
final:
endm

apasare_tasta_stergere macro
	cmp eax, 260
	jl 	salt2
	cmp eax, 290
	jg salt2
	cmp ebx, 100
	jl salt2
	cmp ebx, 120
	jg salt2
	mov ecx, var
	mov byte ptr [sir+ecx-1], 0
	dec var
	curatareOutput
	afisare_output
salt2:
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	
	;push ebx
	mov eax, [ebp+arg2]
	mov ebx, [ebp+arg3]
;*	;apasare taste- verifica pt fiecare
	apasare_tasta x147plus, y123egal
	apasare_tasta x258minus,y123egal
	apasare_tasta x369mul,y123egal
	apasare_tasta x147plus,y456c
	apasare_tasta x258minus,y456c
	apasare_tasta x369mul,y456c
	apasare_tasta x147plus,y7890
	apasare_tasta x258minus,y7890
	apasare_tasta x369mul,y7890
	apasare_tasta x0divEgalC,y7890
	
	apasare_tasta x147plus, yplusMinusMulDiv  
	apasare_tasta x258minus, yplusMinusMulDiv
	apasare_tasta x369mul, yplusMinusMulDiv
	apasare_tasta x0divEgalC,yplusMinusMulDiv
	
	apasare_tasta x0divEgalC,y123egal
	apasare_tasta x0divEgalC,y456c
	
	apasare_tasta_stergere
	
	;pop ebx
	
	jmp afisare_litere
evt_timer:
	inc counter
	
afisare_litere:
;*
	;scriem un mesaj
	
	make_text_macro '1', area, x147plus, y123egal
	make_text_macro '2', area, x258minus, y123egal
	make_text_macro '3', area, x369mul, y123egal
	make_text_macro '4', area, x147plus, y456c
	make_text_macro '5', area, x258minus, y456c
	make_text_macro '6', area, x369mul, y456c
	make_text_macro '7', area, x147plus, y7890
	make_text_macro '8', area, x258minus, y7890
	make_text_macro '9', area, x369mul, y7890
	make_text_macro '0', area, x0divEgalC, y7890
	
	make_text_macro '+', area, x147plus, yplusMinusMulDiv
	make_text_macro '-', area, x258minus, yplusMinusMulDiv
	make_text_macro '*', area, x369mul, yplusMinusMulDiv
	make_text_macro '/', area, x0divEgalC, yplusMinusMulDiv
	make_text_macro '=', area, x0divEgalC, y123egal
	make_text_macro 'C', area, x0divEgalC, y456c
	;desenare zone
	line_horizontal x147plus-20, y123egal-15, button_length, 0						;
	line_horizontal	x147plus-20, y123egal-15 + button_length, button_length, 0		; formare zona 1
	line_vertical x147plus-20, y123egal-15, button_length, 0						;
	line_vertical x147plus-20 + button_length, y123egal-15, button_length, 0		;
	
	line_horizontal x258minus-20, y123egal-15, button_length, 0						;
	line_horizontal	x258minus-20, y123egal-15 + button_length, button_length, 0		; formare zona 2
	line_vertical x258minus-20, y123egal-15, button_length, 0						;
	line_vertical x258minus-20 + button_length, y123egal-15, button_length, 0		;
	
	line_horizontal x369mul-20, y123egal-15, button_length, 0					;
	line_horizontal	x369mul-20, y123egal-15 + button_length, button_length, 0	; formare zona 3
	line_vertical x369mul-20, y123egal-15, button_length, 0						;
	line_vertical x369mul-20 + button_length, y123egal-15, button_length, 0		;
	
	line_horizontal x147plus-20, y456c-15, button_length, 0						;
	line_horizontal	x147plus-20, y456c-15 + button_length, button_length, 0		; formare zona 4
	line_vertical x147plus-20, y456c-15, button_length, 0						;
	line_vertical x147plus-20 + button_length, y456c-15, button_length, 0		;
	
	line_horizontal x258minus-20, y456c-15, button_length, 0						;
	line_horizontal	x258minus-20, y456c-15 + button_length, button_length, 0		; formare zona 5
	line_vertical x258minus-20, y456c-15, button_length, 0							;
	line_vertical x258minus-20 + button_length, y456c-15, button_length, 0			;
	
	line_horizontal x369mul-20, y456c-15, button_length, 0					;
	line_horizontal	x369mul-20, y456c-15 + button_length, button_length, 0	; formare zona 6
	line_vertical x369mul-20, y456c-15, button_length, 0					;
	line_vertical x369mul-20 + button_length, y456c-15, button_length, 0	;
	
	line_horizontal x147plus-20, y7890-15, button_length, 0						;
	line_horizontal	x147plus-20, y7890-15 + button_length, button_length, 0		; formare zona 7
	line_vertical x147plus-20, y7890-15, button_length, 0						;
	line_vertical x147plus-20 + button_length, y7890-15, button_length, 0		;
	
	line_horizontal x258minus-20, y7890-15, button_length, 0						;
	line_horizontal	x258minus-20, y7890-15 + button_length, button_length, 0		; formare zona 8
	line_vertical x258minus-20, y7890-15, button_length, 0							;
	line_vertical x258minus-20 + button_length, y7890-15, button_length, 0			;
	
	line_horizontal x369mul-20, y7890-15, button_length, 0					;
	line_horizontal	x369mul-20, y7890-15 + button_length, button_length, 0	; formare zona 9
	line_vertical x369mul-20, y7890-15, button_length, 0					;
	line_vertical x369mul-20 + button_length, y7890-15, button_length, 0	;
	
	line_horizontal x0divEgalC-20, y7890-15, button_length, 0					;
	line_horizontal	x0divEgalC-20, y7890-15 + button_length, button_length, 0	; formare zona 0
	line_vertical x0divEgalC-20, y7890-15, button_length, 0						;
	line_vertical x0divEgalC-20 + button_length, y7890-15, button_length, 0		;
	
	line_horizontal x0divEgalC-20, y456c-15, button_length, 0					;
	line_horizontal	x0divEgalC-20, y456c-15 + button_length, button_length, 0	; formare zona C
	line_vertical x0divEgalC-20, y456c-15, button_length, 0						;
	line_vertical x0divEgalC-20 + button_length, y456c-15, button_length, 0		;
	
	line_horizontal x147plus-20, yplusMinusMulDiv -15, button_length, 0						;
	line_horizontal	x147plus-20, yplusMinusMulDiv -15 + button_length, button_length, 0		; formare zona +
	line_vertical x147plus-20, yplusMinusMulDiv -15, button_length, 0						;
	line_vertical x147plus-20 + button_length, yplusMinusMulDiv -15, button_length, 0		;
	
	line_horizontal x258minus-20, yplusMinusMulDiv -15, button_length, 0						;
	line_horizontal	x258minus-20, yplusMinusMulDiv -15 + button_length, button_length, 0		; formare zona -
	line_vertical x258minus-20, yplusMinusMulDiv -15, button_length, 0							;
	line_vertical x258minus-20 + button_length, yplusMinusMulDiv -15, button_length, 0			;
	
	line_horizontal x369mul-20, yplusMinusMulDiv -15, button_length, 0					;
	line_horizontal	x369mul-20, yplusMinusMulDiv -15 + button_length, button_length, 0	; formare zona *
	line_vertical x369mul-20, yplusMinusMulDiv -15, button_length, 0					;
	line_vertical x369mul-20 + button_length, yplusMinusMulDiv -15, button_length, 0	;
	
	line_horizontal x0divEgalC-20, yplusMinusMulDiv -15, button_length, 0					;
	line_horizontal	x0divEgalC-20, yplusMinusMulDiv -15 + button_length, button_length, 0	; formare zona /
	line_vertical x0divEgalC-20, yplusMinusMulDiv -15, button_length, 0						;
	line_vertical x0divEgalC-20 + button_length, yplusMinusMulDiv -15, button_length, 0		;
	
	line_horizontal x0divEgalC-20, y123egal-15, button_length, 0					;
	line_horizontal	x0divEgalC-20, y123egal-15 + button_length, button_length, 0	; formare zona =
	line_vertical x0divEgalC-20, y123egal-15, button_length, 0						;
	line_vertical x0divEgalC-20 + button_length, y123egal-15, button_length, 0		;
	
	line_horizontal 30, 30, 245, 0			;
	line_horizontal 30, 80, 245, 0			;formare screen
	line_vertical 30, 30, 50, 0				;
	line_vertical 30+245, 30, 50, 0			;
	
	line_horizontal 260, 100, 30, 0			;zona de stergere bucata cate bucata
	line_horizontal 260, 120, 30, 0			;
	line_vertical 290, 100, 20, 0			;
	linie_oblicaSt 260, 100 , 10, 0			;
	linie_oblicaDr 252, 110, 10, 0			;
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start

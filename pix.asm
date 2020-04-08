global modPix
global powPix
global sum1Pix
global sum2Pix
global pixPi
global pwPix

extern pixtime
global pix





section .text

; Computes { numerator / denominator }.
; %1 - numerator (64 bit)
; %2 - denominator (64 bit)
; rax - result (64 bit)
%macro divFractionalPart 2
	mov rax, %1
	; We'll now consider numerator a 128-bit value on rdx:rax
	mov rdx, rax ; numerator <<= 64 (*= 2 ^ 64)
	div %2
%endmacro


; Calculates value % modulus. 
; rdx:rax - value (128 bit) OR rax - value (64 bit) -
; - in the latter case, do "xor rdx, rdx" before using the function
; %1 - modulus (64 bit)
; rax - result (64 bit)
%macro modulo 1
	div %1
	mov rax, rdx
%endmacro


; Computes (value ^ power) % modulus. Uses the fast exponentiation algorithm.
; %1 - value (64 bit)
; %2 (rbx for convenience) - power (64 bit)
; %3 - modulus (64 bit)
; rax - result (64 bit)  - Auxiliarily we'll use rdx:rax (128 bit), but on return rdx will be discarded.
%macro power 3
	mov rbx, %2 ; power
	mov rax, 1 ; result = 1
	
%%powerLoop:
	cmp rbx, 0 ; if (power == 0) break
	je %%endPowerLoop
	
	test bl, 1 ; if (power is odd) {
	jne %%skipPowerIf
	mul %1 ; result (rdx:rax) = result * value
	modulo %3 ; result (rdx:rax) %= modulus }
%%skipPowerIf: 

	push rax ; store result temporarily
	mov rax, %1
	mul %1 ; value (now on rdx:rax) = value * value 
	modulo %3 ; value (rdx:rax) %= modulus
	mov %1, rax
	pop rax ; retrieve result
	
	shr rbx, 1 ; power /= 2
	jmp %%powerLoop
%%endPowerLoop:
%endmacro

; TEST: - floating point exception (core dumped)
powPix:
	push rbx
	power rdi, rsi, rdx
	pop rbx
	ret







































modPix:
    ; rdi - wartosc
    ; rsi - modulo

        ; TODO

        ret

sum1Pix:
; rdi - n
; rsi - j
        ; TODO

        ret

sum2Pix:
; rdi - n
; rsi - j
        ; TODO

        ret

pixPi:
; rdi - n

        ; TODO

        ret

; TODO do wyjebonexa
align 8
pwPix:
; rdi - wskaznik na tablice
; rsi - wskaznik na indeks
; rdx - wartosc max

        ; TODO

        ret


align 8 ; TODO: usun jak bedzie dzialac bez
pix:
	ret











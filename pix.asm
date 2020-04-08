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
%macro divFractional 2
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
	xor rdx, rdx
	
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


; Computes { value1 * value2 }, where value1 and value 2 are also fractional parts.
; %1 - value1 (64 bit)
; %2 - valu2 (64 bit)
; rax - result (64 bit)
%macro mulAllFractional 2
	mov rax, %1
	xor rdx, rdx
	; ??? czy na pewno tutaj 128 bit * 64 bit zadziala?? Ciolek ma 128 * 128; ale chyba powinno
	mul %2
	mov rax, rdx ; return the more significant part 
%endmacro


; Computes {16^n * pi} from the blue equation from the tutorial (see above).
; %1 - n (64 bit)
; rax - result (64 bit)
%macro nthPi 1
	computeSj 1, rdi ; S1
	mov r12, rax
	computeSj 4, rdi ; S4
	mov r13, rax
	computeSj 5, rdi ; S5
	mov r14, rax
	computeSj 6, rdi ; S6
	mov r15, rax
	
	; ??? Co tutaj z wychodzeniem ponizej zera i powyzej overflowa?
	xor rax, rax
	add rax, r12 ; += S1
	add rax, r12 ; += S1
	sub rax, r13 ; -= S4
	add rax, r12 ; += S1
	sub rax, r13 ; -= S4
	add rax, r12 ; += S1
	sub rax, r14 ; -= S5
	sub rax, r15 ; -= S6
%endmacro


; Computes {16^n * S_j} for the blue equation from the tutorial (see above).
; %1 - j (64 bit)
; %2 - n (64 bit)
; rax (rbp for convenience) - result (64 bit)
%macro computeSj 2
	push %2
	xor rbp, rbp ; result
	
	; first sum from the equation:
	xor r8, r8 ; k
	mov r11, %2 ; tmp (r11) := n - k
	sub r11, r8
	; for (k = 0; k <= n; ++k)
%%computeSjLoop1: 
	cmp r8, %2 ; if (k > n) break
	ja %%endComputeSjLoop1
	
	; denominator (r9) = 8 * k + j
	mov rax, r8 
	mul 8
	add rax, %1
	mov r9, rax
	
	; numerator (r10) = 16 ^ (n - k) % denominator
	power 16, r11, r9
	mov r10, rax
	
	divFractional r10, r9
	add rbp, rax ; result += { numerator / denominator }
	
	inc r8 ; ++k
	jmp %%computeSjLoop1
%%endComputeSjLoop1:
	
	; tmp (r11) := current power of 16
	divFractional 1, 16
	mov r11, rax
	
	; second sum from the equation:
	; k = n + 1
	mov r8, %2 
	inc r8 
%%computeSjLoop2: 

	; current term (r10)
	; denominator (r9) = 8 * k + j
	mov rax, r8 
	mul 8
	add rax, %1
	mov r9, rax
	
	mov rax, r11 ; numerator = current power of 16
	div r9
	mov r10, rax ; current term (r10) = numerator / denominator
	
	cmp r10, 0 ; if (current term == 0) break
	je endComputeSjLoop2
	
	add rbp, r10 ; result += current term
	
	; increment exponent of the power of 16
	divFractional 1, 16
	mov r9, rax
	mulAllFractional r11, r9 
	mov r11, rax
	
	inc r8 ; ++k
	jmp %%computeSjLoop2
%%endComputeSjLoop2
	
	
	pop %2
	mov rax, rbp
%endmacro
























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











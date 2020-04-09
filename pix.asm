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
	; We'll now consider numerator a 128-bit value on rdx:rax
	mov rdx, %1 ; numerator <<= 64 (*= 2 ^ 64)
	xor rax, rax
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
; %2 - power (64 bit)
; %3 - modulus (64 bit)
; rax - result (64 bit)  - Auxiliarily we'll use rdx:rax (128 bit), but on return rdx will be discarded.
%macro power 3
	mov rax, 1 ; result = 1
	
%%powerLoop:
	cmp %2, 0 ; if (power == 0) break
	je %%endPowerLoop
	
	test %2, 1 ; if (power is odd) {
	jz %%skipPowerIf
	mul %1 ; result (rdx:rax) = result * value
	modulo %3 ; result (rdx:rax) %= modulus }
%%skipPowerIf: 

	push rax ; store result temporarily
	mov rax, %1
	mul %1 ; value (now on rdx:rax) = value * value 
	modulo %3 ; value (rdx:rax) %= modulus
	mov %1, rax
	pop rax ; retrieve result
	
	shr %2, 1 ; power /= 2
	jmp %%powerLoop
	
%%endPowerLoop:
%endmacro


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
; rax (temporarily in r14) - result (64 bit)
%macro nthPi 1
	; ??? Co tutaj z wychodzeniem ponizej zera i powyzej overflowa?
	xor r14, r14 ; result = 0
	
	computeSj 1, %1 ; S1
	mov rbx, 4
	mul rbx
	add r14, rax ; result += 4 * S1
	
	computeSj 4, %1 ; S4
	mov rbx, 2
	mul rbx
	sub r14, rax ; result -= 2 * S4
	
	computeSj 5, %1 ; S5
	sub r14, rax ; result -= S6
	
	computeSj 6, %1 ; S6
	sub r14, rax ; result -= S6	
	
	mov rax, r14
%endmacro


; Computes the first sum from the equation for Sj (see above).
; %1 - j (64 bit)
; %2 - n (64 bit)
; rax (temporarily in r12) - result (64 bit)
%macro computeSum1 2
	xor r12, r12 ; result = 0
	
	xor r8, r8 ; k
	; for (k = 0; k <= n; ++k)
%%computeSum1Loop: 
	cmp r8, %2 ; if (k > n) break
	ja %%endComputeSum1Loop
	
	; denominator (r9) = 8 * k + j	
	xor rax, rax
	xor rdx, rdx
	mov rbx, 8
	mul rbx
	add rax, %1
	mov r9, rax
	
	; TODO - zmien / zastap tego ifa
	cmp r9, 2
	jb %%skipSum1If
	
	; tmp (r11) := n - k
	mov r11, %2
	sub r11, r8
	
	; numerator (r10) = 16 ^ (n - k) % denominator
	mov rbp, 16
	xor r10, r10
	power rbp, r11, r9
	mov r10, rax
	
	divFractional r10, r9
	add r12, rax ; result += { numerator / denominator }
%%skipSum1If:
	
	inc r8 ; ++k
	jmp %%computeSum1Loop
%%endComputeSum1Loop:
	
	mov rax, r12
%endmacro


; Computes the second sum from the equation for Sj (see above).
; %1 - j (64 bit)
; %2 - n (64 bit)
; rax (temporarily in r12) - result (64 bit)
%macro computeSum2 2
	xor r12, r12 ; result = 0
	
	; current power of 16 (r11)
	mov rbx, 16
	divFractional 1, rbx
	mov r11, rax
	
	; k = n + 1
	mov r8, %2 
	inc r8 
%%computeSum2Loop: 
	; denominator (r9) = 8 * k + j
	mov rax, r8 
	mov rbx, 8
	mul rbx
	add rax, %1
	mov r9, rax
	
	mov rax, r11 ; numerator = current power of 16
	xor rdx, rdx
	div r9
	mov r10, rax ; current term (r10) = numerator / denominator
	
	cmp r10, 0 ; if (current term == 0) break
	je %%endComputeSum2Loop
	
	add r12, r10 ; result += current term
	
	; increment the exponent of current power of 16
	mov rbx, 16
	divFractional 1, rbx
	mov r9, rax
	mulAllFractional r11, r9 
	mov r11, rax
	
	inc r8 ; ++k
	jmp %%computeSum2Loop
%%endComputeSum2Loop:
	
	mov rax, r12
%endmacro


; Computes {16^n * S_j} for the blue equation from the tutorial (see above).
; %1 - j (64 bit)
; %2 - n (64 bit)
; rax (temporarily in r13) - result (64 bit)
%macro computeSj 2
	computeSum1 %1, %2
	mov r13, rax ; result = sum1
	computeSum2 %1, %2
	add r13, rax ; result += sum2
	mov rax, r13
%endmacro


; Main function. Writes to the array.
; %1 - Pointer to the ppi array (32 bit*)
; %2 - Pointer to the pidx index (64 bit*)
; %3 - The max value (64 bit)
%macro mainPix 3
%%mainPixLoop:
	cmp [%2], %3 ; if (*pidx >= max) break
	jae %%endMainPixLoop
	
	mov rax, [%2]
	mov rbx, 8
	mul rbx
	mov r15, rax ; n
	nthPi r15 ; nthPi(8 * m)
	
	rsh rax, 32 ; result >>= 32
	mov r15, [%2]
	mov [%1 + r15], eax ; ppi[m] = result
	
	inc [%2]
%%endMainPixLoop:
%endmacro











powPix:
%ifdef COMMENT
	push r12
	mov r12, rdx
	power rdi, rsi, r12
	pop r12
%endif
	ret
	
	
modPix:
%ifdef COMMENT
	xor rdx, rdx
	mov rax, rdi
	modulo rsi
%endif
	ret
	
	
sum1Pix:
	push r12
	push rbp
	push rbx
	computeSum1 rsi, rdi
	pop rbx
	pop rbp
	pop r12
	ret
	
	
sum2Pix:
	push r12
	push rbp
	push rbx
	computeSum2 rsi, rdi
	pop rbx
	pop rbp
	pop r12
	ret
	
	
pixPi:
%ifdef COMMENT
	push r14
	push r13
	push r12
	push rbp
	push rbx
	nthPi rdi
	pop rbx
	pop rbp
	pop r12
	pop r13
	pop r14
%endif
	ret


; TODO - wyrzuc te funkcje
align 8
pwPix:
	ret
; rdi - wskaznik na tablice
; rsi - wskaznik na indeks
; rdx - wartosc max

align 8 ; TODO: usun jak bedzie dzialac bez
pix:
	ret











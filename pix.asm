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







; From the tutorial on how to use BBP Formula to calculate the nth pi digit:
; https://math.stackexchange.com/questions/880904/how-do-you-use-the-bbp-formula-to-calculate-the-nth-digit-of-%CF%80
; Computes the first sum (16 ^ (n-k) mod 8 k + j ...) in the last line of the tutorial.
; uint64_t sum1Pix(uint64_t n, uint64_t j)
; rdi - n
; rsi - j
; rax - result
sum1Pix:
	ret




; Computes the second sum (16 ^ (n-k) mod 8 k + j ...) in the last line of the tutorial (see above).
; uint64_t sum2Pix(uint64_t n, uint64_t j)
; rdi - n
; rsi - j
; rax - result
sum2Pix:
	ret

	



; Computes {16^n * S_j} for the blue equation from the tutorial (see above).
; %1 - j
; %2 - n
; %3 (temporarily in rax) - result
%macro computeSj 3
	push %2
	xor rax, rax ; We'll store the result here
	
	
	xor r8, r8 ; k
; for (k = 0; k <= n; ++k)
%%computeSjLoop: 
	cmp r8, %2 ; if (k == n) break
	je %%endComputeSjLoop
	
	
	jmp %%computeSjLoop
%%endComputeSjLoop:

	mov %3, rax
	pop %2
%endmacro



; Computes {16^n * pi} from the blue equation from the tutorial (see above).
; uint64_t pixPi(uint64_t n)
; rdi - n
; rax - result
pixPi:
	push r12
	push r13
	push r14
	push r15
	
	computeSj 1, rdi, r12 ; S1
	computeSj 4, rdi, r13 ; S4
	computeSj 5, rdi, r14 ; S5
	computeSj 6, rdi, r15 ; S6
	
	; ??? Co tutaj z wychodzeniem ponizej zera i powyzej overflowa?
	xor rax, rax
	add rax, r12 ; += S1
	add rax, r12 ; += S1
	sub rax, r13 ; -= S4
	sub rax, r13 ; -= S4
	add rax, r12 ; += S1
	add rax, r12 ; += S1
	sub rax, r14 ; -= S5
	sub rax, r15 ; -= S6
	
	pop r12
	pop r13
	pop r14
	pop r15
	ret



; TODO: usun 
; Checks correctness of using mutexes. You should increment the given index in the array,
; instead of writing there the target value.
; void pwPix(uint32_t *ppi, uint64_t *pidx, uint64_t max)
; rdi - pointer to the ppi array 
; rsi - pointer to the pidx index
; rdx - the max value
align 8
pwPix:
	ret



align 8 ; TODO: usun jak bedzie dzialac bez
pix:
	ret

















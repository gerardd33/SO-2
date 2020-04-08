global modPix
global powPix
global sum1Pix
global sum2Pix
global pixPi
global pwPix

extern pixtime
global pix



section .bss



section .text



; Computes value % modulus
; uint64_t modPix(uint64_t a, uint64_t mod)
; rdi - value
; rsi - modulus
; rax - result
modPix:
	mov rax, rdi
	xor rdx, rdx
	div rsi ; rax / rsi, result in rax, remainder in rdx
	mov rax, rdx
	ret

; Calculates %1 % %2. Result in rax.
%macro modulo 2
	push rdi
	push rsi
	
	mov rdi, %1
	mov rsi, %2
	call modPix
	
	pop rdi
	pop rsi
%endmacro


; Computes (value ^ power) % modulus. Uses the fast exponentiation algorithm.
; uint64_t powPix(uint64_t a, uint64_t pow, uint64_t mod)
; rdi - value
; rsi (moved to rbx) - power
; rdx - modulus
; rax - result
powPix:
%ifdef COMMENT
	push rbx
	mov rbx, rsi 
	
	mov rax, 1 ; result = 1
	
powLoop:
	cmp rbx, 0 ; if (power == 0) break
	je endPowLoop
	
	test bl, 1 ; if (power is odd) {
	jne skipPowIf
	; result = (result * value) % modulus }
	mul rdi ; result (rax) *= value 
	; The result of mul is stored in RDX:RAX
	modulo rax, rdx ; result %= modulus
skipPowIf:
	
	; value = (value * value) % modulus
	push rax
	mov rax, rdi
	mul rax
	modulo rax, rdx ; rax %= modulus
	mov rdi, rax ; We want the updated value back in rdi
	pop rax
	
	shr rbx, 1 ; power /= 2
	jmp powLoop
endPowLoop:
	
	modulo rax, rdx ; result %= modulus
	pop rbx
%endif
	ret


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
















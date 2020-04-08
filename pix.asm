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
	div rsi
	mov rax, rdx
	ret


; Computes (value ^ power) % modulus. Uses the fast exponentiation algorithm.
; uint64_t powPix(uint64_t a, uint64_t pow, uint64_t mod)
; rdi - value
; rsi - power
; rdx - modulus
; rax - result
powPix:
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



; Computes the second sum (16 ^ (n-k) mod 8 k + j ...) in the last line of the tutorial (as above).
; uint64_t sum2Pix(uint64_t n, uint64_t j)
; rdi - n
; rsi - j
; rax - result
sum2Pix:
	ret


; rdi - n
; rax - result
pixPi:
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
















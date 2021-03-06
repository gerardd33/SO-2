global pix
extern pixtime

section .text


; Calculates value % modulus. 
; rdx:rax - value (128 bit) OR rax - value (64 bit) -
; - in the latter case, do "xor edx, edx" before using the function
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

	push rax
	mov rax, %1
	mul %1 ; value (now on rdx:rax) = value * value 
	modulo %3 ; value (rdx:rax) %= modulus
	mov %1, rax
	pop rax
	
	shr %2, 1 ; power /= 2
	jmp %%powerLoop
	
%%endPowerLoop:
%endmacro


; Computes { numerator / denominator }.
; %1 - numerator (64 bit)
; %2 - denominator (64 bit)
; rax - result (64 bit)
%macro divFractional 2
	; we'll now consider numerator a 128-bit value on rdx:rax
	mov rdx, %1 ; numerator <<= 64 (*= 2 ^ 64)
	xor eax, eax
	div %2
%endmacro


; Computes { value1 * value2 }, where value1 and value 2 are also fractional parts.
; %1 - value1 (64 bit)
; %2 - value2 (64 bit)
; rax - result (64 bit)
%macro mulAllFractional 2
	mov rax, %1
	xor edx, edx
	mul %2
	mov rax, rdx ; return the more significant part 
%endmacro


; Most equations in the following code taken from: 
; https://math.stackexchange.com/questions/880904/how-do-you-use-the-bbp-formula-to-calculate-the-nth-digit-of-%CF%80 
; referred to as "the tutorial" below.

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
	mov rax, r8 
	mov rbx, 8
	mul rbx
	add rax, %1
	mov r9, rax
	
	cmp r9, 2 ; if (denominator <= 1) continue
	jb %%skipSum1If
	
	; tmp (r11) := n - k
	mov r11, %2
	sub r11, r8
	
	; numerator (r10) = 16 ^ (n - k) % denominator
	push rbp
	mov rbp, 16
	xor r10, r10
	power rbp, r11, r9
	mov r10, rax
	pop rbp
	
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
	xor edx, edx
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


; Computes {16^n * pi} from the blue equation from the tutorial (see above).
; %1 - n (64 bit)
; rax (temporarily in r14) - result (64 bit)
%macro nthPi 1
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


; Main function. Writes to the array.
; %1 - Pointer to the ppi array (32 bit*)
; %2 - Pointer to the pidx index (64 bit*)
; %3 - The max value (64 bit)
%macro mainPix 3
%%mainPixLoop:
	; increment the pidx pointer (atomic)
	mov rbx, 1
	lock xadd qword [%2], rbx 
	; the old value of *pidx is now in rbx, which we'll use from now on
	
	cmp rbx, %3 ; if (*pidx >= max) break
	jae %%endMainPixLoop
	
	; n = 8 * m
	mov rax, rbx
	mov r8, 8
	mul r8
	mov r15, rax ; n
	push rbx
	nthPi r15 ; nthPi(8 * m)
	pop rbx
	shr rax, 32 ; result >>= 32
	
	; write the computed value to the ppi array
	mov dword [%1 + 4 * rbx], eax ; ppi[m] = result
	jmp %%mainPixLoop
%%endMainPixLoop:
%endmacro


pix:
	push r15
	push r14
	push r13
	push r12
	push rbp
	push rbx
	push rdi
	push rsi
	push rdx
	
	; call pixtime - stack aligned
	rdtsc
	mov rdi, rax
	call pixtime
	
	pop rdx
	pop rsi
	pop rdi
	
	mov rbp, rdx
	mainPix rdi, rsi, rbp
	
	; call pixtime
	sub rsp, 8 ; aligning the stack
	rdtsc
	mov rdi, rax
	call pixtime
	add rsp, 8 ; aligning the stack
	
	pop rbx
	pop rbp
	pop r12
	pop r13
	pop r14
	pop r15
	ret

.data

; dispatch table for bytecodes
jmp_table:
	.quad _halt
	.quad _kdouble
	.quad _add
	; comparisons not= = < <=
	; .quad _islt
	; .quad _isle
	; .quad _iseq
	; .quad _isne

	; arith:
	; sub
	; mul
	; div
	; mod
	; pow
	; concat ; A = B ~ C

	; .quad _ist ; jmp if D is not false
	; .quad _isf ; jmp if D is false
	; .quad _mov ; mv D to A
	; .quad _not ; A = not D
	; .quad _unm ; A = -D
	; .quad call ; A(A[1],A[2],...,A[D])
	; .quad callt ; tail call A(A[1],A[2],...,A[D])
	; .quad ret ; return A

	; maybe:
	; .quad _len ; A = len(D)
	; .quad _istc ; mov D to A and jmp if not false
	; .quad _isfc ; mov D to A and jmp if false

; we'll use:
; - x19 as base of dispatch table
; - x20 as address of next instruction in bytecode array (IP/PC)
; - x21 as base of constant array
; - x0 is D
; - x22 is A
; - x23 is B
; - x24 is C
; - x25 is frame pointer

; coming into `startvm`
; arg1: x0 has byte code
.text
.macro load_next_bytecode
	ldr w0, [x20], #4	; Load next bytecode, and IP+4
	UBFX w1, w0, #0, #8	; w1 = opcode
	UBFX w22, w0, #8, #8	; w22 = A
	lsr w0, w0, #16		; w0 = D
	lsl w1, w1, #3		; w1 = opcode * 8
	add x1, x19, x1		; x1 = jmp_table + opcode * 8
	ldr x30, [x1]		; x30 = *x1
	br x30
.endm
.macro spill_registers
	stp x19, x20, [sp, #-16]!
	stp x21, x30, [sp, #-16]!
	stp x22, x23, [sp, #-16]!
	stp x24, x25, [sp, #-16]!
.endm
.macro slurp_registers
	ldp x24, x25, [sp], #16
	ldp x22, x23, [sp], #16
	ldp x21, x30, [sp], #16
	ldp x19, x20, [sp], #16
.endm
.macro decode_ABC
	UBFX w23, w0, #0, #8	; w23 = B
	UBFX w24, w0, #8, #8	; w24 = C
.endm
.macro decode_AD
.endm

.globl	_startvm
.p2align	2 ; align to 2^2=4 bytes
_startvm:
	spill_registers

	mov x20, x0 ; x20 = &bytecode_arr
	mov x21, x1 ; x21 = &constant_arr
	mov x25, x2 ; x25 = &frame

	; (3) x19 = &jmp_table
	adrp	x19, jmp_table@GOTPAGE
	ldr	x19, [x19, jmp_table@GOTPAGEOFF]

	load_next_bytecode
_kdouble:
	decode_AD ; x0 = D, x22 = A = dst

	lsl x0, x0, #3 ; x0 = D * 8
	add x0, x0, x21 ; x0 = constants_arr + D * 8
	ldr d0, [x0] ; d0 = *x0

	lsl x22, x22, #3 ; x22 = A * 8
	add x22, x22, x25 ; x22 = frame + A * 8
	str d0, [x22] ; frame[A*8] = d0

	load_next_bytecode
_add:
	decode_ABC ; x23 = B, x24 = C, x22 = A = dst
	
	lsl x23, x23, #3 ; x23 = B * 8
	add x23, x23, x25 ; x23 = frame + B * 8
	ldr d0, [x23]
	; TODO: need to check not quiet NaN

	lsl x24, x24, #3 ; x24 = C * 8
	add x24, x24, x25 ; x24 = frame + C * 8
	ldr d1, [x24]
	; TODO: need to check not quiet NaN

	fadd d0, d0, d1

	lsl x22, x22, #3 ; x22 = A * 8
	add x22, x22, x25 ; x22 = frame + A * 8
	str d0, [x22] ; frame[A*8] = d0

	load_next_bytecode
_halt:
	decode_AD ; x22 = A = src

	lsl x22, x22, #3 ; x22 = A * 8
	add x22, x22, x25 ; x22 = frame + A * 8
	ldr d0, [x22] ; d0 = frame[A*8]

	slurp_registers
	ret


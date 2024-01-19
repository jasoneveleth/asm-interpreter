.data

; use this to save x30
saved_x30:
    .quad 0

jmp_table:
	.quad _halt
	.quad _kdouble

; we'll use:
; - x0 as accumulator
; - x6 as base of dispatch table
; - x7 as index into bytecode array (IP/PC)

; coming into `startvm`
; arg1: x0 has byte code
.text
.globl	_startvm
.p2align	2 ; align to 2^2=4 bytes
_startvm:
	; (1) x7 = &bytecode_arr
	mov x7, x0

	; (2) x6 = &jmp_table
	adrp	x6, jmp_table@GOTPAGE
	ldr	x6, [x6, jmp_table@GOTPAGEOFF]

	; (3) save x30
	adrp	x0, saved_x30@GOTPAGE
	ldr	x0, [x0, saved_x30@GOTPAGEOFF]
	str	x30, [x0]

	; (4) load next bytecode
	ldr w0, [x7], #4	; Load next bytecode, and IP+4
	UBFX w1, w0, #0, #8	; w1 = opcode
	UBFX w2, w0, #9, #15	; w2 = A
	lsl w0, w0, #8		; w0 = D
	lsl w1, w1, #3		; w1 = opcode * 8
	add x1, x6, x1		; x1 = jmp_table + opcode * 8
	ldr x30, [x1]		; x30 = jmp_table[opcode * 8]
	br x30
_kdouble:
	
_halt:
	; load x30
	adrp	x30, saved_x30@GOTPAGE
	ldr	x30, [x30, saved_x30@GOTPAGEOFF]
	ldr	x30, [x30]
	; end load
; REMOVE:
	mov x0, #15
	ret


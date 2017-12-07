extern printf
section .text
global dbl2str
default rel
 
dbl2str:
;prologue
	push rbx
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
 ;int3
	mov [point2dbl], ecx 
	mov rax, [rcx] ;pointer
	mov r10, rax
	shl r10, 1 ; - NAN check - avoiding sign
	mov r11,0xFFE0000000000000
	cmp r10, r11;
	ja nanch
	jna negch
nanch:;writing "nan\0"
	mov byte[rdx], 6Eh
	mov byte[rdx+1], 61h
	mov byte[rdx+2], 6Eh
	mov byte[rdx+3], 0h
	jmp pops
negch:;check sign
	mov r10, 0x8000000000000000
	test rax, r10
	jnz minuch
pluch:;writing "+"
	mov byte[rdx], 2Bh
	jmp beforeinfch
minuch:;writing "-"
	mov byte[rdx], 2Dh
	mov r10, 0x8000000000000000
	xor rax, r10
beforeinfch:
	lea r11, byte[rdx+1]; r11 now is a pointer to position after sign in string
	mov r10 ,0x7FF0000000000000
	cmp rax, r10
	jne beforezeroch
infch:;writing "inf/0"
	mov byte[r11], 69h
	mov byte[r11+1], 6Eh
	mov byte[r11+2], 66h
	mov byte[r11+3], 0h
	jmp pops
beforezeroch:;writing "0."
	mov byte[r11], 30h
	mov byte[r11+1], 2Eh
	test rax, rax
	jnz beforegrisu
zeroch:
	mov byte[r11+2], 30h
	mov byte[r11+3], 0h
	jmp pops
beforegrisu:
	lea rbx, byte[r11+2]
	mov r11, rbx; ; r11 now is a pointer to position of "_" in "s0._"

;Nu hebben wij RAX met unsigned value van ons double en r11 van pointer ann buffer
;horaay
 
grisu:
	nop
pops:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret
section .data
	pow10cache: dd 0, 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000
	format:     db "abacaba %lld", 10, 0
	len:        dq 0
	K:			dq 0
	Mplusf:		dq 0
	Mpluse:		dq 0
	point2dbl:	dq 0
	buffer:		dq 0


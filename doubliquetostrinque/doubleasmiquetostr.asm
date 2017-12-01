extern printf
section .text
global dbl2str
default rel
 
dbl2str:
 ;int3
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
 ret
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
 ret
beforezeroch:;writing "0."
 mov byte[r11], 30h
 mov byte[r11+1], 2Eh
 test rax, rax
 jnz beforegrisu
zeroch:
 mov byte[r11+2], 30h
 mov byte[r11+3], 0h
 ret
beforegrisu:
 push rbx
 lea rbx, byte[r11+2]
 mov r11, rbx; ; r11 now is a pointer to position of "_" in "s0._"
 pop rbx

;and now we have RAX with unsigned value of our double and r11 as pointer to buffer
;horaay
 
grisu:
 nop 
 nop
 nop
 ret

section .rdata
 pow10cache: dd 0, 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000



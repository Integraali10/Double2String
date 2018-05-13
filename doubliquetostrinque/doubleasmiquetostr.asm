global dbl2str
default rel
section .text
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
	sub rsp, 28h
	mov rax, [rcx] ;pointer
	lea rcx, [dbl]
	mov [rcx], rax
	lea rcx, [pointertodbl]
	mov [rcx], rdx
	;int3
	mov r8, rax;
	mov r10, rax
	shl r10, 1 ; - NAN check - avoiding sign
	mov r12,0xFFE0000000000000
	cmp r10, r12;
	ja nanch
	jna negch

nanch:;writing "NaN\0"
	mov byte[rdx], 4Eh
	mov byte[rdx+1], 61h
	mov byte[rdx+2], 4Eh
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
	xor rax, r10
beforeinfch:
	lea r11, byte[rdx+1]; r11 now is a pointer to position after sign in string
	mov r10 ,0x7FF0000000000000
	cmp rax, r10
	jne beforezeroch
infch:;writing "Inf/0"
	mov byte[r11], 49h
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
	lea rcx, [pointtochar]
	mov [rcx], rbx; pointer to position of "_" in "s0._"
grisu:
;int3;
	
	;FP van ons double 
	mov rax, r8; f.frac
	mov rcx, 000FFFFFFFFFFFFFh
	and r8, rcx
	mov r9, rax;f.exp
	mov rcx, 7FF0000000000000h
	and r9, rcx
	shr r9,34h;>>52
	mov r12d, 1075
	test r9d, r9d
	jz exbi
	mov rcx, 0010000000000000h
	add r8, rcx
	sub r9d, r12d
	jmp borderspls
exbi:
	neg r12d
	inc r12d
	mov r9d, r12d
borderspls:
	;r12 und r13 for upper b frac und exp
	;r14 und r15 for lower b frac und exp
	mov r12, r8
	lea r12,[r12+r12+1]; shl r12, 1; inc r12
	mov r13d, r9d
	dec r13d

	mov r10, 0010000000000000h
	shl r10, 1
upcicle:
	test r12, r10
	jnz upshift
	shl r12, 1
	dec r13d
	jmp upcicle
upshift:   
	shl r12, 10
	sub r13d, 10
	mov r14, r8
	mov r15d, r9d
	shr r10, 1
	cmp r8, r10
	je lshift2
lshift1:
	lea r14, [r14+r14-1]
	dec r15d;
	jmp lbound
lshift2:
	shl r14, 2
	dec r14
	sub r15d, 2;
lbound:
	mov eax, r15d;
	sub eax, r13d
	movzx ecx, al
	shl r14, cl;
	mov r15d, r13d;
;normalise f
	;;r10 = 0010000000000000h
	
	;int3;
normcicle:
	test r8, r10
	jnz normshift
	shl r8, 1
	dec r9d
	jmp normcicle
normshift:
	shl r8, 11
	sub r9d, 11
	mov ebx, r13d
;CASH POWER!
	lea rcx, [log10]
	movsd xmm0, [rcx]
	add ebx, 87
	neg ebx
	cvtsi2sd xmm1, ebx
	mulsd xmm0, xmm1
	cvttsd2si ebx, xmm0
	add ebx, 348
	sar ebx, 3
pow10cicle:
	lea rcx, [pow_ten_exp]
	mov ecx, [rcx+rbx*4]
	lea r11d, [r13+rcx+64]
	cmp r11d, 0FFFFFFC4h ;-60
	jge emax
	inc ebx
	jmp pow10cicle
emax:
	cmp r11d, 0FFFFFFE0h ;-32
	jle kvalue
	dec ebx
	jmp pow10cicle
kvalue:
	lea ebp, [rbx*8-348]
	neg ebp

;int3
	;cp value
	lea rcx,  [pow_ten_frac]
	mov r10,  [rcx+rbx*8]
	lea rcx,  [pow_ten_exp]
	mov r11d, [rcx+rbx*4]

	 ;;convention was defeated by incompetency	
	mov rcx, r8
	mov edx, r9d
	mov r8, r10
	mov r9d, r11d
	;;f * cp
	call multiply
tomem4:
	lea rax, [ffrac]
	mov [rax], rcx

	mov rcx, r12
	mov edx, r13d
	;;u * cp
	call multiply
tomem5:
	dec rcx
	mov r12, rcx
	mov r13d, edx;; upper frac und exp

	mov rcx, r14
	mov edx, r15d
	;;l * cp
	call multiply
tomem6:
	inc rcx
	mov r14, rcx
	mov r15d, edx;; lower frac und exp
	
	;add rsp, 28h will happen soon

	;;generatenums
	lea rax, [ffrac]
	mov r10, [rax]

	mov rax, r12
	sub rax, r10 ; wfrac
	lea rcx, [wfrac]
	mov [rcx], rax

	mov rbx, r12
	sub rbx, r14 ; delta
	lea rcx, [delta]
	mov [rcx], rbx
	
	mov ecx, r13d
	neg ecx
	mov r8, 1 
	shl r8, cl
	mov r11, r8
	xchg r11, r12

	mov r9d, r13d

	neg r9d
	mov ecx, r9d
	mov r9, r11
	shr r9, cl
	mov r13d, ecx

	dec r8
	and r8, r11
	;;free registers rdx (kind of -_-)
	;;r15 tmp
	;;r8 = part2
	;;r9 = part1
	;;r14 -> pow10cash
	;;ebx = kappa
	;;r12 und r13 for one.frac und -one.exp
	;;rax = digit 
	;;rcx using for adress
	;;r10 = idx
	;;r11 = ; pointer to position of "_" in "s0._"
	lea rcx, [pointtochar]
	mov r11, [rcx] 
	mov ebx, 10; kappa
	xor r10d, r10d; idx
	lea r14, [pow10cache]
	add r14, 80 ; 
	jmp conkappa
kappacicle:
	add r14, 8
conkappa:
	test ebx, ebx
	jle afterkc
	;;begin 
	mov rax, r9
	mov rcx, [r14]
	xor rdx, rdx
	div rcx 
	test eax, eax
	jne yepdig0
	test r10d, r10d
	je nopdig0
yepdig0:
	inc r10d
	mov rdx, rax
	add edx, 30h; "0"
	mov byte[r11], dl
	inc r11
nopdig0:
	imul rax, [r14]
	sub r9, rax
	dec ebx
	mov r15, r9
	mov ecx, r13d
	shl r15, cl
	add r15, r8
;int3	
	lea rcx, [delta]
	mov rcx, [rcx]
	cmp r15, rcx 
	ja kappacicle
	;; rax , rbx, r14, rdx and others will be inessential there
	add ebp, ebx
	;;;; args = rcx = wfrac, rdx = ptrtochar, r8 = tmp, r9 = delta, rsp -> kappa
	mov rax, [r14]
	mov ecx, r13d
	shl rax, cl
	push rax
	dec r11
	lea rcx, [wfrac]
	mov rcx, [rcx]
	mov rdx, r11
	lea r9, [delta]
	mov r9, [r9]
	mov r8, r15; tmp
	;;;;call roundigit
	call roundnd
	inc r11
	pop rax
	;;;; args
	jmp afterall
afterkc:	
	lea r14, [pow10cache]
	add r14, 144
	lea r15, [delta]
	mov r15, [r15]
seccicle:
	imul r8, 10 ; part2
	imul r15, 10 ; delta
	dec ebx ; kappa
	mov ecx, r13d
	mov rax, r8
	shr rax, cl
	test eax, eax
	jne yepdig1
	test r10d, r10d
	je nopdig1
yepdig1:
	inc r10d
	add eax, 30h; "0"
	mov byte[r11], al
	inc r11
nopdig1:
	dec r12
	and r8, r12
	inc r12
	cmp r8, r15 
	jae endseccicle
	;; rax , rbx, r14, rdx and others will be inessential
	add ebp, ebx
	;;;; args = rcx = wfrac * [unit], rdx = ptrtochar, r8 = part2, r9 = delta, rsp -> kappa
	lea rcx, [wfrac]
	mov rcx,[rcx]
	mov rax, [r14]
	imul rcx, rax
	push r12
	dec r11
	mov rdx, r11
	;;r8  = part 2
	mov r9, r15 ; delta
	;;;;call roundigit
	call roundnd
	inc r11
	pop rax
	;;;; args
	jmp afterall
endseccicle:
	sub r14, 8
	jmp seccicle

afterall:;;emit exp
;int3
	mov r8d, r10d
	add r8d, ebp
	mov ebx, r8d 
	neg r8d
	cmovl r8d, ebx ; exp
	xor r9, r9
	mov byte[r11], 65h
	inc r11
	test ebx, ebx
	jge yepsign
nopsign:
	mov byte[r11], 2dh
	inc r11
	jmp cent
yepsign:
	mov byte[r11], 2bh
	inc r11
cent:
	xor rdx, rdx
	cmp r8d, 63h 
	jle deca
	mov eax, r8d
	mov ecx, 100
	idiv ecx
	mov r9d, eax
	add eax, 30h
	mov byte[r11], al
	sub eax, 30h
	inc r11
	imul eax, 100
	sub r8d, eax
deca:
    xor rdx, rdx
	cmp r8d, 9 
	jle zerociph
	xor r9, r9
	mov eax, r8d
	mov ecx, 10
	idiv ecx
	add eax, 30h
	mov byte[r11], al
	sub eax, 30h
	inc r11
	imul eax, 10
	sub r8d, eax
zerociph:
	test r9d,r9d
	jz ciph
	mov byte[r11], 30h
	inc r11
ciph:
	xor rdx,rdx
	mov eax, r8d
	idiv ecx
	add edx, 30h
	mov byte[r11], dl
	mov byte[r11+1], 0h
	lea rcx, [pointertodbl]
	mov rdx, [rcx]
pops:
	add rsp, 28h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret

roundnd:
	mov rax, [rsp+8] ; kappa
	push rbx
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
while:
	cmp r8, rcx
	jae letsgo
	mov rbx, r9
	sub rbx, r8
	cmp rbx, rax
	jb letsgo 
	mov rbx, r8
	add rbx, rax
	cmp rbx, rcx
	jb action
	mov rbx, rcx
	sub rbx, r8
	mov r15, r8
	add r15, rax
	sub r15, rcx
	cmp rbx, r15
	jbe letsgo
action:
	dec byte[rdx]
	add r8, rax
	jmp while
letsgo:
	pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
	ret

multiply:
    push r12
    push r13
    push r14
    push r15
	;result exp
	add edx, r9d
	add edx, 64

	mov r10, 0x00000000FFFFFFFF

	mov r15, rcx
	mov r14, rcx
	mov r13, r8
	mov r12, r8
	shr r15, 20h
	shr r13, 20h
	and r14, r10
	and r12, r10

	mov r11, r15
	;ah_bl = r15
	imul r15, r12
	;ah_bh = r11
	imul r11, r13
	;al_bl = r12
	imul r12, r14
	shr r12, 20h
	;al_bh = r14
	imul r14, r13
	
	;tmp = + 1U << 31+ (al_bl >> 32) +(al_bh & lomask) +(ah_bl & lomask)  
	mov r13, 80000000h
	add r13, r12
	mov rax, r14
	and rax, r10
	add r13, rax
	and r10, r15
	add r13, r10

	;result frac
	mov rcx, r11 ;ah_bh + (ah_bl >> 32) + (al_bh >> 32) + (tmp >> 32)
	shr r15, 20h
	shr r14, 20h
	shr r13, 20h
	add rcx, r15
	add rcx, r14
	add rcx, r13

	pop r15
    pop r14
    pop r13
    pop r12
	ret

section .bss
	dbl: resq 1
	pointtochar: resq 1
	pointertodbl: resq 1
	ffrac: resq 1
	wfrac: resq 1
	delta: resq 1

section .data
	log10:        dq   3.0102999566398114e-1
	pow10cache:   dq   10000000000000000000, 1000000000000000000, 100000000000000000,
				  dq   10000000000000000, 1000000000000000, 100000000000000,
				  dq   10000000000000, 1000000000000, 100000000000,
				  dq   10000000000, 1000000000, 100000000,
				  dq   10000000, 1000000, 100000,
				  dq   10000, 1000, 100,
				  dq   10, 1
    pow_ten_frac: dq   18054884314459144840, 13451937075301367670, 10022474136428063862, 14934650266808366570, 11127181549972568877, 16580792590934885855,
				  dq   12353653155963782858, 18408377700990114895, 13715310171984221708, 10218702384817765436, 15227053142812498563, 11345038669416679861,
				  dq   16905424996341287883, 12595523146049147757,  9384396036005875287, 13983839803942852151, 10418772551374772303, 15525180923007089351,
				  dq   11567161174868858868, 17236413322193710309, 12842128665889583758,  9568131466127621947, 14257626930069360058, 10622759856335341974,
				  dq   15829145694278690180, 11793632577567316726, 17573882009934360870, 13093562431584567480,  9755464219737475723, 14536774485912137811,
				  dq   10830740992659433045, 16139061738043178685, 12024538023802026127, 17917957937422433684, 13349918974505688015,  9946464728195732843, 
				  dq   14821387422376473014, 11042794154864902060, 16455045573212060422, 12259964326927110867, 18268770466636286478, 13611294676837538539,
				  dq   10141204801825835212, 15111572745182864684, 11258999068426240000, 16777216000000000000, 12500000000000000000,  9313225746154785156, 
				  dq   13877787807814456755, 10339757656912845936, 15407439555097886824, 11479437019748901445, 17105694144590052135, 12744735289059618216,
				  dq    9495567745759798747, 14149498560666738074, 10542197943230523224, 15709099088952724970, 11704190886730495818, 17440603504673385349,
				  dq   12994262207056124023,  9681479787123295682, 14426529090290212157, 10748601772107342003, 16016664761464807395, 11933345169920330789,
				  dq   17782069995880619868, 13248674568444952270,  9871031767461413346, 14708983551653345445, 10959046745042015199, 16330252207878254650,
				  dq   12166986024289022870, 18130221999122236476, 13508068024458167312, 10064294952495520794, 14996968138956309548, 11173611982879273257,
				  dq   16649979327439178909, 12405201291620119593,  9242595204427927429, 13772540099066387757, 10261342003245940623, 15290591125556738113,
				  dq   11392378155556871081, 16975966327722178521, 12648080533535911531
	pow_ten_exp:  dd  -1220 , -1193 , -1166 , -1140 , -1113 , -1087 ,
				  dd  -1060 , -1034 , -1007 , -980  ,  -954 ,  -927 ,
				  dd  -901  , -874  , -847  , -821  ,  -794 ,  -768 ,
				  dd  -741  , -715  , -688  , -661  ,  -635 ,  -608 ,
				  dd  -582  , -555  , -529  , -502  ,  -475 ,  -449 ,
				  dd  -422  , -396  , -369  , -343  ,  -316 ,  -289 ,
			 	  dd  -263  , -236  , -210  , -183  ,  -157 ,  -130 ,
				  dd  -103  , -77   , -50   ,  -24  ,   3   ,   30  ,
				  dd   56   ,  83   ,  109  ,  136  ,   162 ,  189  ,
				  dd   216  ,  242  ,  269  ,  295  ,   322 ,  348  ,
				  dd   375  ,  402  ,  428  ,  455  ,   481 ,  508  ,
				  dd   534  ,  561  ,  588  ,  614  ,   641 ,  667  ,
				  dd   694  ,  720  ,  747  ,  774  ,   800 ,  827  ,
				  dd   853  ,  880  ,  907  ,  933  ,   960 ,  986  ,
				  dd   1013 ,  1039 ,  1066 


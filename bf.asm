; brainfuck interperter, nested loops might not work
; Ran Durbach 21.8.2025
; r12, r13, r14, r15, rbx, rbp, and rsp don't get changed after a syscall
; rbp - address of code
; r12b - current command
; r13 - index in array
global _start

section	.data
	array:	db 100	dup(0)
	code:	db	">++++++++[<+++++++++>-]<.>++++[<+++++++>-]<+.+++++++..+++.>>++++++[<+++++++>-]<++.------------.>++++++[<+++++++++>-]<+.<.+++.------.--------.>>>++++[<++++++++>-]<+.", 0
	codelen:	equ $ - code
	
	bnd_err_msg: db	"Error: out of bounds.\n"
	bnd_err_msg_len:	equ $ - bnd_err_msg
	unclosed_loop_err_msg: db	"Error: unclosed loop.\n"
	unclosed_loop_err_msg_len:	equ $ - unclosed_loop_err_msg
section	.text

_start:
	lea rbp, code	; load address of code to rbp
	mov r13, 0	; index in array
	dec rbp
	
	exe_com:
	
	inc rbp
	mov r12b, byte [rbp]	; r12b = command
	
	cmp r12b, 0		; input has ended
	mov r15, 0		; exit status 0
	je exit
	
	cmp r12b, 43		; increment? +
	jne not_inc
	
	mov al, [array + r13]
	inc al
	mov [array+r13], al
	
	jmp exe_com
	not_inc:
	cmp r12b, 45		; decrement? -
	jne not_dec
	
	mov al, [array + r13]
	dec al
	mov [array+r13], al
	
	jmp exe_com
	not_dec:
	cmp r12b, 62		; right? >
	jne not_right
	
	inc r13
	cmp r13, 100
	je bound_err
	
	jmp exe_com
	not_right:
	cmp r12b, 60		; left? <
	jne not_left
	
	dec r13
	cmp r13, -1
	je bound_err
	
	jmp exe_com
	not_left:
	cmp r12b, 46		; print? .
	jne not_print
	
	
	mov rax, 1	; sys_write
	mov rdi, 1	; stdout
	lea rsi, [array + r13]
	mov rdx, 1
	syscall
	
	jmp exe_com
	not_print:
	cmp r12b, 44		; input? ,
	jne not_input
	
	mov rax, 0	; sys_read
	mov rdi, 0	; stdin
	lea rsi, [array + r13]
	mov rdx, 1
	syscall
	
	jmp exe_com
	not_input:
	cmp r12b, 91		; start loop? [
	jne not_srt_loop
	
	mov al, [array+r13]	; cell val
	cmp al, 0		; if the cell value is not 0 start the loop, else skip it

	jne start_loop
	loop:
		inc rbp
		mov r12b, byte [rbp]
		
		
		cmp r12b, 0	; input has ended
		je loop_err	; unclosed loop error
		
		cmp r12b, 93	; input is ]
		je exe_com	; loop skipped
		
	jmp loop
	
	start_loop:
	push rbp
	
	jmp exe_com
	not_srt_loop:
	
	cmp r12b, 93		; end loop? ]
	jne not_end_loop
	; if pointer is non 0 then jump back to the command after [
	mov al, [array+r13]
	cmp al, 0
	je after_loop
	; still inside the loop
	pop rbp
	push rbp
	jmp exe_com
	after_loop:
	
	jmp exe_com
	not_end_loop:
	
	jmp exe_com
	
	exit:
	mov rax, 60	; sys_exit
	mov rdi, r15	; exit code 0
	syscall
	
	


bound_err:

	mov rax, 1	; sys_write
	mov rdi, 1	; stdout
	mov rsi, bnd_err_msg
	mov rdx, bnd_err_msg_len
	syscall

	mov r15, 1	; exit status 1
	jmp exit
	
loop_err:
	mov rax, 1	; sys_write
	mov rdi, 1	; stdout
	mov rsi, unclosed_loop_err_msg
	mov rdx, unclosed_loop_err_msg_len
	syscall

	mov r15, 1	; exit status 1
	jmp exit

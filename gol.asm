
; Ran Durbach 24.8.2025
; r12, r13, r14, r15, rbx, rbp, and rsp don't get changed after a syscall or function call
global _start

section	.data
	ts:
	    dq 0	; tv_sec = 1 second
	    dq 250000000	; tv_nsec = 0 nanoseconds


	one equ 88	; 'X'
	zero equ 32	; ' '
	
	
	size equ 400
	line_size equ 20
	
	grid:	times size db 0	; grid
	next_grid: times size db 0 ; next grid
	

section	.text


_start:
	xor r12, r12  ; time
	
	call zero_grid
	call zero_next_grid
	mov byte [grid + 209], one
	mov byte [grid + 210], one
	mov byte [grid + 211], one
	mov byte [grid + 212], one
	mov byte [grid + 230], one
	mov byte [grid + 233], one
	mov byte [grid + 190], one
	mov byte [grid + 192], one
	
	
	sim_loop:
		call print_grid
		call update
		
		mov rax, 35          ; syscall: nanosleep
		lea rdi, [rel ts]    ; &ts
		xor rsi, rsi         ; NULL
		syscall
		inc r12 ; increment time
	
	
	jmp sim_loop
	
	exit:
	mov rax, 60	; sys_exit
	mov rdi, 0	; exit code 0
	syscall
	
update:
	
	xor r13, r13 ; index = 0
	dec r13
	
	iter_grid:
		inc r13
		cmp r13, size ; if r13 == size, end
		je end_inter_grid
		xor rbp, rbp ; clear out neighbour counter
		xor rbx, rbx
		
		call check_right
		add rbx, rbp
		
		call check_left
		add rbx, rbp
		
		call check_top
		add rbx, rbp
		
		call check_bottom
		add rbx, rbp
		
		call check_top_right
		add rbx, rbp
		
		call check_top_left
		add rbx, rbp
		
		call check_bottom_right
		add rbx, rbp
		
		call check_bottom_left
		add rbx, rbp

		
		
		mov r14b, [grid + r13]
		cmp r14b, zero ; if the cell is dead
		je cell_dead ; jump to cell dead
		; cell_alive
		
		cmp rbx, 2 ; if living neighbours < 2
		jnl skip_1st_rule
		mov byte [next_grid + r13], zero ; make the cell dead
		jmp iter_grid
		
		skip_1st_rule:
		je cell_still_alive; if living neighbours = 2, the cell stays alive
		cmp rbx, 3 ; if living '' = 3, the cell stays  alive
		je cell_still_alive
	
		; here the cell has more than 3 living neighbours, kill it
		
		mov byte [next_grid + r13], zero ; make the cell dead
		
		jmp iter_grid
		cell_still_alive:
		mov byte [next_grid + r13], one ; make the cell alive
		jmp iter_grid
		
		cell_dead:		; check 4th rule
		
		cmp rbx, 3 ; if there are 3 living neighbours, make the cell alive
		jne skip_4th_rule
		mov byte [next_grid + r13], one ; make the cell alive
		jmp iter_grid
		skip_4th_rule:
		mov byte [next_grid + r13], zero
		
		jmp iter_grid
	
	end_inter_grid:
	
	; copy next_grid to grid
	
	mov rax, 0
	copy_grid_loop:
		
		mov bpl, [next_grid + rax]
		mov byte [grid + rax], bpl
		
		inc rax
		cmp rax, size
		jne copy_grid_loop
	ret
		
	ret
	
print_grid:
	mov r14, 0
	
	print_line:
	mov rax, 1	; sys_write
	mov rdi, 1	; stdout
	lea rsi, grid
	add rsi, r14
	mov rdx, line_size
	syscall
	
	add r14, line_size
	
	push 10
	mov rax, 1	; sys_write
	mov rdi, 1	; stdout
	mov rsi, rsp
	mov rdx, 1
	syscall
	
	pop rax
	cmp r14, size
	jne print_line
	
	end_print_grid:
	
	push 10 ; one more newline
	mov rax, 1	; sys_write
	mov rdi, 1	; stdout
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop rax
	
	ret
	
zero_grid:
	mov rax, 0
	zero_grid_loop:
	
		mov byte [grid + rax], zero
		
		inc rax
		cmp rax, size
		jne zero_grid_loop
	ret
	
zero_next_grid:
	mov rax, 0
	zero_next_grid_loop:
	
		mov byte [next_grid + rax], zero
		
		inc rax
		cmp rax, size
		jne zero_next_grid_loop
	ret

; if right neighbour is alive: rbp = 1, else 0.  the index is r13			
check_right:
		xor rbp, rbp

		mov rax, r13 ; bottom bytes
		inc rax
		xor rdx, rdx ; top bytes
		mov rcx, line_size
		div rcx
		test rdx, rdx
		jz right_dead ; if (r13+1) % line_size = 0 then we are on the right, there is not right neighbour



		mov r14b, [grid + r13 + 1] ; right cell       ---need to add edge detection
		cmp r14b, one
		jne right_dead ; right neighbor alive
		mov rbp, 1
		right_dead: ; right neighbor dead
		ret
		
; if left neighbour is alive: rbp = 1, else 0.  the index is r13			
check_left:
		xor rbp, rbp
		
		mov rax, r13 ; bottom bytes
		xor rdx, rdx ; top bytes
		mov rcx, line_size
		div rcx
		test rdx, rdx
		jz left_dead ; if r13 % line_size = 0 then we are on the left, there is not left neighbour


		mov r14b, [grid + r13 - 1] ; left cell       ---need to add edge detection
		cmp r14b, one
		jne left_dead ; left neighbor alive
		mov rbp, 1
		left_dead: ; left neighbor dead
		ret
		
; if top neighbour is alive: rbp = 1, else 0.  the index is r13			
check_top:
		xor rbp, rbp

		cmp r13, line_size ; if r13 < line_size we are at the top, there is no top neighbor
		jl top_dead

		mov r14b, [grid + r13 - line_size] ; top cell       ---need to add edge detection
		cmp r14b, one
		jne top_dead ; top neighbor alive
		mov rbp, 1
		top_dead: ; top neighbor dead
		ret
		

; if bottom neighbour is alive: rbp = 1, else 0.  the index is r13			
check_bottom:
		xor rbp, rbp

		mov rax, size
		sub rax, line_size
		cmp r13, rax ; if r13 > size - line_size we are at the bottom, there is no bottom neighbor
		jge bottom_dead

		mov r14b, [grid + r13 + line_size] ; bottom cell       ---need to add edge detection
		cmp r14b, one
		jne bottom_dead ; bottom neighbor alive
		mov rbp, 1
		bottom_dead: ; bottom neighbor dead
		ret
		
; if top_left neighbour is alive: rbp = 1, else 0.  the index is r13			
check_top_left:

		cmp r13, line_size ; if r13 < line_size we are at the top, there is no top-left neighbor
		jl top_left_dead

		mov rax, r13 ; bottom bytes
		xor rdx, rdx ; top bytes
		mov rcx, line_size
		div rcx
		test rdx, rdx
		jz top_left_dead ; if r13 % line_size = 0 then we are on the left, there is no top-left neighbour


		xor rbp, rbp
		mov r14b, [grid + r13 - line_size - 1] ; top_left cell       ---need to add edge detection
		cmp r14b, one
		jne top_left_dead ; top_left neighbor alive
		mov rbp, 1
		top_left_dead: ; top_left neighbor dead
		ret

; if top_right neighbour is alive: rbp = 1, else 0.  the index is r13			
check_top_right:

		xor rbp, rbp

		cmp r13, line_size ; if r13 < line_size we are at the top, there is no top-right neighbor
		jl top_right_dead

		mov rax, r13 ; bottom bytes
		inc rax
		xor rdx, rdx ; top bytes
		mov rcx, line_size
		div rcx
		test rdx, rdx
		jz top_right_dead ; if (r13+1) % line_size = 0 then we are on the right, there is no top-right neighbour


		mov r14b, [grid + r13 - line_size + 1] ; top_right cell       ---need to add edge detection
		cmp r14b, one
		jne top_right_dead ; top_right neighbor alive
		mov rbp, 1
		top_right_dead: ; top_right neighbor dead
		ret

; if bottom_right neighbour is alive: rbp = 1, else 0.  the index is r13			
check_bottom_right:


		xor rbp, rbp

		mov rax, size
		sub rax, line_size
		cmp r13, rax ; if r13 > size - line_size we are at the bottom, there is no bottom neighbor
		jge bottom_right_dead

		mov rax, r13 ; bottom bytes
		inc rax
		xor rdx, rdx ; top bytes
		mov rcx, line_size
		div rcx
		test rdx, rdx
		jz bottom_right_dead ; if (r13+1) % line_size = 0 then we are on the right, there is no bottom-right neighbour


		mov r14b, [grid + r13 + line_size + 1] ; bottom_right cell       ---need to add edge detection
		cmp r14b, one
		jne bottom_right_dead ; top_right neighbor alive
		mov rbp, 1
		bottom_right_dead: ; top_right neighbor dead
		ret

; if bottom_left neighbour is alive: rbp = 1, else 0.  the index is r13			
check_bottom_left:

		xor rbp, rbp

		mov rax, size
		sub rax, line_size
		cmp r13, rax ; if r13 > size - line_size we are at the bottom, there is no bottom-left neighbor
		jge bottom_left_dead

		mov rax, r13 ; bottom bytes
		xor rdx, rdx ; top bytes
		mov rcx, line_size
		div rcx
		test rdx, rdx
		jz bottom_left_dead ; if r13 % line_size = 0 then we are on the left, there is no bottom-left neighbour

		
		mov r14b, [grid + r13 + line_size -1] ; bottom_right cell       ---need to add edge detection
		cmp r14b, one
		jne bottom_left_dead ; top_right neighbor alive
		mov rbp, 1
		bottom_left_dead: ; top_right neighbor dead
		ret

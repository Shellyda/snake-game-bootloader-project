;; SETUP ---------------
;org 07C00h		; Set bootsector to be at memory location hex 7C00h (UNCOMMENT IF USING AS BOOTSECTOR)
org 8000h		; Set memory offsets to start here

jmp setup_game 

;; CONSTANTS
VIDMEM		equ 0B800h
SCREENW		equ 80
SCREENH		equ 25
WINCOND		equ 20
BGCOLOR		equ 1020h
APPLECOLOR  equ 4020h
SNAKECOLOR  equ 2020h
TIMER       equ 046Ch
SNAKEXARRAY equ 1000h
SNAKEYARRAY equ 2000h
UP		equ 0
DOWN		equ 1
LEFT		equ 2
RIGHT		equ 3

;; VARIABLES
playerX:	 dw 40
playerY:	 dw 12
appleX:		 dw 16
appleY:		 dw 8
direction:	 db 4
snakeLength: 	 dw 1

;; LOGIC --------------------
setup_game:
	;; Set video mode - VGA mode 03h (80x25 text mode, 16 colors)
	mov ax, 0003h
	int 10h

	;; Set up video memory
	mov ax, VIDMEM
	mov es, ax		; ES:DI <- video memory (0B800:0000 or B8000)

	;; Set 1st snake segment "head"
	mov ax, [playerX]
	mov word [SNAKEXARRAY], ax
	mov ax, [playerY]
	mov word [SNAKEYARRAY], ax
	
	;; Hide cursor
	;mov ah, 02h
	;mov dx, 2600h	; DH = row, DL = col, cursor is off the visible screen
	;int 10h

;; Game loop
game_loop:
	;; Clear screen every loop iteration
	mov ax, BGCOLOR
	xor di, di
	mov cx, SCREENW*SCREENH
	rep stosw				; mov [ES:DI], AX & inc di

	;; Draw snake
	xor bx, bx				; Array index
	mov cx, [snakeLength]	; Loop counter
	mov ax, SNAKECOLOR
	.snake_loop:
		imul di, [SNAKEYARRAY+bx], SCREENW*2	; Y position of snake segment, 2 bytes per character
		imul dx, [SNAKEXARRAY+bx], 2			; X position of snake segment, 2 bytes per character
		add di, dx
		stosw
		inc bx
		inc bx
	loop .snake_loop

	;; Draw apple
	imul di, [appleY], SCREENW*2
	imul dx, [appleX], 2
	add di, dx
	mov ax, APPLECOLOR
	stosw

	;; Move snake in current direction
	mov al, [direction]
    	mov si, [playerX]
    	mov di, [playerY]

	cmp al, UP
	je move_up
	cmp al, DOWN
	je move_down
	cmp al, LEFT
	je move_left
	cmp al, RIGHT
	je move_right

	jmp update_snake

	move_up:
		dec di		; Move up 1 row on the screen
		jmp update_snake

	move_down:
		inc di		; Move down 1 row on the screen
		jmp update_snake

	move_left:
		dec si		; Move left 1 column on the screen
		jmp update_snake

	move_right:
		inc si		; Move right 1 column on the screen

	;; Update snake position from playerX/Y changes
	update_snake:
        mov word [playerX], si  ;; Update snake/player X,Y position
        mov word [playerY], di

		;; Update all snake segments past the "head", iterate back to front
		imul bx, [snakeLength], 2	; each array element = 2 bytes
		.snake_loop:
			mov ax, [SNAKEXARRAY-2+bx]			; X value
			mov word [SNAKEXARRAY+bx], ax
			mov ax, [SNAKEYARRAY-2+bx]			; Y value
			mov word [SNAKEYARRAY+bx], ax
			
			dec bx								; Get previous array elem
			dec bx
		jnz .snake_loop							; Stop at first element, "head"

	;; Store updated values to head of snake in arrays
	mov word [SNAKEXARRAY], si
	mov word [SNAKEYARRAY], di
	
	
	;; Lose conditions
	;; 1) Hit borders of screen
	cmp di, -1		; Top of screen
	je game_lost
	cmp di, SCREENH	; Bottom of screen
	je game_lost
	cmp si, -1		; Left of screen
	je game_lost
	cmp si, SCREENW ; Right of screen
	je game_lost

	;; 2) Hit part of snake
	cmp word [snakeLength], 1	; Only have starting segment
	je get_player_input

	mov bx, 2					; Array indexes, start at 2nd array element
	mov cx, [snakeLength]		; Loop counter
	check_hit_snake_loop:
		cmp si, [SNAKEXARRAY+bx]
		jne .increment

		cmp di, [SNAKEYARRAY+bx]
		je game_lost				; Hit snake body, lose game :'(

		.increment:
			inc bx
			inc bx
	loop check_hit_snake_loop

	get_player_input:
		mov bl, [direction]		; Save current direction
		
		mov ah, 1
		int 16h					; Get keyboard status
		jz check_apple			; If no key was pressed, move on

		xor ah, ah
		int 16h					; Get keystroke, AH = scancode, AL = ascii char entered
		
		cmp al, 'w'
		je w_pressed
		cmp al, 's'
		je s_pressed
		cmp al, 'a'
		je a_pressed
		cmp al, 'd'
		je d_pressed
        cmp al, 'r'
        je r_pressed

		jmp check_apple

		w_pressed:
            ;; Move up
			mov bl, UP
			jmp check_apple

		s_pressed:
            ;; Move down
			mov bl, DOWN
			jmp check_apple

		a_pressed:
            ;; Move left
			mov bl, LEFT
			jmp check_apple

		d_pressed:
            ;; Move right
			mov bl, RIGHT
			jmp check_apple

		r_pressed:
            ;; Reset
			int 19h     ; Reload bootsector

	;; Did player hit apple?
	check_apple:
		mov byte [direction], bl		; Update direction
		
		mov ax, si
		cmp ax, [appleX]
		jne delay_loop

		mov ax, di
		cmp ax, [appleY]
		jne delay_loop

		; Hit apple, increase snake length
		inc word [snakeLength]
		cmp word [snakeLength], WINCOND
		je game_won

	;; Did not win yet, spawn next apple
	next_apple:
		;; Random X position
		xor ah, ah
		int 1Ah			; Timer ticks since midnight in CX:DX
		mov ax, dx		; Lower half of timer ticks
		xor dx, dx		; Clear out upper half of dividend
		mov cx, SCREENW
		div cx			; (DX/AX) / CX; AX = quotient, DX = remainder (0-79) 
		mov word [appleX], dx
			
		;; Random Y position
		xor ah, ah
		int 1Ah			; Timer ticks since midnight in CX:DX
		mov ax, dx		; Lower half of timer ticks
		xor dx, dx		; Clear out upper half of dividend
		mov cx, SCREENH
		div cx			; (DX/AX) / CX; AX = quotient, DX = remainder (0-24) 
		mov word [appleY], dx

	;; Check if apple spawned inside of snake
	xor bx, bx				; array index
	mov cx, [snakeLength]	; loop counter
	.check_loop:
		mov ax, [appleX]
		cmp ax, [SNAKEXARRAY+bx]
		jne .increment

		mov ax, [appleY]
		cmp ax, [SNAKEYARRAY+bx]
		je next_apple				; Apple did spawn in snake, make a new one!
		
		.increment:
			inc bx
			inc bx
	loop .check_loop
	
	delay_loop:
		mov bx, [TIMER]
		inc bx
		inc bx
		.delay:
			cmp [TIMER], bx
			jl .delay

jmp game_loop

;; End conditions
game_won:
	mov dword [ES:0000], 1F491F57h	; WI
	mov dword [ES:0004], 1F211F4Eh	; N!
	jmp reset
	
game_lost:
	mov dword [ES:0000], 1F4F1F4Ch	; LO
	mov dword [ES:0004], 1F451F53h	; SE
	
;; Reset the game
reset:
	xor ah, ah
	int 16h
    int 19h     ; Reload bootsector

;; Bootsector padding
times 510 - ($-$$) db 0
dw 0AA55h

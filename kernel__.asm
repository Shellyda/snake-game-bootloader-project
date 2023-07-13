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
	mov es, ax
	
	;; Set 1st snake segment "head"
	mov ax, [playerX]
	mov word [SNAKEXARRAY], ax
	mov ax, [playerY]
	mov word [SNAKEYARRAY], ax

;; Game loop
game_loop:
	;; Clear screen every loop iteration
	mov ax, BGCOLOR
	xor di, di
	mov cx, SCREENW*SCREENH
	rep stosw				; mov [ES:DI], AX & inc di

	;; Draw snake
	xor bx, bx
	mov cx, [snakeLength]
	mov ax, SNAKECOLOR
	.snake_loop:
		imul di, [SNAKEYARRAY+bx], SCREENW*2
		imul di, [SNAKEXARRAY+bx], 2
		add di, dx
		stosw
		inc bx
		inc bx
		;xor bx, bx
	loop .snake_loop
		
	
jmp game_loop

;; Bootsector padding
times 510 - ($-$$) db 0

dw 0AA55h

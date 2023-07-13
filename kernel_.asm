org 0x7e00
jmp 0x0000:start

section .data
    width db 20
    height db 10
    snake_x db 10
    snake_y db 5
    fruit_x db 15
    fruit_y db 5
    snake_length db 1
    snake_tail_x db 10 dup(0)
    snake_tail_y db 10 dup(0)
    direction db 3 ; 0: esquerda, 1: direita, 2: cima, 3: baixo
    game_over db 0

    screen_width db 80
    screen_height db 25

section .text
    global start

start:
    call init_screen
    call draw_fruit
    call draw_snake

game_loop:
    call handle_input
    call update_snake
    call check_collision
    call draw_snake

    cmp byte [game_over], 1
    je game_over_label

    jmp game_loop

game_over_label:
    ; Código para lidar com o fim do jogo
    mov eax, 1
    xor ebx, ebx
    int 0x80

init_screen:
    ; Código para inicializar a tela
    mov eax, 0x0
    mov ebx, 0x3
    int 0x10 ; Modo de vídeo: 80x25 texto
    ret

draw_fruit:
    ; Código para desenhar a fruta
    mov al, '*'
    mov ah, 0x0f ; Atributo de cor: Branco em fundo preto

    mov bh, 0x0
    mov bl, ah

    xor cx, cx
    mov cl, byte [fruit_y]

    xor dx, dx
    mov dl, byte [fruit_x]

    mov ah, 0x02 ; Função: Posicionar o cursor
    int 0x10

    mov ah, 0x09 ; Função: Escrever caractere e atributo
    int 0x10
    ret

draw_snake:
    ; Código para desenhar a cobra
    mov al, 'O'
    mov ah, 0x0f ; Atributo de cor: Branco em fundo preto

    mov bh, 0x0
    mov bl, ah

    xor cx, cx
    mov cl, byte [snake_y]

    xor dx, dx
    mov dl, byte [snake_x]

    mov ah, 0x02 ; Função: Posicionar o cursor
    int 0x10

    mov ah, 0x09 ; Função: Escrever caractere e atributo
    int 0x10
    ret

handle_input:
    ; Código para lidar com a entrada do jogador
    mov ah, 0x00 ; Função: Ler caractere
    int 0x16

    cmp al, 'a' ; Mover para a esquerda
    je move_left

    cmp al, 'd' ; Mover para a direita
    je move_right

    cmp al, 'w' ; Mover para cima
    je move_up

    cmp al, 's' ; Mover para baixo
    je move_down

    jmp handle_input

move_left:
    mov byte [direction], 0 ; Esquerda
    ret

move_right:
    mov byte [direction], 1 ; Direita
    ret

move_up:
    mov byte [direction], 2 ; Cima
    ret

move_down:
    mov byte [direction], 3 ; Baixo
    ret

update_snake:
    ; Atualizando a posição da cauda
    mov si, [snake_length]
    dec si
update_tail_loop:
    cmp si, 0
    je update_head
    mov bx, [snake_tail_x + si - 1]
    mov [snake_tail_x + si], bx
    mov bx, [snake_tail_y + si - 1]
    mov [snake_tail_y + si], bx
    dec si
    jmp update_tail_loop
    
update_head:
    ; Código para atualizar a posição da cabeça da cobra
    mov al, [direction]
    cmp al, 0 ; Esquerda
    je move_left_head

    cmp al, 1 ; Direita
    je move_right_head

    cmp al, 2 ; Cima
    je move_up_head

    cmp al, 3 ; Baixo
    je move_down_head

    ret
    
move_left_head:
    dec byte [snake_x]
    mov al, [snake_x]
    mov [snake_tail_x], al
    ret
    
move_right_head:
    inc byte [snake_x]
    mov al, [snake_x]
    mov [snake_tail_x], al
    ret
    
move_up_head:
    dec byte [snake_y]
    mov al, [snake_y]
    mov [snake_tail_y], al
    ret
    
move_down_head:
    inc byte [snake_y]
    mov al, [snake_y]
    mov [snake_tail_y], al
    ret

check_collision:
    ; Código para verificar colisões com a própria cobra
    mov al, byte [snake_x]
    mov ah, byte [snake_y]
    mov cl, byte [snake_length]
    xor ch, ch
    mov si, cx
    
collision_loop:
    cmp si, 0
    je no_self_collision
    cmp al, byte [snake_tail_x + si - 1]
    jne next_segment
    cmp ah, byte [snake_tail_y + si - 1]
    je game_over
next_segment:
    dec si
    jmp collision_loop
no_self_collision:
    ; Resto do seu código de verificação de colisão...

collision_detected:
    ; Código para lidar com colisões
    inc byte [snake_length]

    mov al, byte [snake_x]
    mov bl, byte [snake_length]
    mov byte [snake_tail_x + bx], al

    mov al, byte [snake_y]
    mov bl, byte [snake_length]
    mov byte [snake_tail_y + bx], al

    ; Gerar nova fruta em posição aleatória
    ; Supondo que temos uma função rand que retorna um número aleatório
    call rand
    and ax, 0x7F ; limite o valor para a largura da tela
    mov byte [fruit_x], al
    call rand
    and ax, 0x7F ; limite o valor para a altura da tela
    mov byte [fruit_y], al

    ret
    
rand:
    ; Uma implementação muito simples de um gerador de números pseudoaleatórios
    mov eax, 0x12345678 ; semente
    imul eax, eax, 0x41C64E6D ; constante multiplicativa
    add eax, 0x3039 ; constante de adição
    ret

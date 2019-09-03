;program for tetris
    [org 0x0100]
    jmp initialization

    
	game_continues: db "Game Continues$"
    msg_next: db "Next$"
    msg_left: db "Left=A$"
    msg_right: db "Right=D$"
    msg_rotate: db "Rotate=SPC$"
    msg_quit: db "Quit=Q$"
    msg_lines: db "POINTS:$"
    msg_game_over: db "Game Over$"
    msg_asmtris: db "TETRIS$"
	tickcount: dw 0
	seconds: dw 0
	minutes: dw 0
	hours: dw 0

    delay_centiseconds db 5 ; delay between frames in hundredths of a second
    screen_width dw 320
    
    block_size dw 5 ; block size in pixels
    blocks_per_piece dw 4 ; number of blocks in a piece
    
    colour_cemented_piece dw 40, 48, 54, 14, 42, 36, 34 ; colours for pieces
                                                        ; which have cemented
    colour_falling_piece dw 39, 47, 55, 44, 6, 37, 33 ; colours for pieces
                                                      ; which are falling
    
    pieces_origin:
    piece_t: dw 1605, 1610, 1615, 3210 ; point down
             dw 10, 1610, 1615, 3210   ; point right
             dw 10, 1605, 1610, 1615   ; point up
             dw 10, 1605, 1610, 3210   ; point left
    piece_j: dw 1605, 1610, 1615, 3215 ; point down
             dw 10, 15, 1610, 3210     ; point right
             dw 5, 1605, 1610, 1615    ; point up
             dw 10, 1610, 3205, 3210   ; point left
    piece_l: dw 1605, 1610, 1615, 3205 ; point down
             dw 10, 1610, 3210, 3215   ; point right
             dw 15, 1605, 1610, 1615   ; point up
             dw 5, 10, 1610, 3210      ; point left
    piece_z: dw 1605, 1610, 3210, 3215 ; horizontal z
             dw 15, 1610, 1615, 3210   ; vertical z
             dw 1605, 1610, 3210, 3215 ; horizontal z
             dw 15, 1610, 1615, 3210   ; vertical z
    piece_s: dw 1610, 1615, 3205, 3210 ; horizontal s
             dw 10, 1610, 1615, 3215   ; vertical s
             dw 1610, 1615, 3205, 3210 ; horizontal s
             dw 10, 1610, 1615, 3215   ; vertical s
    piece_square: dw 1605, 1610, 3205, 3210 ; a square
                  dw 1605, 1610, 3205, 3210 ; another square
                  dw 1605, 1610, 3205, 3210 ; nothing but 
                  dw 1605, 1610, 3205, 3210 ; squares here
    piece_line: dw 1600, 1605, 1610, 1615 ; horizontal line
                dw 10, 1610, 3210, 4810   ; vertical line
                dw 1600, 1605, 1610, 1615 ; horizontal line
                dw 10, 1610, 3210, 4810   ; vertical line
    

    msg_score_buffer: db "000$" ; holds the string representation of score
    score: dw 0 ; keeps score (representing total number of cleared lines)

    current_frame dw 0 ; our global frame counter
    
    delay_stopping_point_centiseconds: db 0 ; convenience variable used by the
                                           ; delay subroutine
    delay_initial: db 0 ; another convenience variable used by the 
                       ; delay subroutine
    
    random_number: db 0 ; incremented by various events 
                       ; such as input, clock polling, etc.
                       
    must_quit: db 0 ; flag indicating that the player is quitting the game
    
    cement_counter: db 0 ; number of frames during which a piece which
                        ; can no longer fall is allowed to still be
                        ; controlled by the player
    
    player_input_pressed: db 0 ; flag indicating the presence of input
    
    current_piece_colour_index: dw 0 ; index of current colour in colours array
    
    next_piece_colour_index: dw 0 ; used to display next piece
    next_piece_orientation_index: dw 0 ; used to display next piece
    
    piece_definition: dw 0 ; pointer to first of the group 
                          ; of four piece orientations for this piece
                          ; (see above for an explanation)
    piece_orientation_index: dw 0 ; 0 through 3, index of current orientation
                                 ; among all of the piece's orientations
                                                                  
    piece_blocks: dw 0, 0, 0, 0  ; stores positions of blocks of current piece 
    
    piece_position: dw 0    ; position of the top left corner 
                        ; of the falling 4 by 4 piece
    piece_position_delta: dw 0 ; frame-by-frame change in current piece position

initialization:
jmp after_start
;jmp near start
    print_sec: push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push di
mov ax, 0xb800
mov es, ax ; point es to video base
mov word[es:142], ' '
mov ax, [bp+4] ; load number in ax
mov bx, 10 ; use base 10 for division
mov cx, 0 ; initialize count of digits
nextdigit: mov dx, 0 ; zero upper half of dividend
div bx ; divide by 10
add dl, 0x30 ; convert digit into ascii value
push dx ; save ascii value on stack
inc cx ; increment count of values
cmp ax, 0 ; is the quotient zero
jnz nextdigit ; if no divide it again
mov di, 140 ; point di to 70th column
nextpos: pop dx ; remove a digit from the stack
mov dh, 0x07 ; use normal attribute
mov [es:di], dx ; print char on screen
sub di, 4
mov byte[es:di], ':'
add di, 6 ; move to next screen location
loop nextpos ; repeat for all digits on stack
pop di
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret 2

print_min: push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push di
mov ax, 0xb800
mov es, ax ; point es to video base
mov word[es:134], ' '
mov ax, [bp+4] ; load number in ax
mov bx, 10 ; use base 10 for division
mov cx, 0 ; initialize count of digits
nextdigit1: mov dx, 0 ; zero upper half of dividend
div bx ; divide by 10
add dl, 0x30 ; convert digit into ascii value
push dx ; save ascii value on stack
inc cx ; increment count of values
cmp ax, 0 ; is the quotient zero
jnz nextdigit1 ; if no divide it again
mov di, 134 ; point di to 70th column
nextpos1: pop dx ; remove a digit from the stack
mov dh, 0x07 ; use normal attribute
mov [es:di], dx ; print char on screen
sub di, 4
mov byte[es:di], ':'
add di, 6 ; move to next screen location
loop nextpos1 ; repeat for all digits on stack
pop di
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret 2


print_hours: push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push di
mov ax, 0xb800
mov es, ax ; point es to video base
mov ax, [bp+4] ; load number in ax
mov bx, 10 ; use base 10 for division
mov cx, 0 ; initialize count of digits
nextdigit2: mov dx, 0 ; zero upper half of dividend
div bx ; divide by 10
add dl, 0x30 ; convert digit into ascii value
push dx ; save ascii value on stack
inc cx ; increment count of values
cmp ax, 0 ; is the quotient zero
jnz nextdigit2 ; if no divide it again
mov di, 130 ; point di to 70th column
nextpos2: pop dx ; remove a digit from the stack
mov dh, 0x07 ; use normal attribute
mov [es:di], dx ; print char on screen
add di, 2 ; move to next screen location
loop nextpos2 ; repeat for all digits on stack
pop di
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret 2

; timer interrupt service routine
timer: 
push ax
inc word [cs:tickcount]; increment tick count
cmp word[cs:tickcount], 18
je inc_sec

ret_func:
mov al, 0x20
out 0x20, al ; end of interrupt
pop ax
iret ; return from interrupt

inc_sec:
mov word[cs:tickcount], 0
inc word[cs:seconds]
push word[cs:seconds]
call print_sec
cmp word[cs:seconds], 60
je inc_minutes
jmp ret_func

inc_minutes:
mov word[cs:seconds], 0
inc word[cs:minutes]
push word[cs:minutes]
call print_min
cmp word[cs:minutes], 60
je inc_hours
jmp ret_func


inc_hours:
mov word[cs:minutes], 0
inc word[cs:hours]
push word[cs:hours]
call print_hours
cmp word[cs:hours], 60
je reset
jmp ret_func

reset:
mov word[cs:tickcount], 0
mov word[cs:seconds], 0
mov word[cs:minutes], 0
mov word[cs:hours], 0
jmp ret_func

after_start:
    mov ax, 13h 
    int 10h
    
    mov ax, 0305h
    xor bx, bx
    int 16h

    call procedure_random_next_piece

    call procedure_draw_screen


new_piece:

    call procedure_display_score
    
    mov word [piece_position], 14550
    
    mov ax, [next_piece_colour_index]
    mov word [current_piece_colour_index], ax

    shl ax, 5 ; ax := ax * 32 ( 16 words for each piece )
    add ax, pieces_origin ; offset from first piece
    mov [piece_definition], ax ; piece_definition now points to the first of 
                               ; four piece orientations of a specific piece    

    mov ax, [next_piece_orientation_index]
    mov word [piece_orientation_index], ax ; choose one of the 
                                           ; four orientations
    call procedure_copy_piece
    
    call procedure_can_piece_be_placed
    test al, al ; did we get a 0, meaning "can move"?
    jnz near game_over ; no, can't move down - game is over!
    
    call procedure_random_next_piece
    
main_loop:

    mov word ax, [current_frame]
    inc ax
    mov word [current_frame], ax

    call procedure_delay
    
    mov word [piece_position_delta], 0
    mov byte [player_input_pressed], 0
    
    
read_input:

    call procedure_read_character
    cmp byte [must_quit], 0
    jne near done
   
handle_horizontal_movement:
    
    mov ax, [piece_position_delta]
    test ax, ax
    jz handle_vertical_movement ; we didn't press left or right

    call procedure_apply_delta_and_draw_piece
    
handle_vertical_movement:
    
    mov cx, [blocks_per_piece] ; each piece has 4 blocks
handle_vertical_movement_loop:

    mov di, [piece_position] ; start from the origin of the piece
    mov bx, cx ; wish I could use cx as an index register...
    shl bx, 1 ; bx := bx * 2, since each block index is a word
    sub bx, 2 ; our index is zero-based, while cx/loop are one-based
    add di, word [piece_blocks + bx] ; shift position in the piece 
                                     ; to the position of current block

    call procedure_can_move_down
    test al, al ; a non-zero indicates an obstacle below
    jnz handle_vertical_movement_loop_failure
    
    loop handle_vertical_movement_loop
    
    jmp handle_vertical_movement_move_down_success
    
handle_vertical_movement_loop_failure:

    mov byte al, [player_input_pressed]
    test al, al
    
    jz handle_vertical_movement_cement_immediately

    mov byte al, [cement_counter]
    dec al
    mov byte [cement_counter], al
    test al, al ; if we reached zero now, it means the piece can finally cement
    jnz main_loop ; we haven't reached zero yet, so render next frame

    
handle_vertical_movement_cement_immediately:

    mov byte [cement_counter], 0
    
    mov word bx, [current_piece_colour_index]
    shl bx, 1 ; each colour is a word, so offset by double the index
    mov byte dl, [colour_cemented_piece + bx]
    call procedure_draw_piece

    xor dx, dx ; we'll accumulate number of lines cleared in dx
    mov cx, 20 ; we're clearing at most 4 lines, each 
               ; having a height of 5 pixels
    
handle_vertical_movement_cement_immediately_attempt_clear_lines_loop:
    push dx
    call procedure_attempt_line_removal    
    pop dx
    
    add dl, al
    loop handle_vertical_movement_cement_immediately_attempt_clear_lines_loop
    
update_score:
    mov ax, dx
    mov dl, [block_size]
    div dl ; al now contains number of block lines
    xor ah, ah
    
    mov word dx, [score]
    add ax, dx
    
    cmp ax, 10 ; our scoring goes to 999, so restart at 0 if it goes over
    jl score_is_not_over_10
    sub ax, 10
score_is_not_over_10:
    mov word [score], ax
    
    jmp new_piece

handle_vertical_movement_move_down_success:

    mov byte [cement_counter], 10

    mov ax, [screen_width]
    mov word [piece_position_delta], ax
    call procedure_apply_delta_and_draw_piece
    
    jmp main_loop

game_over:

    call procedure_display_game_over
    
game_over_loop:

    call procedure_delay
    
    mov word ax, [current_frame]
    inc ax
    mov word [current_frame], ax
    
    mov ah, 1
    int 16h ; any key pressed ?
    jz game_over_loop ; no key pressed
    
    xor ah, ah
    int 16h
    cmp al, 'q'
    jne game_over_loop ; wait for Q to be pressed to exit the program

done:

    mov ax, 3
    int 10h ; restore text mode

    ret
	
procedure_display_score:

    mov word ax, [score]
    mov dl, 100
    div dl ; hundreds in al, remainder in ah 
    mov cl, '0'
    add cl, al
    mov byte [msg_score_buffer], cl ; set hundreds digit
    
    mov al, ah ; divide remainder again
    xor ah, ah
    mov dl, 10
    div dl ; tens in al, remainder in ah
    mov cl, '0'
    add cl, al
    mov byte [msg_score_buffer + 1], cl ; set tens digit
    
    mov cl, '0'
    add cl, ah
    mov byte [msg_score_buffer + 2], cl ; set units digit
    
    mov bx, msg_score_buffer
    mov dh, 0
    mov dl, 9
    call procedure_print_at
	
	
    ret

    
procedure_print_at:

    push bx
    mov ah, 2
    xor bh, bh
    int 10h
    
    mov ah, 9
    pop dx
    int 21h
    
    ret
    
procedure_random_next_piece:
    
    call procedure_delay ; advance random number (or seed for the initial call)
    
    mov bl, 7
    call procedure_generate_random_number ; choose a piece (in ax)
    mov word [next_piece_colour_index], ax ; save colour index
    
    mov bl, 4
    call procedure_generate_random_number ; choose one of four piece
                                          ; orientations (in ax)
    
    mov word [next_piece_orientation_index], ax 
    
    ret


procedure_attempt_line_removal:

    push cx
    
    mov di, 47815
    mov cx, 104 ; we'll check at most all but one lines of the play area
                ; there are 20 block lines, and each block line is 5 pixels 
                ; tall with an additional top line to accomodate pieces with 
                ; an empty top block line in some of their orientations
    
attempt_line_removal_loop:

    call procedure_is_horizontal_line_full
    test al, al
    jz attempt_line_removal_full_line_found
    
    sub di, [screen_width] ; move one line up
    loop attempt_line_removal_loop
    
    jmp attempt_line_removal_no_line_found
    
attempt_line_removal_full_line_found:
attempt_line_removal_shift_lines_down_loop:
    
    push cx 
    push di
        
    mov si, di
    sub si, [screen_width] ; line above (source)
    
    mov cx, 50
    
    push ds
    push es
    mov ax, 0A000h ; we'll be reading and writing within the video segment
    mov ds, ax ; so source segment will be this segment as well
    mov es, ax ; and so will the destination segment
    rep movsb
    pop es
    pop ds
    
    pop di
    pop cx
    
    sub di, [screen_width] ; move one line up
    
    loop attempt_line_removal_shift_lines_down_loop
    
    xor dl, dl
    mov cx, 50
    call procedure_draw_line ; empty the top most line
    
    mov al, 1
    jmp attempt_line_removal_done

attempt_line_removal_no_line_found:    
    xor al, al
    
attempt_line_removal_done:
    pop cx
    ret


procedure_is_horizontal_line_full:
    push cx
    push di
    
    mov cx, 50 ; width of play area is 10 blocks
is_horizontal_line_full_loop:

    call procedure_read_pixel
    test dl, dl ; is colour at current location black?
    jz is_horizontal_line_full_failure
    
    inc di ; next pixel of this line
    loop is_horizontal_line_full_loop
    
    xor ax, ax
    jmp is_horizontal_line_full_loop_done
    
is_horizontal_line_full_failure:

    mov al, 1
    
is_horizontal_line_full_loop_done:
    pop di
    pop cx
    
    ret

    
procedure_generate_random_number:

    mov al, byte [random_number]
    add al, 31
    mov byte [random_number], al

    div bl ; divide by N
    mov al, ah ; save remainder in al
    xor ah, ah
    
    ret

    
procedure_copy_piece:
    
    push ds
    push es
    
    mov ax, cs ; all code is within this segment
    mov ds, ax ; so source segment will be this segment as well
    mov es, ax ; and so will the destination segment
    
    mov di, piece_blocks ; pointer to current orientation (destination)
    
    mov ax, [piece_orientation_index] ; choose k-th orientation 
                                      ; of this piece ( 0 through 3 )
    
    mov si, [piece_definition] ; piece_definition is a pointer to 
                               ; first orientation of current piece (source)
    shl ax, 3 ; ax := ax * 8 ( 4 words for each orientation )
    add si, ax ; offset orientation within the current piece
    
    mov cx, 4
    
    rep movsw ; perform copy
    
    pop es
    pop ds
    
    ret
    
    
procedure_apply_delta_and_draw_piece:

    mov dl, 0
    call procedure_draw_piece

    mov ax, [piece_position]
    add ax, [piece_position_delta]
    mov [piece_position], ax
    
    mov word bx, [current_piece_colour_index]
    shl bx, 1 ; two bytes per colour
    mov byte dl, [colour_falling_piece + bx]
    call procedure_draw_piece

    ret
    
    
procedure_draw_piece:    

    mov cx, [blocks_per_piece]
draw_piece_loop:

    mov di, [piece_position]
    
    mov bx, cx
    shl bx, 1 ; bx := bx * 2
    sub bx, 2 ; our index is zero-based, while cx/loop are one-based
    add di, word [piece_blocks + bx] ; shift position in the piece 
                                     ; to the position of current block
                                     
    mov bx, [block_size]
    call procedure_draw_square
    
    loop draw_piece_loop
    
    ret


procedure_can_piece_be_placed:
    mov cx, [blocks_per_piece] ; each piece has 4 blocks

can_piece_be_placed_loop:
    mov di, [piece_position]
    
    mov bx, cx 
    shl bx, 1 ; bx := bx * 2
    sub bx, 2 ; our index is zero-based, while cx/loop are one-based
    add di, word [piece_blocks + bx] ; shift position in the piece 
                                     ; to the position of current block
    
    push cx ; don't mess up the outer loop
    
    mov bx, 1 ; horizontal lines
    
    mov cx, [block_size]
can_piece_be_placed_line_by_line_loop:

    call procedure_is_line_available
    test al, al ; a non-zero indicates an obstacle
    jne can_piece_be_placed_failure
    
    add di, [screen_width]
    loop can_piece_be_placed_line_by_line_loop
    
    pop cx
    
    loop can_piece_be_placed_loop
    
    xor ax, ax
    jmp can_piece_be_placed_success

can_piece_be_placed_failure:
    mov al, 1
    
    pop cx

can_piece_be_placed_success:

    ret


procedure_advance_orientation:

    mov word ax, [piece_orientation_index]
    inc ax
    and ax, 3 ; ax := (ax + 1) mod 4
    mov word [piece_orientation_index], ax
    
    call procedure_copy_piece
    
    ret
    
    
procedure_read_character: 

    mov ah, 1
    int 16h ; any keys pressed?
    jnz read_character_key_was_pressed ; yes
    
    ret

read_character_key_was_pressed:

    mov ah, 0
    int 16h
    
    push ax    
    mov ah, 6 ; direct console I/O
    mov dl, 0FFh ; input mode
    int 21h 
    pop ax

handle_input:
    cmp al, 'd'
    je move_right
    
    cmp al, 'a'
    je near move_left
    
    cmp al, ' '
    je rotate
    
    cmp al, 'q'
    je quit    
    
    ret

quit:
    mov byte [must_quit], 1        
    ret

rotate:
    push word [piece_orientation_index]
    
    call procedure_advance_orientation
    
    call procedure_can_piece_be_placed
    test al, al ; did we get a 0, meaning ok
    jz rotate_perform ; yes!
    
    pop word [piece_orientation_index] 
    call procedure_copy_piece
    
    ret
    
rotate_perform:
    pop word [piece_orientation_index] 
    call procedure_copy_piece
    
    xor dl, dl ; black colour
    call procedure_draw_piece
    
    call procedure_advance_orientation
    
    mov al, byte [random_number]
    add al, 11
    mov byte [random_number], al
    
    ret
    
move_right:
    mov byte [player_input_pressed], 1
    
    mov cx, [blocks_per_piece]
move_right_loop:
    mov di, [piece_position]
    
    mov bx, cx
    shl bx, 1 ; bx := bx * 2
    sub bx, 2 ; our index is zero-based, while cx/loop are one-based
    add di, word [piece_blocks + bx] ; shift position in the piece 
                                     ; to the position of current block
    
    add di, [block_size]

    mov bx, [screen_width]
    call procedure_is_line_available
    
    test al, al ; did we get a 0, meaning success ?
    jnz move_right_done ; no
    
    loop move_right_loop
    
    mov ax, [piece_position_delta]
    add ax, [block_size]
    mov [piece_position_delta], ax

move_right_done:
    mov al, byte [random_number]
    add al, 3
    mov byte [random_number], al
    
    ret
    
move_left:
    mov byte [player_input_pressed], 1
    
    mov cx, [blocks_per_piece]
move_left_loop:    
    mov di, [piece_position]
    
    mov bx, cx
    shl bx, 1 ; bx := bx * 2
    sub bx, 2 ; our index is zero-based, while cx/loop are one-based
    add di, word [piece_blocks + bx] ; shift position in the piece 
                                     ; to the position of current block
    
    dec di
    
    mov bx, [screen_width]
    call procedure_is_line_available
    
    test al, al ; did we get a 0, meaning success ?
    jnz move_left_done ; no    
    
    loop move_left_loop
    
    mov ax, [piece_position_delta]
    sub ax, [block_size]
    mov [piece_position_delta], ax
    
move_left_done:
    mov al, byte [random_number]
    add al, 5
    mov byte [random_number], al
    
    ret

    
procedure_can_move_down:

    push cx
    push di
    
    mov cx, [block_size]
can_move_down_find_delta:
    add di, [screen_width]
    loop can_move_down_find_delta
    
    mov bx, 1
    call procedure_is_line_available
    
    test al, al ; did we get a 0, meaning success ?
    jnz can_move_down_obstacle_found ; no
    
    xor ax, ax
    jmp can_move_down_done
    
can_move_down_obstacle_found:
    mov ax, 1
    
can_move_down_done:
    
    pop di
    pop cx
    
    ret


procedure_is_line_available:

    push bx
    push cx
    push di
    
    mov cx, [block_size]
is_line_available_loop:

    call procedure_read_pixel
    test dl, dl ; is colour at current location black?
    jnz is_line_available_obstacle_found
    
is_line_available_loop_next_pixel:    
    add di, bx ; move to next pixel of this line
    loop is_line_available_loop
    
    xor ax, ax
    jmp is_line_available_loop_done

    
is_line_available_obstacle_found:
    push bx
    mov word bx, [current_piece_colour_index]
    shl bx, 1 ; two bytes per colour
    mov byte al, [colour_falling_piece + bx]
    cmp dl, al ; if obstacle is a falling block, treat it as a non-obstacle
    pop bx
    jne is_line_available_failure
    
    jmp is_line_available_loop_next_pixel
    
is_line_available_failure:
    mov al, 1
    
is_line_available_loop_done:
    pop di
    pop cx
    pop bx
    
    ret


procedure_delay:
    push bx
    push cx
    push dx 
    push ax

    xor bl, bl
    mov ah, 2Ch
    int 21h
    
    mov byte al, [random_number]
    add al, dl
    mov byte [random_number], al
    
    mov [delay_initial], dh
    
    add dl, [delay_centiseconds]
    cmp dl, 100
    jb delay_second_adjustment_done
    
    sub dl, 100
    mov bl, 1

delay_second_adjustment_done:
    mov [delay_stopping_point_centiseconds], dl

read_time_again:
    int 21h
    
    test bl, bl ; will we stop within the same second?
    je must_be_within_same_second
    
    cmp dh, [delay_initial]
    je read_time_again
    
    push dx
    sub dh, [delay_initial]
    cmp dh, 2
    pop dx
    jae done_delay
    
    jmp check_stopping_point_reached
    
must_be_within_same_second: 
    cmp dh, [delay_initial]
    jne done_delay
    
check_stopping_point_reached:
    cmp dl, [delay_stopping_point_centiseconds]
    jb read_time_again

done_delay:
    pop ax
    pop dx
    pop cx
    pop bx
    
    ret

procedure_draw_square:

    mov ax, bx
    call procedure_draw_rectangle
    
    ret
    
procedure_draw_rectangle:

    push di
    push dx
    push cx
    
    mov cx, ax
draw_rectangle_loop:    
    push cx
    push di
    mov cx, bx
    call procedure_draw_line
    
    pop di
    
    add di, [screen_width]
    
    pop cx
    
    loop draw_rectangle_loop

    pop cx
    pop dx
    pop di
    
    ret


procedure_draw_line_vertical:

    call procedure_draw_pixel
    
    add di, [screen_width]
    
    loop procedure_draw_line_vertical
    
    ret

    
procedure_draw_line:

    call procedure_draw_pixel
    
    inc di
    
    loop procedure_draw_line
    
    ret


procedure_draw_pixel:

    push ax
    push es

    mov ax, 0A000h
    mov es, ax
    mov byte [es:di], dl
    
    pop es
    pop ax
    
    ret


procedure_read_pixel:

    push ax
    push es

    mov ax, 0A000h
    mov es, ax
    mov byte dl, [es:di]
    
    pop es
    pop ax
    
    ret


procedure_draw_border:

    mov dl, 200 ; colour
    
    mov bx, 4
    mov ax, 200
    
    xor di, di
    call procedure_draw_rectangle
    
    mov di, 316
    call procedure_draw_rectangle
    
    mov bx, 317
    mov ax, 4
    
    xor di, di
    call procedure_draw_rectangle
    
    mov di, 62720
    call procedure_draw_rectangle
    
    ret


procedure_draw_screen:

    call procedure_draw_border
    
draw_screen_play_area:
    mov dl, 27 ; colour
    
    mov cx, 52
    mov di, 14214
    call procedure_draw_line
    
    mov cx, 52
    mov di, 48134
    call procedure_draw_line

    mov cx, 105
    mov di, 14534
    call procedure_draw_line_vertical
    
    mov cx, 105
    mov di, 14585
    call procedure_draw_line_vertical


draw_screen_strings:
    
    mov dh, 8
    mov dl, 4
    mov bx, msg_left
    call procedure_print_at
    
    mov dh, 10
    mov dl, 4
    mov bx, msg_right
    call procedure_print_at
    
    mov dh, 12
    mov dl, 4
    mov bx, msg_rotate
    call procedure_print_at
    
    mov dh, 14
    mov dl, 4
    mov bx, msg_quit
    call procedure_print_at
    
    mov bx, msg_lines
    mov dh, 0
    mov dl, 2
    call procedure_print_at
    
    mov bx, msg_asmtris
    mov dh, 3
    mov dl, 17
    call procedure_print_at
	
	mov bx, game_continues
	mov dh, 0
	mov dl, 16
	call procedure_print_at
    
    ret

    
procedure_display_game_over:

    xor dl, dl
    mov ax, 45
    mov bx, 100
    mov di, 19550
    call procedure_draw_rectangle

    mov dl, 40
    mov ax, 16
    mov bx, 88
    mov di, 29560
    call procedure_draw_rectangle

    mov dh, 12
    mov dl, 16
    mov bx, msg_game_over
    call procedure_print_at

    ret
    
start: 
xor ax, ax
mov es, ax ; point es to IVT base
cli ; disable interrupts
mov word [es:8*4], timer; store offset at n*4
mov [es:8*4+2], cs ; store segment at n*4+2
sti ; enable interrupts
mov dx, start ; end of resident portion
add dx, 15 ; round up to next para
mov cl, 4
shr dx, cl ; number of paras
mov ax, 0x3100 ; terminate and stay resident
int 0x21
jmp near after_start
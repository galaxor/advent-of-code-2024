.text            
.global _start
_start:
  # Read <= 8192 bytes from stdin
  mov r7, #3
  mov r0, #0
  ldr r1, =input_buffer
  mov r2, #buffer_size
  swi 0

  # if we got zero bytes, we are done.
  cmp r0, #0
  beq exit

  # Number of bytes read is in r0
  ldr r1, =input_buffer
  add r2, r1, r0
  ldr r3, =input_buffer_end_pointer
  str r2, [r3]
  
  # r1 = input buffer pointer
  # r2 = input buffer end pointer
  # r4 = multiplicand buffer pointer
  # r5 = multiplier buffer pointer
  # r6 = current state

  ldr r4, =multiplicand_buffer
  ldr r5, =multiplier_buffer
  mov r6, #0

examine_character_loop:
  cmp r1, r2
  bge end_of_character_loop

  # Grab the current character from the input buffer into r3 for consideration (incrementing the pointer after).
  ldrb r3, [r1], #+1

  # Do things based on the state (in r6) and the character (in r3).
  cmp r6, #STATE_START
  itt eq
  cmpeq r3, #'m'
  beq goto_state_m

  cmp r6, #STATE_M
  it eq
  cmpeq r3, #'u'
  beq goto_state_u

  cmp r6, #STATE_U
  it eq
  cmpeq r3, #'l'
  beq goto_state_l

  cmp r6, #STATE_L
  it eq
  cmpeq r3, #'('
  beq goto_state_open_paren

  # Maybe the thing is always 'gt' vs 'le'.  And we check whether the state is greater than state_l (state open paren minus one), then whether the character is greater than 0x2f (0x30 is '0'), then whether the state is greater than 0x39 (which it shouldn't be).  Something like that.
  cmp r6, #STATE_OPEN_PAREN

goto_start_state:
  b exit

goto_state_m:

goto_state_u:

goto_state_l:

goto_state_open_paren:

goto_state_multiplicand:

goto_stat_comma:

goto_state_multiplier:

goto_state_close_paren:


  # Go back to the top of the loop.
  # The pointer has already been incremented as a result of the post-indexing on the ldrb.
  b examine_character_loop


end_of_character_loop:
  # Read more characters from stdin
  # (can we just jump to _start?)
  


exit:
  # Exit
  mov r7, #1
  # We're keeping r0, the return value from read, as our return code.
  swi 0

.data
state: .dc.l 0
STATE_START = 0
STATE_M = 1
STATE_U = 2
STATE_L = 3
STATE_OPEN_PAREN = 4
STATE_MULTIPLICAND = 5
STATE_COMMA = 6
STATE_MULTIPLIER = 7
STATE_CLOSE_PAREN = 8

buffer_size = 8192
input_buffer: .dcb.b buffer_size
input_buffer_end_pointer: .long 0

multiplicand_buffer: .dcb.b buffer_size
multiplicand_end_pointer: .long 0
multiplier_buffer: .dcb.b buffer_size
multiplier_buffer_end_pointer: .long 0

multiplicand: .int 0
multiplier: .int 0

# These are the different actions we can take at each step of our automaton.
OP_NOOP = 0
OP_COPY_MULTIPLICAND_DIGIT = 1 << 24
OP_COPY_MULTIPLIER_DIGIT = 2 << 24
OP_MULTIPLY = (8+4) << 24
OP_RESET = 8 << 24


automaton_table:
  # (input character, input state, output state, output action)
  # Any time an (input state, input character) has no output state or action, the output state is STATE_START and the output action is to reset.
  .int 'm' + STATE_START << 8 + STATE_M << 16 + OP_NOOP
  .int 'u' + STATE_M << 8 + STATE_U << 16 + OP_NOOP
  .int 'l' + STATE_U << 8 + STATE_L << 16 + OP_NOOP
  .int '(' + STATE_L << 8 + STATE_OPEN_PAREN << 16 + OP_NOOP

  .int '1' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '2' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '3' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '4' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '5' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '6' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '7' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '8' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '9' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT

  .int '0' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '1' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '2' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '3' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '4' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '5' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '6' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '7' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '8' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '9' + STATE_MULTIPLICAND << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT

  .int ',' + STATE_MULTIPLICAND << 8 + STATE_COMMA << 16 + OP_NOOP

  .int '1' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '2' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '3' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '4' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '5' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '6' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '7' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '8' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '9' + STATE_COMMA << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT

  .int '0' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '1' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '2' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '3' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '4' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '5' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '6' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '7' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '8' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT
  .int '9' + STATE_MULTIPLIER << 8 + STATE_MULTIPLIER << 16 + OP_COPY_MULTIPLIER_DIGIT

  .int ')' + STATE_MULTIPLIER << 8 + STATE_START << 16 + OP_MULTIPLY


message:
  .asciz "hello world\n"
len = .-message

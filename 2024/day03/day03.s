.text            
.global _start
_start:
  # Variables
  # char input_buffer[buffer_size]
  # char *input_buffer_pointer
  # char *input_buffer_end_pointer

  # char multiplicand_buffer[buffer_size]
  # char *multiplicand_buffer_pointer
  # char *multiplicand_end_pointer

  # char multiplier_buffer[buffer_size]
  # char *multiplier_buffer_pointer
  # char *multiplier_buffer_end_pointer

  # unsigned int multiplicand
  # unsigned int multiplier

  # unsigned int current_state
  # unsigned int current_sum

  # "Call" read_into_buffer (by falling into it).
  # Set the lr to the "reset" label so it returns to that point.
  ldr lr, =reset

read_into_buffer:
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

  # input_buffer_pointer = input_buffer + 0
  ldr r1, =input_buffer
  ldr r2, =input_buffer_pointer
  str r1, [r2]

  # input_buffer_end_pointer = input_buffer + number_of_bytes_read
  add r2, r1, r0
  ldr r3, =input_buffer_end_pointer
  str r2, [r3]

  # Return.
  bx lr

reset:

  ldr r0, =multiplicand_buffer
  ldr r1, =multiplicand_buffer_pointer
  str r0, [r1]

  ldr r2, =multiplier_buffer
  ldr r3, =multiplier_buffer_pointer
  str r2, [r3]

  mov r6, #(STATE_START << 8)

examine_character_loop:
  cmp r1, r2
  bge end_of_character_loop

  # Grab the current character from the input buffer into r3 for consideration (incrementing the pointer after).
  ldrb r3, [r1], #+1

  

  

  # Go back to the top of the loop.
  # The pointer has already been incremented as a result of the post-indexing on the ldrb.
  b examine_character_loop

  
end_of_character_loop:


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
input_buffer_pointer: .long input_buffer
input_buffer_end_pointer: .long 0

multiplicand_buffer: .dcb.b buffer_size
multiplicand_buffer_pointer: .long multiplicand_buffer
multiplicand_end_pointer: .long 0

multiplier_buffer: .dcb.b buffer_size
multiplier_buffer_pointer: .long multiplier_buffer
multiplier_buffer_end_pointer: .long 0

multiplicand: .int 0
multiplier: .int 0

current_state: .int STATE_START
current_sum: .int 0


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

automaton_table_end = .


message:
  .asciz "hello world\n"
len = .-message

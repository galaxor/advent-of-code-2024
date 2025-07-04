.syntax unified

.text            
.global _start
.thumb_func
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
  bl read_into_buffer
  b reset
  
.thumb_func
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

examine_character_loop_init:
  # If we've reached the end of the input buffer, we need to load more characters.
  ldr r0, =input_buffer_pointer
  ldr r1, [r0]
  ldr r3, =input_buffer_end_pointer
  ldr r2, [r3]

  cmp r1, r2
    # XXX We should be loading more characters here instead of branching to the end.
  bge exit

  # Grab the current character from the input buffer into r3 for consideration (incrementing the pointer after).
  # For some reason, I get an illegal instruction error if I don't have this nop here.
  # Maybe it's an interworking fail because the last instruction was a branch?
  nop
  ldrb r5, [r1]
  add r1, r1, #1
  str r1, [r0]

  # Loop through the states and see what to do.
  # r0 = scratch
  # r1 = scratch
  # r2 = automaton_table_pointer
  # r3 = automaton_table_end_pointer
  # r4 = automaton word
  # r5 = (current_state << 8) | current character

  ldr r2, =automaton_table
  ldr r3, =automaton_table_end_pointer

  # r5 now contains (current state << 8) + current character.
  orr r5, r6

examine_character_loop:
  # Load the automaton word and then advance the automaton table pointer.
  ldmia r2!, { r4 }

  # We want r1 to contain 0x00ff0000 so it can mask out the state to move to.
  mov r1, #0xff
  lsl r1, r1, #16

  mov r0, #0xffff
  and r0, r4
  # r0 now contains the lower 2 bytes of the automaton word.
  # If that equals (current state << 8 | current character), do the thing!
  cmp r0, r5

  # If this is the right state transition,
  # put the new (state << 8) into r6
  itttt eq
  andeq r6, r4, r1
  lsreq r6, r6, #8
  # shift the mask over so we can get the opcode of the state transition.
  lsleq r1, r1, #8
  andeq r1, r4

  ite eq
  moveq r0, #-1
  movne r0, #0

  # r0 has -1 if this is a matching state transition and 0 if it's not.
  # So r1 has the state transition opcodes if this is the matching state, and 0 if it's not.
  and r1, r1, r0

  # Figure out what opcode(s) we're doing and jump to the subroutine to do that.
  # The subroutine must not touch r1, which contains the list of opcodes that we're doing.
  mov r0, r5
  push {r0, r1, r2, r3, r4, r5, r6}

  # r0 needs to have the (current state << 8 | current character) so we can pass it to any of the ops subroutines if we do them.

  mov r7, #OP_COPY_MULTIPLICAND_DIGIT
  ands r7, r7, r1
  it ne
  blne copy_multiplicand_digit

  mov r7, #OP_COPY_MULTIPLIER_DIGIT
  ands r7, r7, r1
  it ne
  blne copy_multiplier_digit

  mov r7, #OP_MULTIPLY
  ands r7, r7, r1
  it ne
  blne multiply

  # Whether we're resetting here or not, we need to get everything back off the stack.
  pop {r0, r1, r2, r3, r4, r5, r6}

  mov r7, #OP_RESET
  ands r7, r7, r1
  bne reset

  # r0 is free again.

  # If r1 is not zero, that means we found a match, so let's get the next character.
  mov r0, #0
  cmp r0, r1
  bne examine_character_loop_init


  # We didn't match this state. If that was the last state, we reset. Otherwise, we check the next state.
  # r2 = automaton_table_pointer
  # r3 = automaton_table_end_pointer
  cmp r2, r3
  bge reset
  b examine_character_loop
  

.thumb_func
copy_multiplicand_digit:

  # char multiplicand_buffer[buffer_size]
  # char *multiplicand_buffer_pointer
  # char *multiplicand_end_pointer

  # r0 has the (current state << 8 | current character)
  mov r6, #0xff
  and r5, r0, r6

  ldr r4, =multiplicand_buffer_pointer
  ldr r6, [r4]
  strb r5, [r6], #1
  str r6, [r4]

  # Return
  bx lr

  
.thumb_func
copy_multiplier_digit:

  # char multiplier_buffer[buffer_size]
  # char *multiplier_buffer_pointer
  # char *multiplier_end_pointer

  # r0 has the (current state << 8 | current character)
  mov r6, #0xff
  and r5, r0, r6

  ldr r4, =multiplier_buffer_pointer
  ldr r6, [r4]
  strb r5, [r6], #1
  str r6, [r4]

  # Return
  bx lr


.thumb_func
multiply:
  # For now, I'm just going to print out the multiplication I would do.

  ldr r1, =multiplicand_buffer

  ldr r4, =multiplicand_buffer_pointer
  ldr r4, [r4]

  # Write the multiplicand to stdout
  mov r7, #4
  mov r0, #1
  ldr r1, =multiplicand_buffer
    # The size of the buffer to print is the multiplicand buffer pointer minus the start of the multiplicand buffer.
  sub r2, r4, r1
  swi 0

  # Write " * " to stdout
  mov r7, #4
  mov r0, #1
  ldr r1, =times_string
  mov r2, #3
  swi 0

  # Write the multiplier to stdout.
  ldr r1, =multiplier_buffer

  ldr r4, =multiplier_buffer_pointer
  ldr r4, [r4]

  # Write the multiplier to stdout
  mov r7, #4
  mov r0, #1
  ldr r1, =multiplier_buffer
    # The size of the buffer to print is the multiplier buffer pointer minus the start of the multiplier buffer.
  sub r2, r4, r1
  swi 0
  
  # Write a newline to stdout
  mov r7, #4
  mov r0, #1
  ldr r1, =newline
  mov r2, #1
  swi 0

  # Parse the integers and add them to the total.
  ldr r0, =multiplicand_buffer
  ldr r2, =multiplicand_buffer_pointer
  ldr r1, [r2]
  push {lr}
  bl parse_int
  pop {lr}

  # We got an integer in r0. Push it to the stack so we can parse the next integer.
  push {r0, lr}
  ldr r0, =multiplier_buffer
  ldr r2, =multiplier_buffer_pointer
  ldr r1, [r2]
  bl parse_int
  mov r1, r0
  pop {r0, lr}

  # We may need to do something more complicated, since muls does not allow us to detect overflows.
  # We may need to use umull, which stores the product into two registers like x86 does.
  # https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/detecting-overflow-from-mul

  # Now r0 has the multiplicand and r1 has the multiplier.
  muls r0, r1
  
  # Dig out the sum and add the product to it.  (The product is in r0).
  ldr r2, =current_sum
  ldr r3, [r2]
  add r3, r3, r0
  str r3, [r2]

  # Return
  bx lr

.thumb_func
parse_int:
  # The pointer to the number's buffer will be in r0.
  # The pointer to the end of the number's buffer will be in r1.
  # We will accumulate into r5, and move it into r0 at the end.
  # We will return the integer in r0.
  mov r5, #0

parse_int_loop:
  ldrb r3, [r0]
    # 0x30 is ascii for '0'.
  sub r4, r3, #0x30     
  add r5, r5, r4

  # If we're not at the end of the number's buffer, multiply by 10.
  add r0, r0, #1

  cmp r0, r1
  itttt lt
  movlt r6, r5
  lsllt r5, #3
  addlt r5, r5, r6
  addlt r5, r5, r6

  # Go on to the next digit of the input buffer
  it lt
  blt parse_int_loop

  # The output needs to be in r0.
  mov r0, r5
  
  # Return if we've processed all the digits.
  bx lr

.thumb_func
exit:
  ldr r2, =current_sum
  ldr r3, [r2]

  # Exit
  mov r7, #1
  mov r0, r3
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
OP_NOOP = 1 << 24
OP_COPY_MULTIPLICAND_DIGIT = 2 << 24
OP_COPY_MULTIPLIER_DIGIT = 4 << 24
OP_MULTIPLY = (16+8) << 24
OP_RESET = 16 << 24


automaton_table:
  # (input character, input state, output state, output action)
  # Any time an (input state, input character) has no output state or action, the output state is STATE_START and the output action is to reset.
  .int 'm' + STATE_START << 8 + STATE_M << 16 + OP_NOOP
  .int 'u' + STATE_M << 8 + STATE_U << 16 + OP_NOOP
  .int 'm' + STATE_M << 8 + STATE_M << 16 + OP_RESET
  .int 'l' + STATE_U << 8 + STATE_L << 16 + OP_NOOP
  .int 'm' + STATE_U << 8 + STATE_M << 16 + OP_RESET
  .int '(' + STATE_L << 8 + STATE_OPEN_PAREN << 16 + OP_NOOP
  .int 'm' + STATE_L << 8 + STATE_M << 16 + OP_RESET

  .int '1' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '2' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '3' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '4' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '5' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '6' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '7' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '8' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int '9' + STATE_OPEN_PAREN << 8 + STATE_MULTIPLICAND << 16 + OP_COPY_MULTIPLICAND_DIGIT
  .int 'm' + STATE_OPEN_PAREN << 8 + STATE_M << 16 + OP_RESET

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

  .int 'm' + STATE_MULTIPLICAND << 8 + STATE_M << 16 + OP_RESET
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
  .int 'm' + STATE_COMMA << 8 + STATE_M << 16 + OP_RESET

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
  .int 'm' + STATE_MULTIPLIER << 8 + STATE_M << 16 + OP_RESET

  .int ')' + STATE_MULTIPLIER << 8 + STATE_START << 16 + OP_MULTIPLY

automaton_table_end_pointer = .

times_string:
  .asciz " * "

newline:
  .asciz "\n"


message:
  .asciz "hello world\n"
len = .-message

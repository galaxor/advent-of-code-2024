.text            
.global _start
_start:

  # The callee-save registers are x19-x28.

  # x19 will store the number of bytes left in the playfield.
  mov x19, PLAYFIELD_SIZE

read_playfield_loop:
  # Read
  mov x8, 0x3f
  mov x0, 1
  ldr x1, =playfield_buffer
  add x1, x1, PLAYFIELD_SIZE
  sub x1, x1, x19
  mov x2, x19
  svc 0

  sub x19, x19, x0
  cmp x0, 0
  b.ne read_playfield_loop

  # Convert the playfield into the preferred format, and measure it.
  # Also figure out where the guard is and what direction they're facing.


  # x1 has the playfield_buffer pointer
  ldr x1, =playfield_buffer
  # x2 has the playfield_buffer end pointer
  mov x2, x1
  add x2, x2, PLAYFIELD_SIZE
  sub x2, x2, x19

  # x3 has the playfield pointer
  ldr x3, =playfield

  # x4 has the playfield width
  mov x4, 0
  # x5 has the playfield height
  mov x5, 0

  # x6 has the guard x
  # x7 has the guard y
  # x8 has the guard direction
  mov x8, 0

  # x13 has the current X position
  mov x13, 0
  # x14 has the current Y position
  mov x14, 0


  # Load the character from the playfield buffer.
  ldrb w0, [x1]

playfield_init_loop:
  # We'll check for all the directions.
  # x9 will be 0 if we didn't find a direction and -1 if we did
  cmp x0, '^' 
  csetm x9, eq
  # If the direction is up, x8 should be set to 0, which is the default, so we don't need to change it.
  # We only needed to set x9 to the "we found a direction" thing.

  mov x11, -1

  cmp x0, '>'
  mov x10, 1
  csel x8, x10, x8, eq
  csel x9, x11, x9, eq

  cmp x0, 'v'
  mov x10, 2
  csel x8, x10, x8, eq
  csel x9, x11, x9, eq

  cmp x0, '<'
  mov x10, 3
  csel x8, x10, x8, eq
  csel x9, x11, x9, eq

  # Now, x8 should have one of 0=up, 1=right, 2=down, 3=left
  # x9 should have 0 if we didn't find a direction and -1 if we did.

  # If we found a direction, emit . instead of the character we read into x0.
  cmp x9, -1
  mov x12, '.' 
  csel x0, x12, x0, eq

  # If we found the guard's position, set it.
  csel x6, x13, x6, eq
  csel x7, x14, x7, eq

  # Emit either the character we read or, if that contained a direction, emit 'X'.
  str x0, [x3]

  
  # Advance the playfield pointer and the playfield buffer pointer.
  add x3, x3, 1
  add x1, x1, 1

  # Load the character from the playfield buffer.
  ldrb w0, [x1]

  # If this is a '\n', advance the Y position, set the X position to 0, and skip this character by advancing the playfield buffer again.
  cmp x0, '\n' 

  # Advance the playfield buffer pointer if it was '\n'
  add x9, x1, 1
  csel x1, x9, x1, eq

  # We have to load again.  This will either get us the same character or the next one.
  # If this goes beyond the buffer, it's okay, because we have one extra zero-byte at the end of the buffer for this purpose.
  ldrb w0, [x1]

  # If it's \n, then X is the playfield width.
  csel x4, x13, x4, eq

  # Set the X position to ('\n')? 0 : X+1
  add x9, x13, 1
  mov x30, 0
  csel x13, x30, x9, eq

  # Set the Y position to (\n)? Y+1 : Y
  add x9, x14, 1
  csel x14, x9, x14, eq
  
  cmp x1, x2
  b.lt playfield_init_loop

  
playfield_initted:
  # Save the precious values we found.

  # Add 1 to the playfield width because right now the width is actually one less than it should be because of zero-indexing.
  ldr x0, =playfield_width
  add x4, x4, 1
  str x4, [x0]

  # There's always an extra \n at the end, so we don't need to add 1 to the playfield height.
  ldr x1, =playfield_height
  str x14, [x1]
  # I also want playfield_height in x5.
  mov x5, x14

  ldr x2, =guard_x
  str x6, [x2]

  ldr x3, =guard_y
  str x7, [x3]

  ldr x9, =guard_direction
  str x8, [x9]

start_playing:

  # x6 is guard_x
  # x7 is guard_y

  # x4 is playfield_width
  # x5 is playfield_height

  # x2 is the &playfield
  ldr x2, =playfield

  # x8 is guard_direction

  # x9 is &guard_velocity_x
  ldr x9, =guard_velocity_x
  # x10 is &guard_velocity_y
  ldr x10, =guard_velocity_y

  # x25 is the number of unique squares the guard has been on.
  mov x25, 0

  # Load the character that's at the guard's current position.  It will be '.'.
  mov x0, '.' 

  # Load x13 with the current index into the playfield.
  # x13 = Y * playfield_width + X
  madd x13, x7, x4, x6

  mov x23, 'X' 

step_loop:
  # Call the cycle_maker subroutine.
  # We have to push all the caller-save registers.
  # The caller-save registers are x0-x18.  Of those, we're using 2, 4-10.
  # The callee-save registers are x19-x28.

  # We have to keep the stack aligned to 16 bytes.  There isn't an easy
  # push/pop command, so we'll allocate the space all at once and then push each
  # register by itself.
  # I got this idea from https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/using-the-stack-in-aarch64-implementing-push-and-pop

  # We're saving 8 8-byte registers.
  sub sp, sp, 8 * 8
  str x2, [sp, 8*0]
  str x4, [sp, 8*1]
  str x5, [sp, 8*2]
  str x6, [sp, 8*3]
  str x7, [sp, 8*4]
  str x8, [sp, 8*5]
  str x9, [sp, 8*6]
  str x10, [sp, 8*7]

  bl cycle_maker

  # Now get everything back off the stack
  ldr x2, [sp, 8*0]
  ldr x4, [sp, 8*1]
  ldr x5, [sp, 8*2]
  ldr x6, [sp, 8*3]
  ldr x7, [sp, 8*4]
  ldr x8, [sp, 8*5]
  ldr x9, [sp, 8*6]
  ldr x10, [sp, 8*7]
  add sp, sp, 8 * 8

  # What is at our feet?  If it's a '.', add 1 to the number of unique squares we've been on, and change it to an X.
  cmp x0, '.' 
  cset x24, eq
  add x25, x25, x24

  # Store the X at our feet.
  strb w23, [x2, x13]
  

  # Let's have the guard take a speculative step so we can see what's at their new spot.
  # Load the guard's (x, y) velocities into (x11, x12)
  ldr x11, [x9, x8, LSL#3]
  ldr x12, [x10, x8, LSL#3]

  # Add the guard's current position to their velocity to see what their new position is.
  add x11, x11, x6
  add x12, x12, x7


  # x13 = Y * playfield_width + X
  madd x13, x12, x4, x11

  # Use x13 as an index into the playfield.
  ldrb w0, [x2, x13]

  # Set x14 to the direction we'd be facing if we had to turn to the right.
  add x14, x8, 1
  mov x15, 0
  cmp x8, 3
  csel x14, x14, x15, le

  # If that step would not lead us to a '#', we should turn to the right and not take that step.
  cmp x0, '#'
  # If it's a #, turn to the right.
  csel x8, x14, x8, eq
  # If it's not a #, take the step.
  csel x6, x11, x6, ne
  csel x7, x12, x7, ne
  
  # We'll set x20 to be 1 if we left the playfield
  mov x20, 0

  # If the new position is outside the playfield, report doneness.
  # x11 is where the guard would end up (X)
  # x12 is where the guard would end up (Y)

  # x4 is playfield_width
  # x5 is playfield_height

  # x6 is guard_x
  # x7 is guard_y

  cmp x6, -1
  cset x19, le
  orr x20, x20, x19

  cmp x6, x4
  cset x19, ge
  orr x20, x20, x19

  cmp x7, -1
  cset x19, le
  orr x20, x20, x19

  cmp x7, x5
  cset x19, ge
  orr x20, x20, x19

  # Load x0 with what is at our feet
  # x13 = Y * playfield_width + X
  madd x13, x7, x4, x6

  # Use x13 as an index into the playfield.
  ldrb w0, [x2, x13]
  
  # x20 is 1 if we left the playfield and 0 if not.
  cmp x20, 0
  b.eq step_loop

  mov x0, x25
  bl int_to_decimal_string

  # This puts the start of the output string in x0 and the length in x1

  # The write call needs the start of the string in x1 and the length in x2
  mov x8, 0x40
  mov x2, x1
  mov x1, x0
  mov x0, 1
  svc 0

  mov x8, 0x40
  mov x0, 1
  ldr x1, =newline
  mov x2, 1
  svc 0
  

  # Exit
  mov x8, 0x5d
  mov x0, 0
  svc 0


int_to_decimal_string:
  # To print out number:
  # Initialize a buffer to hold the digits. We'll fill the buffer from back to front.
  # We return a pointer to the beginning of the number buffer in r0.
  # The buffer ends at output_number_buffer_end.

  # start_of_loop
  #   x0 = (the current number) / 10
  #   x1 = divisor (ten)
  #   x2 = (the current number) % 10
  #   put x1 on the buffer
  #   set the current number to x0
  #   Is the current number 0?  If not, go back to loop.

  mov x1, #10

  # r4 is the pointer into the output buffer (starting at "output_number_buffer").
  # We need the pointer to start at the back.
  ldr x4, =output_number_buffer
  mov x5, #BUFFER_SIZE
  add x4, x4, x5

int_to_decimal_string_loop:
  # Set the pointer to where we're putting the digit.
  sub x4, x4, #1

  udiv x10, x0, x1
  msub x2, x10, x1, x0
  mov x0, x10

  # The digit is in x2.  Ascii-fy it.
  add x2, x2, #0x30
  # Put the digit into the buffer
  strb w2, [x4]
  cmp x0, #0
  b.ne int_to_decimal_string_loop

  # The buffer is filled.  Return it.
  # x0 will be the pointer to the start of the number string.
  mov x0, x4

  # r1 will be the length of the string.
  ldr x1, =output_number_buffer_end
  sub x1, x1, x0
  
  blr lr

cycle_maker:
  # Don't actually do anything.
  blr lr



.data

helloworld:
  .asciz "Hello, world\n"
hello_len = . - helloworld

PLAYFIELD_SIZE = 256 * 256
playfield_buffer:
  .space PLAYFIELD_SIZE + 1

  # When we're reading this, we might end up reading one byte past the end of
  # the buffer before we notice it. So let's put an extra byte there so we
  # don't segfault.

playfield:
  .space PLAYFIELD_SIZE

playfield_width: .quad 0
playfield_height: .quad 0
guard_x: .quad 0
guard_y: .quad 0
guard_direction: .quad 0

ghost_guard_x: .quad 0
ghost_guard_y: .quad 0
ghost_guard_direction: .quad 0

BUFFER_SIZE = 8192
output_number_buffer: .space BUFFER_SIZE
output_number_buffer_end = .

newline: .byte '\n' 


# Directions are up, right, down, left

guard_velocity_x: .quad 0, 1, 0, -1
guard_velocity_y: .quad -1, 0, 1, 0

turning_points_x: .ds.d PLAYFIELD_SIZE
turning_points_y: .ds.d PLAYFIELD_SIZE

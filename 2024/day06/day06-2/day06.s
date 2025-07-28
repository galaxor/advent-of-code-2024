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

  # x25 is the number of squares where we could add an obstacle to cause a cycle.
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

  # We're saving 10 8-byte registers.
  sub sp, sp, 8 * 10
  str x0, [sp, 8*0]
  str x2, [sp, 8*1]
  str x4, [sp, 8*2]
  str x5, [sp, 8*3]
  str x6, [sp, 8*4]
  str x7, [sp, 8*5]
  str x8, [sp, 8*6]
  str x9, [sp, 8*7]
  str x10, [sp, 8*8]
  str x13, [sp, 8*9]

  bl cycle_maker

  # The return value is in x0:  It's 0 if it's not a cycle and 1 if it is.
  add x25, x25, x0

  # Now get everything back off the stack
  ldr x0, [sp, 8*0]
  ldr x2, [sp, 8*1]
  ldr x4, [sp, 8*2]
  ldr x5, [sp, 8*3]
  ldr x6, [sp, 8*4]
  ldr x7, [sp, 8*5]
  ldr x8, [sp, 8*6]
  ldr x9, [sp, 8*7]
  ldr x10, [sp, 8*8]
  ldr x13, [sp, 8*9]
  add sp, sp, 8 * 10

  # What is at our feet?  If it's a '.', add 1 to the number of unique squares we've been on, and change it to an X.
  cmp x0, '.' 
  cset x24, eq

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
  csel x14, x14, x15, lt

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
  # The callee-save registers are x19-x28.
  # We're using 19 and 20.
  # We're saving 2 8-byte registers.
  sub sp, sp, 8 * 6
  str x19, [sp, 8*0]
  str x20, [sp, 8*1]
  str x21, [sp, 8*2]
  str x22, [sp, 8*3]
  str x23, [sp, 8*4]

  # Initialize x1 to the length of the turning point list.
  mov x1, 0

  ldr x21, =turning_points_x
  ldr x22, =turning_points_y
  ldr x23, =turning_points_direction

  # Try putting an obstacle in front of us.  Then run that scenario and see if we find a cycle.

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

  # If there's an X or a # on the playfield in that position, quit and report that this position doesn't work.
  # The # because then we can't add a new obstacle there, and the X because if
  # we put a new obstacle there, we would've bumped into it already in our trek so
  # far.
  cmp x0, '.' 
  # We want to return 0 if we couldn't place an obstacle.
  mov x0, 0
  b.ne cycle_maker_end

  # x16 and x17 are the (x, y) location where we put the obstacle (so we can take it back if it doesn't work out).
  mov x16, x11
  mov x17, x12

  # Actually place the obstacle in the playfield
  mov x0, '#' 
  strb w0, [x2, x13]
  

  # We've placed our obstacle or died trying.  Now let's let the guard walk around and see if it causes a cycle.
  
cycle_maker_step_loop:
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

  # If it's a #, check if it's in the list of turns we've made.  If it is, then
  # this is a cycle!  If it's not a cycle, add it to the list for later checking.
  cmp x0, '#'
  b.ne cycle_maker_step_no_cycle

  # Go through the list of turns and see if this one is on it.
  # Remember, (x6, x7) = (X, Y), and x8 is direction.
  # x18 is a list iterator.
  mov x18, -1 

turning_point_list_check_loop:
  add x18, x18, 1

  # x1 has the length of the turning point list.
  cmp x18, x1
  b.ge cycle_maker_obstacle_no_cycle

  # x21 has =turning_points_x
  # x22 has =turning_points_y
  # x23 has =turning_points_direction
  ldr x19, [x21, x18, lsl#3]
  cmp x19, x6
  b.ne turning_point_list_check_loop
  ldr x19, [x22, x18, lsl#3]
  cmp x19, x7
  b.ne turning_point_list_check_loop
  ldr x19, [x23, x18, lsl#3]
  cmp x19, x8
  b.ne turning_point_list_check_loop

  # If we're here, that means we've found a cycle!

  # I want to print out the (x, y) location where we put the obstacle, for debugging.
  # I'll call a print function.
  # I'm just gonna save all the caller-save registers because I don't want to figure out if there's any we're not using.
  sub sp, sp, 8 * 18
  str x0, [sp, 8*0]
  str x1, [sp, 8*1]
  str x2, [sp, 8*2]
  str x3, [sp, 8*3]
  str x4, [sp, 8*4]
  str x5, [sp, 8*5]
  str x6, [sp, 8*6]
  str x7, [sp, 8*7]
  str x8, [sp, 8*8]
  str x9, [sp, 8*9]
  str x10, [sp, 8*10]
  str x13, [sp, 8*11]
  str x14, [sp, 8*12]
  str x15, [sp, 8*13]
  str x16, [sp, 8*14]
  str x17, [sp, 8*15]
  str x18, [sp, 8*16]
  str lr, [sp, 8*17]

  # x16 and x17 are the (x, y) location where we put the obstacle (so we can take it back if it doesn't work out).
  mov x0, x16
  mov x1, x17
  
  bl debug_print_obstacle_location

  ldr x0, [sp, 8*0]
  ldr x1, [sp, 8*1]
  ldr x2, [sp, 8*2]
  ldr x3, [sp, 8*3]
  ldr x4, [sp, 8*4]
  ldr x5, [sp, 8*5]
  ldr x6, [sp, 8*6]
  ldr x7, [sp, 8*7]
  ldr x8, [sp, 8*8]
  ldr x9, [sp, 8*9]
  ldr x10, [sp, 8*10]
  ldr x13, [sp, 8*11]
  ldr x14, [sp, 8*12]
  ldr x15, [sp, 8*13]
  ldr x16, [sp, 8*14]
  ldr x17, [sp, 8*15]
  ldr x18, [sp, 8*16]
  ldr lr, [sp, 8*17]
  add sp, sp, 8 * 18


  mov x0, 1
  b cycle_maker_end

cycle_maker_obstacle_no_cycle:
  # We bumped into an obstacle, but it wasn't a cycle, so let's add that
  # obstacle to the list of obstacles and then take the next cyclemaker step.

  # The obstacle we want to add to the list is at (X, Y, Direction) = (x6, x7, x8)
  # x1 has the length of the turning point list.
  # x21 has =turning_points_x
  # x22 has =turning_points_y
  # x23 has =turning_points_direction
  str x6, [x21, x1, lsl#3]
  str x7, [x22, x1, lsl#3]
  str x8, [x23, x1, lsl#3]
  add x1, x1, 1
  

cycle_maker_step_no_cycle:
  # Set x14 to the direction we'd be facing if we had to turn to the right.
  add x14, x8, 1
  mov x15, 0
  cmp x8, 3
  csel x14, x14, x15, lt

  # Use x13 as an index into the playfield.
  ldrb w0, [x2, x13]

  # If that step would lead us to a '#', we should turn to the right and not take that step.
  cmp x0, '#'
  # If it's a #, turn to the right.
  csel x8, x14, x8, eq
  # If it's not a #, take the step.
  csel x6, x11, x6, ne
  csel x7, x12, x7, ne

  
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


  # Get ready for another iteration of the cycle maker step loop.

  # x13 = Y * playfield_width + X
  madd x13, x7, x4, x6


  # x20 is 1 if we left the playfield and 0 if not.
  cmp x20, 0

  # If we took the step and it landed us out of bounds, then loading from that
  # location could cause a segfault.
  # So if we stepped out of bounds, we'll load from playfield[0] instead of
  # playfield[x13]. We'll throw out the value anyway.
  # This is just a way to remove a branch -- load unconditionally from ...
  # somewhere.

  mov x0, 0
  csel x13, x13, x0, eq
  
  # Use x13 as an index into the playfield.
  ldrb w0, [x2, x13]

  b.eq cycle_maker_step_loop

  # We have left the playfield. Return that this obstacle does not make a cycle.
  mov x0, 0

cycle_maker_end:
  # Undo the barrier we placed.

  # x16 and x17 are the (x, y) location where we put the obstacle (so we can take it back if it doesn't work out).

  # x13 = Y * playfield_width + X
  madd x13, x17, x4, x16

  # x2 is the &playfield
  mov x19, '.'
  strb w19, [x2, x13]

  # The callee-save registers are x19-x28.
  ldr x19, [sp, 8*0]
  ldr x20, [sp, 8*1]
  ldr x21, [sp, 8*2]
  ldr x22, [sp, 8*3]
  ldr x23, [sp, 8*4]
  add sp, sp, 8 * 6

  # Return.
  blr lr

debug_print_obstacle_location:
  # (x0, x1) is the (x, y) location of the obstacle that caused a cycle. Print it out.

  sub sp, sp, 8*4
  str x0, [sp, 8*0]
  str x1, [sp, 8*1]
  str lr, [sp, 8*2]

  # The write call needs the start of the string in x1 and the length in x2
  mov x8, 0x40
  mov x0, 1
  ldr x1, =left_paren
  mov x2, 1
  svc 0

  ldr x0, [sp, 8*0]
  bl int_to_decimal_string

  mov x8, 0x40
  # int_to_decimal_string put the string in x0 and the length in x1.
  mov x2, x1
  mov x1, x0
  mov x0, 1
  svc 0

  mov x8, 0x40
  mov x0, 1
  ldr x1, =comma_space
  mov x2, 2
  svc 0

  ldr x0, [sp, 8*1]
  bl int_to_decimal_string
  
  mov x8, 0x40
  # int_to_decimal_string put the string in x0 and the length in x1.
  mov x2, x1
  mov x1, x0
  mov x0, 1
  svc 0

  mov x8, 0x40
  mov x0, 1
  ldr x1, =right_paren_enter
  mov x2, 2
  svc 0

  
  ldr x0, [sp, 8*0]
  ldr x1, [sp, 8*1]
  ldr lr, [sp, 8*2]
  add sp, sp, 8*4
  

  # Return.
  blr lr



.data

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
left_paren: .byte '('
comma_space: .ascii ", "
right_paren_enter: .ascii ")\n"


# Directions are up, right, down, left

guard_velocity_x: .quad 0, 1, 0, -1
guard_velocity_y: .quad -1, 0, 1, 0

# List of turning points we've encountered during a cycle check.
turning_points_x: .ds.d PLAYFIELD_SIZE
turning_points_y: .ds.d PLAYFIELD_SIZE
turning_points_direction: .ds.d PLAYFIELD_SIZE

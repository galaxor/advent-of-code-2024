.bss
buffer:
  buffer_size = 8192
  .space buffer_size

current_number_buffer:
  .space buffer_size

# report_array has space for 8192 uint64s.
report_array:
  .ds.d buffer_size

.data
hello:
  .ascii "Hello there, world! B-)\n\0"

hello_len = . - hello

goodbye:
  .ascii "Donezo\n\0"

goodbye_len = . - goodbye

newline: .ascii "\n"


.text
.globl _start

_start:
  # safe registers:  RBX, R12–R15

  # r15 is "number of safe reports"
  xor %r15, %r15

  # rbx stores several boolean values
  end_of_report_found = 32
  previous_number_initialized = 16
  report_direction_initialized = 8
  report_direction_ascending = 4
  report_safe_initialized = 2
  report_safe_safe = 1

  end_of_report_found_offset = 5
  previous_number_initialized_offset = 4
  report_direction_initialized_offset = 3
  report_direction_ascending_offset = 2
  report_safe_initialized_offset = 1
  report_safe_safe_offset = 0

  mov $(report_safe_initialized | report_safe_safe), %rbx

  # r8 is the current index in "buffer".
  xor %r8, %r8

  # r12 is going to be the offset into the destination string (current_number_buffer).
  xor %r12, %r12

  # r13 is the "current number"
  xor %r13, %r13
  # r14 is the "previous number"
  xor %r14, %r14

# Read an entire report's worth of numbers into the report_array.

# %r8 is the current index in "buffer".
# %r14 is how many levels we have in the report.
xor %r14, %r14

get_bytes:
  # Attempt to read a buffer of bytes
  mov $0, %rax  # syscall: read
  mov $0, %rdi             # fd = stdin
  mov $buffer, %rsi        # buf = buffer
  mov $buffer_size, %rdx   # count = 8192
  syscall
  
  # The number of bytes returned is in %rax. Let's move it to %r11 so we can mess with %rax.
  mov %rax, %r11
  and $-1, %r11  # Set or clear the Z flag, to know if we got bytes.

  # If we got no bytes, we are done processing input.
  # Let's assume the final line ended with a linefeed, so if we hit the end, we are actually done.
  jz donezo
  

  xor %r8, %r8           # The index into the buffer
number_copy_loop:
  # Examine the bytes.  Copy them one by one until we find a space or line feed.
  mov $buffer, %r9        
  xor %rax, %rax
  mov (%r9, %r8), %al

  # I want to move the value from %al into the destination string.
  mov $current_number_buffer, %rdx
  mov %al, (%rdx, %r12)

  or $end_of_report_found, %rbx  # did we find the end of the report? Let's say yes.
  cmp $0xa, %al
  je end_of_number_found
  xor $end_of_report_found, %rbx  # We did not find the end of the report after all.
  cmp $0x20, %al
  je end_of_number_found
  inc %r12
  inc %r8

  # If we hit the end of the buffer, try to get more data.  We're not done til we hit eof!
  cmp %r11, %r8
  jae get_bytes

  jmp number_copy_loop


end_of_number_found:
  # Now we convert the string we stored in current_number_buffer into an integer.

  xor %rcx, %rcx  # This points to the current character in current_number_buffer.
  dec %r12  # This points to the last character in the current_number_buffer

  xor %r13, %r13  # We're saving the current integer into %r13.

  xor %rax, %rax  # %rax will have the current digit

  mov $current_number_buffer, %r9
  
convert_number:
  xor %rax, %rax
  mov (%r9, %rcx), %al
  sub $0x30, %al  # 0x30 is ascii for '0'.
  add %rax, %r13

  # If we're not at the end of the current_number_buffer, multiply by 10.
  cmp %rcx, %r12
  jbe we_have_current_number
  mov %r13, %r10
  sal $3, %r13
  add %r10, %r13
  add %r10, %r13

  # Go on to the next digit of the input buffer
  inc %rcx
  jmp convert_number
  

we_have_current_number:
  mov $report_array, %rax
  mov %r13, (%rax, %r14, 8)

  inc %r14
  test $end_of_report_found, %rbx
  jnz we_have_full_report

read_next_number:
  # If we hit the end of the buffer, try to get more data.  We're not done til we hit eof!
  xor %r12, %r12  # Start over reading into current_number_buffer

  # Advance the pointer in buffer.
  inc %r8

  # If we're at the end of the buffer, we need more bytes.
  cmp %r8, %r11
  jle get_bytes

  jmp number_copy_loop


we_have_full_report:
  # r14 should store the index of the last element of the report array, not the first open element.
  dec %r14

  # But actually, we're going to store that index in r12, because r14 will have the "previous number".
  mov %r14, %r12

  # r10 will hold the currently masked-out number.
  mov $-2, %r10

maskout_loop:
  # Advance to the next masked-out number.
  inc %r10

  # If we've advanced beyond the end of the report array, there is nothing more
  # we can mask out, and there is no saving this report.  Move to the next
  # report.
  cmp %r10, %r12
  jge report_is_saveable
  
  # Go back to the beginning of the report array.
  xor %r14, %r14

  # Go back to the beginning of the current number buffer
  xor %rdx, %rdx

  # Advance the buffer index beyond this report.
  inc %r8
  inc %r8

  jmp number_copy_loop

report_is_saveable:
  # rcx will hold the index of the report element we are currently looking at.
  xor %rcx, %rcx

  # Initialize by storing the first number into "previous number". We'll start at the second number.
  # Bump up what we mean by "first" and "second" number if they are the masked out numbers.
  mov $report_array, %rax
  xor %rdx, %rdx
  cmp $0, %r10
  sete %dl
  add %rdx, %rcx
  # If the first non-masked-out number is after the end of the report, the report is safe.
  cmp %rcx, %r12
  jl safe_by_default
  mov (%rax, %rcx, 8), %r14
  inc %rcx
  cmp %rcx, %r10
  sete %dl
  add %rdx, %rcx
  # If the second non-masked-out number is after the end of the report, the report is safe.
  cmp %rcx, %r12
  jl safe_by_default
  mov (%rax, %rcx, 8), %r13

  # Assume the report is safe until proven otherwise.
  mov $(previous_number_initialized | report_safe_initialized | report_safe_safe), %rbx

report_safety_logic:
  # booleans are in %rbx
  # current number is in %r13
  # r14 is the "previous number"

  # This is where we check the relationship of the previous number with this
  # number and set the report direction and whether the report is safe and
  # stuff.

# if( current_number > previous_number ) {
#   if( current_number - previous_number > 3 ) {
#     report_safe = false
#   } else {
#     if( report_direction_initialized ) {
#       if( report_direction != ascending ) {
#         report_safe = false
#       }
#     } else {
#       report_direction_initialized = true
#       report_direction = ascending
#     }
#   }
# } 
# if( current_number < previous_number ) {
#   if( previous_number - current_number > 3 ) {
#     report_safe = false
#   } else {
#     if( report_direction_initialized ) {
#       if( report_direction != descending ) {
#         report_safe = false
#       }
#     } else {
#       report_direction_initialized = true
#       report_direction = descending
#     }
#   }
# }

  cmp %r13, %r14                               # if( current_number > previous_number ) 
  jge not_ascending                             
  mov %r13, %rax 
  sub %r14, %rax
  cmp $3, %rax                                
  jbe ascending_but_not_by_more_than_3
  btr $report_safe_safe_offset, %rbx                #   if( current_number - previous_number > 3) report_safe = false
  bts $report_safe_initialized_offset, %rbx
  jmp ready_for_next_number

ascending_but_not_by_more_than_3:
  test $report_direction_initialized, %rbx     # if( report_direction_initialized )
  jz ascending_report_not_initialized          
  test $report_direction_ascending, %rbx       #   if( report_direction != ascending )
  jnz ready_for_next_number                    
  btr $report_safe_safe_offset, %rbx                #   report_safe = false
  bts $report_safe_initialized_offset, %rbx
  jmp ready_for_next_number
  
ascending_report_not_initialized:
  bts $report_direction_initialized_offset, %rbx
  bts $report_direction_ascending_offset, %rbx
  jmp ready_for_next_number
  

not_ascending:
  cmp %r13, %r14                               # if( current_number < previous_number ) 
  je not_descending_either
  mov %r14, %rax 
  sub %r13, %rax
  cmp $3, %rax                                
  jbe descending_but_not_by_more_than_3
  btr $report_safe_safe_offset, %rbx                #   if( previous_number - current_number > 3) report_safe = false
  bts $report_safe_initialized_offset, %rbx
  jmp ready_for_next_number

descending_but_not_by_more_than_3:
  test $report_direction_initialized, %rbx     # if( report_direction_initialized )
  jz descending_report_not_initialized          
  test $report_direction_ascending, %rbx       #   if( report_direction == ascending )
  jz ready_for_next_number                    
  btr $report_safe_safe_offset, %rbx                #   report_safe = false
  bts $report_safe_initialized_offset, %rbx
  jmp ready_for_next_number
  
descending_report_not_initialized:
  bts $report_direction_initialized_offset, %rbx
  btr $report_direction_ascending_offset, %rbx
  jmp ready_for_next_number

not_descending_either:
  btr $report_safe_safe_offset, %rbx   # Report is not ascending or descending.  Unsafe.
  bts $report_safe_initialized_offset, %rbx

ready_for_next_number:
  # Advance the index, bumping it if they are masked out.
  # Then we see if we hit the end of the report.  If it's safe, say so.  If not, try the next mask-out.

  # The current number is now the previous number.
  mov %r13, %r14

  # Advance the index in the report array, bumping it if the new one is the masked-out number.
  inc %rcx
  # If that's the currently-masked-out number, skip it.
  cmp %rcx, %r10
  sete %dl
  add %rdx, %rcx

  # If the index is after the end of the report, check whether the report is safe and act accordingly.
  # Otherwise, read the next number from the report.
  cmp %rcx, %r12
  jl check_safe

  mov $report_array, %rax
  mov (%rax, %rcx, 8), %r13
  jmp report_safety_logic

safe_by_default:
  or $(report_safe_initialized | report_safe_safe), %rbx

check_safe:
  test $report_safe_safe, %rbx
  # If it's unsafe, we need to check if there's more numbers we could mask out.  If so, try the next one.
  je maskout_loop

  # We know it's safe.
  inc %r15

  # Reset all the booleans for the next report.
  mov $(report_safe_initialized | report_safe_safe), %rbx

  # Start constructing the next report.
  # Reset the index of current_number_buffer
  xor %r12, %r12

  # Advance the index in the buffer and check if we're out of bytes.
  inc %r8
  
  # If we hit the end of the buffer, try to get more data.  We're not done til we hit eof!
  cmp %r11, %r8
  jae get_bytes

  jmp number_copy_loop

  
donezo:
  # To print out number:
  # Initialize a buffer to hold the digits. We'll fill the buffer from back to front.

  # start_of_loop
  #   %rax = (the current number) / 10
  #   %rdx = (the current number) % 10
  #   put %rdx on the buffer
  #   set the current number to %rax
  #   Is the current number 0?  If not, go back to loop.


  # rax is the number as we manipulate it.
  # rcx is the index into the output buffer (we're re-using "current_number_buffer".
  # r14 is the address of current_number_buffer
  # r10 stores the number ten, so we can divide by it

  mov %r15, %rax
  mov $buffer_size, %rcx
  dec %rcx
  mov $current_number_buffer, %r14
  mov $10, %r10

  # Make sure there's a "\n" at the end.
  movb $0xa, (%r14, %rcx)

number_figure_out_loop:
  dec %rcx
  xor %rdx, %rdx
  div %r10
  add $0x30, %rdx   # ascii-ify the digit
  mov %dl, (%r14, %rcx)
  cmp $0, %rax
  jnz number_figure_out_loop


  # Output the final number
  
  mov $1, %rax # syscall: sys_write
  mov $1, %rdi # file descriptor: stdout
  mov $current_number_buffer, %rsi
  add %rcx, %rsi # string address
  mov $buffer_size, %rdx    # string length
  sub %rcx, %rdx
  syscall # calls the kernel
  

  
  mov $1, %rax # syscall: sys_write
  mov $1, %rdi # file descriptor: stdout
  mov $goodbye, %rsi # string address
  mov $goodbye_len, %rdx # string length
  syscall # calls the kernel
  

  mov $60, %rax # syscall: sys_exit
  xor %rdi, %rdi # exit status: 0
  syscall # calls the kernel


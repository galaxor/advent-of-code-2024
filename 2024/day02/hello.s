.bss
buffer:
  buffer_size = 8192
  .space buffer_size

current_number_buffer:
  .space buffer_size

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
  # booleans are in %rbx
  # current number is in %r13
  # r14 is the "previous number"

  bts $previous_number_initialized_offset, %rbx
  jnc ready_for_next_number

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
  # The current number is now the previous number.
  mov %r13, %r14

  # Check some stuff:
  # If this is not the end of the report, then get the next number.
  # If this is the end of the report, then update the number of safe reports and get ready for a new report.
  # Whether this is the end of the report is one of the booleans.

  test $end_of_report_found, %rbx
  jz read_next_number

  mov %rbx, %rax
  and $(report_safe_initialized | report_safe_safe), %rax
  cmp $(report_safe_initialized | report_safe_safe), %rax
  sete %al
  add %rax, %r15

  # Reset all the booleans for the next report.
  mov $(report_safe_initialized | report_safe_safe), %rbx

  
read_next_number:
  # If we hit the end of the buffer, try to get more data.  We're not done til we hit eof!
  xor %r12, %r12  # Start over reading into current_number_buffer

  # Advance the pointer in buffer.
  inc %r8

  # If we're at the end of the buffer, we need more bytes.
  cmp %r8, %r11
  jle get_bytes

  jmp number_copy_loop



donezo:
  # To print out number:
  # Initialize a buffer to hold the digits. We'll fill the buffer from back to front.
  # Initialize carry to be 0.

  # start_of_loop
  #   digit = (number & 0xF) + carry
  #   if digit >= 10
  #     carry = 1
  #     digit -= 10
  #   put digit in the buffer
  #   number >> 4
  #   if number > 0, go to start_of_loop


  # r13 is the number as we manipulate it.
  # rcx is the index into the output buffer (we're re-using "current_number_buffer".
  # bl is the digit
  # r10 is the address of current_number_buffer
  # al is "carry".

  mov %r15, %r13
  mov $buffer_size, %rcx
  dec %rcx
  mov $current_number_buffer, %r10
  xor %rax, %rax

  # Make sure there's a "\n" at the end.
  movb $0xa, (%r10, %rcx)
  dec %rcx

number_figure_out_loop:
  mov %r13, %rbx
  and $0xf, %rbx
  add %rax, %rbx
  cmp $10, %rbx
  setae %al
  # Subtract either 0 or 10 from rbx, depending on whether %al is 0 or 1. But do it without any branches.
  # i.e., %rdx is %al multiplied by 10. Subtract it from rbx.
  mov %rax, %rdx
  sal $3, %rdx
  add %rax, %rdx
  add %rax, %rdx
  sub %rdx, %rbx

  add $0x30, %rbx   # ascii-ify the digit.
  mov %bl, (%r10, %rcx)
  dec %rcx
  sar $4, %r13
  ja number_figure_out_loop

  # If carry is 1, put the final digit in the buffer.
  # Otherwise, increment %rcx because there is no digit here to print.
  # Actually, we'll just lay down '1' no matter what.  We'll only use the carry
  # to decide whether to increment rcx.  If there was a carry, we don't
  # increment rcx, and the '1' gets printed out.  If there was no carry, we
  # increment rcx and the '1' doesn't print out.
  movb $0x31, (%r10, %rcx)

  # Add 0 to rcx if carry was 1.
  # Add 1 to rcx if carry was 0.
  not %rax
  and $1, %rax
  add %rax, %rcx

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


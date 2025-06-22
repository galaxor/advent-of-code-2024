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

  xor %rbx, %rbx

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
  

  xor %rcx, %rcx           # The index into the buffer
number_copy_loop:
  # Examine the bytes.  Copy them one by one until we find a space or line feed.
  mov $buffer, %r9        
  mov (%r9, %rcx), %al

  # I want to move the value from %al into the destination string.
  mov $current_number_buffer, %rdx
  mov %al, (%rdx, %r12)

  or $end_of_report_found, %rbx  # did we find the end of the report? Let's say yes.
  cmp $0xa, %al
  je end_of_string_found
  xor $end_of_report_found, %rbx  # We did not find the end of the report after all.
  cmp $0x20, %al
  je end_of_string_found
  inc %r12
  inc %rcx

  # If we hit the end of the buffer, try to get more data.  We're not done til we hit eof!
  cmp %r11, %rcx
  jae get_bytes

  jmp number_copy_loop


end_of_string_found:
  # Now we convert the string we stored in current_number_buffer into an integer.

  # %r13 is the current number, %r14 is the previous number
  mov %r13, %r14

  xor %rcx, %rcx  # %rcx has the current index into the number string, %r12 has the end index
  dec %r12  # This points to the last character in the number

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
  jg not_ascending                             
  mov %r14, %rax 
  sub %r13, %rax
  cmp $3, %rax                                
  jg ascending_but_not_by_more_than_3
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
  jl ready_for_next_number
  mov %r13, %rax 
  sub %r14, %rax
  cmp $3, %rax                                
  jg descending_but_not_by_more_than_3
  btr $report_safe_safe_offset, %rbx                #   if( previous_number - current_number > 3) report_safe = false
  bts $report_safe_initialized_offset, %rbx
  jmp ready_for_next_number

descending_but_not_by_more_than_3:
  test $report_direction_initialized, %rbx     # if( report_direction_initialized )
  jz descending_report_not_initialized          
  test $report_direction_ascending_offset, %rbx       #   if( report_direction == ascending )
  jz ready_for_next_number                    
  btr $report_safe_safe_offset, %rbx                #   report_safe = false
  bts $report_safe_initialized_offset, %rbx
  jmp ready_for_next_number
  
descending_report_not_initialized:
  bts $report_direction_initialized_offset, %rbx
  btr $report_direction_ascending_offset, %rbx
  jmp ready_for_next_number



ready_for_next_number:
  # The current number is now the previous number.
  mov %r13, %r14

  # Check some stuff:
  # If this is not the end of the report, then get the next number.
  # If this is the end of the report, then update the number of safe reports and get ready for a new report.
  # Whether this is the end of the report is one of the booleans.

  
  
  # If we hit the end of the buffer, try to get more data.  We're not done til we hit eof!
  cmp %r11, %rcx
  jae get_bytes

  jmp number_copy_loop



end_of_buffer_found:
  mov $1, %rax       # syscall: sys_write
  mov $1, %rdi       # file descriptor: stdout
  mov $current_number_buffer, %rsi   # string address
  mov %r12, %rdx     # string length
  syscall

  # Print a newline
  mov $1, %rax
  mov $1, %rdi
  mov $newline, %rsi
  mov $1, %rdx
  syscall
  

  mov $1, %rax # syscall: sys_write
  mov $1, %rdi # file descriptor: stdout
  mov $hello, %rsi # string address
  mov $hello_len, %rdx # string length
  syscall # calls the kernel

donezo:
  
  mov $1, %rax # syscall: sys_write
  mov $1, %rdi # file descriptor: stdout
  mov $goodbye, %rsi # string address
  mov $goodbye_len, %rdx # string length
  syscall # calls the kernel
  

  mov $60, %rax # syscall: sys_exit
  xor %rdi, %rdi # exit status: 0
  syscall # calls the kernel


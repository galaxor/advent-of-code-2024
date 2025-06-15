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


report_direction: .byte 0
report_safe: .byte 0
num_safe_reports: .quad 0
current_number: .quad 0
previous_number: .quad 0

.text
.globl _start

_start:

  # r12 is going to be the offset into the destination string (current_number_buffer).
  xor %r12, %r12

  # Attempt to read a buffer of bytes
  mov $0, %rax  # syscall: read
  mov $0, %rdi             # fd = stdin
  mov $buffer, %rsi        # buf = buffer
  mov $buffer_size, %rdx   # count = 8192
  syscall
  
  and $-1, %rax  # Set or clear the Z flag, to know if we got bytes.

  # If we got no bytes, we are done processing input.
  jz donezo
  

  xor %rcx, %rcx           # The index into the buffer
number_copy_loop:
  # Examine the bytes.  Copy them one by one until we find a space or line feed.
  mov $buffer, %rbx        
  mov (%rbx, %rcx), %al

  # I want to move the value from %al into the destination string.
  mov $current_number_buffer, %rdx
  mov %al, (%rdx, %r12)

  cmp $0x20, %al
  je end_of_string_found
  cmp $0xa, %al
  je end_of_string_found
  cmp $0, %al
  je end_of_string_found
  inc %r12
  inc %rcx
  cmp $buffer_size, %rcx 
  jae end_of_buffer_found
  jmp number_copy_loop


end_of_string_found:
  # Now we convert the string we stored in current_number_buffer into an integer.
  



end_of_buffer_found:
  mov $1, %rax       # syscall: sys_write
  mov $1, %rdi       # file descriptor: stdout
  mov $current_number_buffer, %rsi   # string address
  mov %rcx, %rdx     # string length
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


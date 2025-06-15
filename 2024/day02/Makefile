OUTPUTS := hello hello-nasm hello-gas-intel

all: $(OUTPUTS)

hello.o: hello.s
	as -g -o $@ $<

hello-gas-intel.o: hello-gas-intel.s
	as -g -o $@ $<

hello-nasm.o: hello-nasm.s
	nasm -g -f elf64 -o $@ $<

hello: hello.o
	ld -o hello hello.o

hello-nasm: hello-nasm.o
	ld -o hello-nasm hello-nasm.o

hello-gas-intel: hello-gas-intel.o
	ld -o hello-gas-intel hello-gas-intel.o


OUTPUTS := hello

all: $(OUTPUTS)

hello.o: hello.s
	as -g -o $@ $<

hello: hello.o
	ld -o hello hello.o

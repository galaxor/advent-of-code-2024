OUTPUTS := day06
OBJECTS := day06.o

all: $(OUTPUTS)

$(OBJECTS): %.o: %.s
	aarch64-linux-gnu-as -g -o $@ $<

$(OUTPUTS): %: %.o
	aarch64-linux-gnu-ld -o $@ $<

clean:
	rm $(OUTPUTS) $(OBJECTS)

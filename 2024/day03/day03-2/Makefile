OUTPUTS := day03
OBJECTS := day03.o

all: $(OUTPUTS)

$(OBJECTS): %.o: %.s
	# arm-linux-gnueabihf-as -march=armv7-m -mthumb -g -o $@ $<
	arm-linux-gnueabihf-as -g -o $@ $<

$(OUTPUTS): %: %.o
	arm-linux-gnueabihf-ld -o $@ $<

clean:
	rm $(OUTPUTS) $(OBJECTS)

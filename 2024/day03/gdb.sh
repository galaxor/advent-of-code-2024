#!/bin/bash

echo "m234" | qemu-arm -L /usr/arm-linux-gnueabihf -g 1234 ./day03 &
gdb-multiarch -q --nh -ex 'set architecture arm' -ex 'file day03' -ex 'target remote localhost:1234'

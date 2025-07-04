#!/bin/bash

CPU=
# CPU="-cpu cortex-m4"

cat little-input.txt | qemu-arm $CPU -L /usr/arm-linux-gnueabihf -g 1234 ./day03 &
gdb-multiarch -q --nh -ex 'set architecture arm' -ex 'file day03' -ex 'target remote localhost:1234'

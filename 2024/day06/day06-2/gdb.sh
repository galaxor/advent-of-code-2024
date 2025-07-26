#!/bin/bash

CPU=
# CPU="-cpu cortex-m4"

cat little-input.txt | qemu-aarch64 $CPU -L /usr/aarch64-linux-gnu -g 1234 ./day06 &
gdb-multiarch -q --nh -ex 'set architecture aarch64' -ex 'file day06' -ex 'target remote localhost:1234'

#!/bin/bash

echo "RISC-V Pipelined Processor Compilation"
echo "Compiling with iverilog..."

# Compile the pipelined processor
iverilog -o risc_v.vvp TestRiscV.v

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo "Running simulation..."
    vvp risc_v.vvp
    
    echo ""
    echo "Waveform file: riscv_tb.vcd"
    echo "View with: gtkwave riscv_tb.vcd"
else
    echo "Compilation failed!"
    exit 1
fi
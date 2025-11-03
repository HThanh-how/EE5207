#!/bin/bash

echo "=========================================="
echo "Single Cycle RISC-V Processor - Local Test"
echo "=========================================="

cd "$(dirname "$0")"

# Check if flist exists
if [ ! -f flist ]; then
    echo "Creating file list..."
    make create_filelist
fi

# Try different simulators
if command -v xrun &> /dev/null; then
    echo "Using Cadence Xcelium (xrun)..."
    xrun -access +rwc -f ./flist
elif command -v vlog &> /dev/null; then
    echo "Using ModelSim/QuestaSim..."
    vlog -sv -f flist
    vsim -c -do "run -all; quit" -voptargs=+acc tbench
elif command -v iverilog &> /dev/null; then
    echo "Using Icarus Verilog..."
    iverilog -g2012 -f flist -o sim
    vvp sim
elif command -v verilator &> /dev/null; then
    echo "Using Verilator..."
    verilator --cc --exe --build --top-module tbench -f flist
    obj_dir/Vtbench
else
    echo "ERROR: No supported simulator found!"
    echo "Please install one of:"
    echo "  - Cadence Xcelium (xrun)"
    echo "  - ModelSim/QuestaSim"
    echo "  - Icarus Verilog (iverilog)"
    echo "  - Verilator"
    exit 1
fi


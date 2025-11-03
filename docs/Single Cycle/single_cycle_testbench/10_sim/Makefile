# Verilator Makefile for Milestone 2
# Author: Based on milestone-2-extra requirements

.PHONY: all
all: build run

.PHONY: build
build:
	@echo "Building with Verilator..."
	@verilator --cc --exe --build --top-module tbench -f ./flist

.PHONY: run
run:
	@echo "Running simulation..."
	@./obj_dir/Vtbench

.PHONY: wave
wave:
	@echo "Opening GTKWave..."
	@gtkwave waveform.vcd &

.PHONY: create_filelist
create_filelist:
	@rm -f flist
	@echo "# Verilator filelist for Milestone 2" > flist
	@echo "-sv" >> flist
	@echo "-timescale 1ns/100ps" >> flist
	@echo "# TESTBENCH FILES" >> flist
	@find ./../01_bench \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) >> flist
	@echo "# SOURCE CODE FILES" >> flist
	@find ./../00_src \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) >> flist
	@echo "Filelist created. Please check and reorder by module hierarchy (top module last)"

.PHONY: clean
clean:
	@echo "Cleaning Verilator output..."
	@rm -rf obj_dir *.vcd waveform.vcd


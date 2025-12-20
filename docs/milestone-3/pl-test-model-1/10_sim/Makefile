# Verilator Makefile for Milestone 3 - Model 2
# Forwarding with Two-bit Branch Prediction

.PHONY: all
all: build run

.PHONY: build
build:
	@echo "Building with Verilator..."
	@verilator $(VFLAGS) --cc --exe --build --top-module tbench -f ./flist

.PHONY: run
run:
	@echo "Running simulation..."
	@./obj_dir/Vtbench

.PHONY: wave
wave:
	@echo "Opening GTKWave..."
	@gtkwave waveform.vcd &

.PHONY: clean
clean:
	@echo "Cleaning Verilator output..."
	@rm -rf obj_dir *.vcd waveform.vcd


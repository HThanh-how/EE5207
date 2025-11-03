# Xcelium Makefile for Milestone 2
# Author: Based on milestone-2-extra requirements

.PHONY: all
all: xrun

.PHONY: xrun
xrun:
	@echo "Running simulation with Xcelium..."
	@xrun -64bit -access +rwc $(XRUN_OPTS) -f ./flist

.PHONY: gui
gui:
	@echo "Opening SimVision GUI..."
	@xrun -gui -access +rwc $(XRUN_OPTS) -f ./flist

.PHONY: simvision
simvision:
	@echo "Opening SimVision waveform viewer..."
	@simvision wave.shm &

.PHONY: create_filelist
create_filelist:
	@rm -f flist
	@echo "# Xcelium filelist for Milestone 2" > flist
	@echo "-sv" >> flist
	@echo "-timescale 1ns/100ps" >> flist
	@echo "# TESTBENCH FILES" >> flist
	@find ./../01_bench \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) >> flist
	@echo "# SOURCE CODE FILES" >> flist
	@find ./../00_src \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) >> flist
	@echo "Filelist created. Please check and reorder by module hierarchy (top module last)"

.PHONY: clean
clean:
	@echo "Cleaning Xcelium output..."
	@rm -rf x* *.vcd *.shm *.log xcelium.d INCA_libs


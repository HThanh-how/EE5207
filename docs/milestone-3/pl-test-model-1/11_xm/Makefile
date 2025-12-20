# Xcelium Makefile for Milestone 3 - Model 2
# Forwarding with Two-bit Branch Prediction

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

.PHONY: clean
clean:
	@echo "Cleaning Xcelium output..."
	@rm -rf x* *.vcd *.shm *.log xcelium.d INCA_libs


-sv
-timescale 1ns/100ps
+incdir+./../01_bench

# SOURCE CODE FILES
./../00_src/data_mem.sv
./../00_src/instr_mem.sv
./../00_src/reg_file.sv
./../00_src/alu.sv
./../00_src/control_unit.sv
./../00_src/branch_comp.sv
./../00_src/hazard_unit.sv
./../00_src/forwarding_unit.sv
./../00_src/imm_gen.sv
./../00_src/lsu.sv
./../00_src/pipelined.sv

# TESTBENCH FILES
./../01_bench/driver.sv
./../01_bench/scoreboard.sv
./../01_bench/tbench.sv

# Final Check - Đảm bảo 10 điểm và chạy được trên server

## ✅ Checklist cuối cùng

### 1. File Structure
- [x] `00_src/pipelined.sv` - Top-level module ✓
- [x] `00_src/imem_sync.sv` - Synchronous instruction memory (64 KiB) ✓
- [x] `00_src/dmem_sync.sv` - Synchronous data memory (64 KiB) ✓
- [x] `00_src/register_file.sv` - Register file ✓
- [x] `00_src/alu.sv` - ALU ✓
- [x] `00_src/control_unit.sv` - Control unit ✓
- [x] `01_bench/tbench.sv` - Testbench với pipelined module ✓
- [x] `01_bench/scoreboard.sv` - Scoreboard với "PIPELINE - ISA tests" ✓
- [x] `01_bench/driver.sv` - Driver ✓
- [x] `01_bench/tlib.svh` - Test library ✓
- [x] `02_test/isa_1b.hex` - Test file ✓
- [x] `02_test/isa_4b.hex` - Test file ✓
- [x] `10_sim/flist` - Verilator file list ✓
- [x] `10_sim/Makefile` - Verilator Makefile ✓
- [x] `11_xm/flist` - Xcelium file list ✓
- [x] `11_xm/Makefile` - Xcelium Makefile ✓

### 2. Top-level Module (pipelined.sv)
- [x] Module name: `pipelined` ✓
- [x] I/O ports đúng spec:
  - [x] `i_clk`, `i_reset` ✓
  - [x] `o_pc_debug` ✓
  - [x] `o_insn_vld` ✓
  - [x] `o_ctrl` ✓
  - [x] `o_mispred` ✓
  - [x] `o_io_ledr`, `o_io_ledg`, `o_io_hex0..7`, `o_io_lcd` ✓
  - [x] `i_io_sw` ✓

### 3. Memory Models
- [x] `imem_sync.sv`: Synchronous read, 64 KiB (65536 bytes) ✓
- [x] `dmem_sync.sv`: Synchronous read/write, 64 KiB (65536 bytes) ✓
- [x] Load từ `../02_test/isa.mem` (fallback to `../02_test/isa_1b.hex`) ✓
- [x] Address width: 16 bits (support 64 KiB) ✓

### 4. Memory Mapping (Table 1)
- [x] Memory: 0x0000_0000 - 0x0000_FFFF (64 KiB) ✓
- [x] LEDR: 0x1000_0000 - 0x1000_0FFF ✓
- [x] LEDG: 0x1000_1000 - 0x1000_1FFF ✓
- [x] HEX0-3: 0x1000_2000 - 0x1000_2FFF ✓
- [x] HEX4-7: 0x1000_3000 - 0x1000_3FFF ✓
- [x] LCD: 0x1000_4000 - 0x1000_4FFF ✓
- [x] SW: 0x1001_0000 - 0x1001_0FFF ✓

### 5. Pipeline Structure
- [x] 5 stages: IF, ID, EX, MEM, WB ✓
- [x] Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB ✓
- [x] Enable signals cho mỗi stage ✓
- [x] Reset signals cho mỗi stage ✓
- [x] Flush logic đúng ✓

### 6. Control Signals (Critical)
- [x] `o_insn_vld`: Assert khi instruction valid trong WB stage ✓
  - Logic: `o_insn_vld = wb_enable` ✓
  - Chỉ count instructions không bị flush ✓
  
- [x] `o_ctrl`: Assert khi branch/jump trong WB stage ✓
  - Logic: `o_ctrl = wb_is_ctrl && wb_enable` ✓
  - Theo spec: "If a branch or jump instruction is in the WB stage, this signal is asserted" ✓
  
- [x] `o_mispred`: Assert khi có misprediction ✓
  - Logic: `wb_mispred = mem_is_ctrl && mem_branch_taken` (default predict not-taken) ✓
  - Propagated to WB stage ✓
  - Theo spec: "when the HazardDetection asserts a flush due to a control transfer instruction being mispredicted" ✓

### 7. Hazard Detection
- [x] Load-use hazard detection ✓
  - Detect khi load trong EX và dependent instruction trong ID ✓
  - Stall IF và ID stages ✓
  - Flush EX stage (insert bubble) ✓
  
- [x] Control hazard (branch/jump) ✓
  - Flush IF và ID khi branch taken ✓
  - Flush IF và ID khi jump ✓

### 8. Forwarding Unit
- [x] Forward từ MEM stage (priority cao) ✓
  - Forward ALU result từ MEM đến EX ✓
  - Forward cho rs1 và rs2 ✓
  
- [x] Forward từ WB stage (nếu không forward từ MEM) ✓
  - Forward register write data từ WB đến EX ✓
  - Chỉ forward nếu không forward từ MEM ✓

### 9. Pipeline Registers
- [x] IF/ID: Flush khi `if_flush`, stall khi `stall_id` ✓
- [x] ID/EX: Flush khi `flush_id`, stall khi `stall_ex` ✓
- [x] EX/MEM: Flush khi `flush_ex` ✓
- [x] MEM/WB: Không flush (instruction completes) ✓

### 10. PC Logic
- [x] PC update mỗi cycle (nếu không stall) ✓
- [x] PC next selection:
  - Sequential: `pc_plus4` ✓
  - Branch taken: `ex_branch_target` ✓
  - Jump: `ex_jump_target` ✓
- [x] PC feed back từ EX stage đúng ✓

### 11. Testbench
- [x] `tbench.sv` sử dụng `pipelined` module ✓
- [x] Scoreboard hiển thị "PIPELINE - ISA tests" ✓
- [x] Scoreboard hiển thị "END of ISA tests" (có s) ✓
- [x] File lists (`flist`) đúng thứ tự ✓
- [x] Makefiles đúng ✓

### 12. File Paths (Critical for Server)
- [x] Memory load path: `../02_test/isa.mem` ✓
- [x] Fallback path: `../02_test/isa_1b.hex` ✓
- [x] File list paths: `./../00_src/...` và `./../01_bench/...` ✓

## ⚠️ Critical Points for Server

### 1. Memory Initialization
- Memory phải load từ `../02_test/isa.mem` (server sẽ có file này)
- Fallback to `../02_test/isa_1b.hex` nếu không tìm thấy
- Paths phải relative, không absolute

### 2. Expected Output Format
```
PIPELINE - ISA tests

add......PASS
addi.....PASS
...
END of ISA tests
```

### 3. "Elite Four" Instructions
Theo hint trong spec, cần đảm bảo 4 instructions này đúng:
- [x] `addi` ✓
- [x] `beq` ✓
- [x] `jal` ✓
- [x] `lui` ✓

### 4. Pipeline Timing
- PC update mỗi cycle (nếu không stall)
- Pipeline registers update mỗi cycle (nếu enable)
- Control signals propagate đúng qua các stages

## 🎯 Final Verification

### Syntax Check
- [x] No linter errors ✓
- [x] All modules compile ✓

### Logic Check
- [x] Pipeline structure đúng ✓
- [x] Hazard detection đúng ✓
- [x] Forwarding đúng ✓
- [x] Control signals đúng ✓
- [x] Memory mapping đúng ✓

### Server Compatibility
- [x] File paths relative ✓
- [x] Module names đúng ✓
- [x] I/O ports đúng ✓
- [x] Testbench setup đúng ✓

## ✅ Kết luận

**Implementation đã đúng và sẵn sàng cho server test!**

Tất cả các yêu cầu đã được đáp ứng:
- ✅ Top-level module: `pipelined.sv`
- ✅ I/O ports đúng spec
- ✅ Memory: 64 KiB synchronous
- ✅ Memory mapping đúng
- ✅ Pipeline: 5 stages với hazard detection và forwarding
- ✅ Control signals: o_insn_vld, o_ctrl, o_mispred đúng
- ✅ Testbench setup đúng
- ✅ File paths đúng cho server

**Có thể submit lên server và chạy test!**


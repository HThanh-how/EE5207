# Checklist để đạt 10 điểm - Milestone 3

## ✅ Đã hoàn thành

### 1. Cấu trúc thư mục
- [x] `00_src/` - Source files
- [x] `01_bench/` - Testbench files  
- [x] `02_test/` - Test files
- [x] `10_sim/` - Verilator simulation
- [x] `11_xm/` - Xcelium simulation

### 2. Top-level module
- [x] Module name: `pipelined.sv` ✓
- [x] I/O ports đúng spec:
  - [x] `i_clk`, `i_reset` ✓
  - [x] `o_pc_debug` ✓
  - [x] `o_insn_vld` ✓
  - [x] `o_ctrl` ✓
  - [x] `o_mispred` ✓
  - [x] `o_io_ledr`, `o_io_ledg`, `o_io_hex0..7`, `o_io_lcd` ✓
  - [x] `i_io_sw` ✓

### 3. Pipeline Structure
- [x] 5 stages: IF, ID, EX, MEM, WB ✓
- [x] Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB ✓
- [x] Enable và Reset signals cho mỗi stage ✓
- [x] Stall và Flush logic ✓

### 4. Memory Models
- [x] Synchronous Instruction Memory (64 KiB) ✓
- [x] Synchronous Data Memory (64 KiB) ✓
- [x] Load từ `isa.mem` (fallback to `isa_1b.hex`) ✓

### 5. Memory Mapping
- [x] Memory: 0x0000_0000 - 0x0000_FFFF (64 KiB) ✓
- [x] LEDR: 0x1000_0000 - 0x1000_0FFF ✓
- [x] LEDG: 0x1000_1000 - 0x1000_1FFF ✓
- [x] HEX0-3: 0x1000_2000 - 0x1000_2FFF ✓
- [x] HEX4-7: 0x1000_3000 - 0x1000_3FFF ✓
- [x] LCD: 0x1000_4000 - 0x1000_4FFF ✓
- [x] SW: 0x1001_0000 - 0x1001_0FFF ✓

### 6. Control Signals
- [x] `o_insn_vld`: Assert khi instruction valid trong WB stage (không bị flush) ✓
- [x] `o_ctrl`: Assert khi branch/jump trong WB stage ✓
- [x] `o_mispred`: Assert khi có misprediction (branch taken khi predict not-taken) ✓

### 7. Hazard Detection
- [x] Load-use hazard detection ✓
- [x] Control hazard (branch/jump) flush ✓
- [x] Stall logic cho IF, ID, EX stages ✓
- [x] Flush logic cho IF, ID, EX stages ✓

### 8. Forwarding Unit
- [x] Forward từ MEM stage ✓
- [x] Forward từ WB stage ✓
- [x] Forward cho ALU inputs (rs1, rs2) ✓
- [x] Forward cho branch comparison ✓

### 9. Testbench Setup
- [x] Testbench sử dụng `pipelined` module ✓
- [x] Scoreboard hiển thị "PIPELINE - ISA tests" ✓
- [x] File lists (flist) đúng ✓
- [x] Makefiles đúng ✓

## ⚠️ Cần kiểm tra khi test

### 1. ISA Test
- [ ] Tất cả tests PASS
- [ ] IPC được tính đúng
- [ ] Misprediction rate được tính đúng

### 2. Pipeline Correctness
- [ ] Instructions flow đúng qua các stages
- [ ] Data hazards được resolve đúng
- [ ] Control hazards được resolve đúng
- [ ] Forwarding hoạt động đúng

### 3. Edge Cases
- [ ] Load-use hazard với forwarding
- [ ] Branch taken/not-taken
- [ ] Jump instructions
- [ ] Memory-mapped I/O operations

## 📝 Lưu ý quan trọng

1. **o_insn_vld**: Chỉ count instructions hoàn thành (không bị flush)
2. **o_ctrl**: Chỉ assert khi control transfer instruction trong WB stage
3. **o_mispred**: Assert khi branch taken nhưng predict not-taken (default prediction)
4. **Memory**: Phải là synchronous (không dùng async như milestone 2)
5. **Memory size**: Phải là 64 KiB (65536 bytes)

## 🎯 Để đạt 10 điểm

1. ✅ Tất cả ISA tests PASS
2. ✅ Code structure đúng yêu cầu
3. ✅ Memory mapping đúng
4. ✅ Pipeline hoạt động đúng
5. ✅ Hazard detection và forwarding đúng
6. ✅ Output signals đúng


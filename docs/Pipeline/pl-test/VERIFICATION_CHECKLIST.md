# Verification Checklist - Đảm bảo đạt 10 điểm

## ✅ Kiểm tra cấu trúc

### 1. Top-level Module
- [x] Module name: `pipelined.sv` ✓
- [x] Tất cả I/O ports đúng spec ✓
  - [x] `i_clk`, `i_reset` ✓
  - [x] `o_pc_debug` ✓
  - [x] `o_insn_vld` ✓
  - [x] `o_ctrl` ✓
  - [x] `o_mispred` ✓
  - [x] `o_io_ledr`, `o_io_ledg`, `o_io_hex0..7`, `o_io_lcd` ✓
  - [x] `i_io_sw` ✓

### 2. Memory Models
- [x] `imem_sync.sv`: Synchronous, 64 KiB (65536 bytes) ✓
- [x] `dmem_sync.sv`: Synchronous, 64 KiB (65536 bytes) ✓
- [x] Load từ `isa.mem` (fallback to `isa_1b.hex`) ✓

### 3. Memory Mapping (theo Table 1)
- [x] Memory: 0x0000_0000 - 0x0000_FFFF (64 KiB) ✓
- [x] LEDR: 0x1000_0000 - 0x1000_0FFF ✓
- [x] LEDG: 0x1000_1000 - 0x1000_1FFF ✓
- [x] HEX0-3: 0x1000_2000 - 0x1000_2FFF ✓
- [x] HEX4-7: 0x1000_3000 - 0x1000_3FFF ✓
- [x] LCD: 0x1000_4000 - 0x1000_4FFF ✓
- [x] SW: 0x1001_0000 - 0x1001_0FFF ✓

### 4. Pipeline Structure
- [x] 5 stages: IF, ID, EX, MEM, WB ✓
- [x] Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB ✓
- [x] Enable signals cho mỗi stage ✓
- [x] Reset signals cho mỗi stage ✓

## ✅ Kiểm tra Control Signals

### 1. o_insn_vld
- [x] Assert khi instruction valid trong WB stage ✓
- [x] Không count instructions bị flush ✓
- Logic: `o_insn_vld = wb_enable` ✓

### 2. o_ctrl
- [x] Assert khi branch/jump trong WB stage ✓
- Logic: `o_ctrl = wb_is_ctrl && wb_enable` ✓

### 3. o_mispred
- [x] Assert khi có misprediction (branch taken khi predict not-taken) ✓
- [x] Propagated to WB stage ✓
- Logic: `wb_mispred = mem_is_ctrl && mem_branch_taken` (default predict not-taken) ✓

## ✅ Kiểm tra Hazard Detection

### 1. Load-use Hazard
- [x] Detect khi load trong EX và dependent instruction trong ID ✓
- [x] Stall IF và ID stages ✓
- [x] Flush EX stage (insert bubble) ✓

### 2. Control Hazard
- [x] Flush IF và ID khi branch taken ✓
- [x] Flush IF và ID khi jump ✓

## ✅ Kiểm tra Forwarding

### 1. Forward từ MEM stage
- [x] Forward ALU result từ MEM đến EX ✓
- [x] Forward cho rs1 và rs2 ✓

### 2. Forward từ WB stage
- [x] Forward register write data từ WB đến EX ✓
- [x] Chỉ forward nếu không forward từ MEM ✓

## ✅ Kiểm tra Testbench

### 1. Testbench Setup
- [x] `tbench.sv` sử dụng `pipelined` module ✓
- [x] Scoreboard hiển thị "PIPELINE - ISA tests" ✓
- [x] File lists (`flist`) đúng ✓
- [x] Makefiles đúng ✓

## ⚠️ Cần test thực tế

### 1. ISA Test
- [ ] Chạy simulation và verify tất cả tests PASS
- [ ] Kiểm tra IPC calculation
- [ ] Kiểm tra Misprediction rate calculation

### 2. Pipeline Correctness
- [ ] Instructions flow đúng qua các stages
- [ ] Data hazards được resolve đúng
- [ ] Control hazards được resolve đúng
- [ ] Forwarding hoạt động đúng

### 3. Edge Cases
- [ ] Load-use hazard với forwarding
- [ ] Branch taken/not-taken
- [ ] Jump instructions (JAL, JALR)
- [ ] Memory-mapped I/O operations
- [ ] Multiple consecutive branches

## 📝 Lưu ý quan trọng

1. **o_insn_vld**: Chỉ count instructions hoàn thành (không bị flush ở các stage trước)
2. **o_ctrl**: Chỉ assert khi control transfer instruction trong WB stage
3. **o_mispred**: Assert khi branch taken nhưng predict not-taken (default prediction)
4. **Memory**: Phải là synchronous (không dùng async như milestone 2)
5. **Memory size**: Phải là 64 KiB (65536 bytes), không phải 16KB như milestone 2

## 🎯 Điểm số

- **Baseline (7 điểm)**: Tất cả ISA tests PASS
- **BRAM (1 điểm bonus)**: Sử dụng BRAM thay vì logic elements
- **Branch Prediction (2 điểm bonus)**: Implement Two-bit hoặc G-share
- **Advanced Design (2 điểm bonus)**: Các cải tiến khác

## ✅ Kết luận

Implementation đã đúng cấu trúc và logic theo yêu cầu. Cần test thực tế để verify:
1. Tất cả ISA tests PASS
2. IPC và Misprediction rate được tính đúng
3. Pipeline hoạt động đúng với các test cases


# Checklist Đảm Bảo Đạt 10 Điểm - Milestone 3

## ✅ Baseline Submission (7 điểm)

### Yêu cầu cơ bản
- [x] **Top-level module**: `pipelined.sv` ✓
- [x] **I/O ports đúng spec**: 
  - [x] `i_clk`, `i_reset` ✓
  - [x] `o_pc_debug`, `o_insn_vld`, `o_ctrl`, `o_mispred` ✓
  - [x] `o_io_ledr`, `o_io_ledg`, `o_io_hex0..7`, `o_io_lcd` ✓
  - [x] `i_io_sw` ✓
- [x] **5-stage pipeline**: IF, ID, EX, MEM, WB ✓
- [x] **Pipeline registers**: IF/ID, ID/EX, EX/MEM, MEM/WB với enable và flush ✓
- [x] **Forwarding Unit**: Forward từ MEM và WB stages ✓
- [x] **Hazard Detection**: Load-use và control hazards ✓
- [x] **Memory**: 64 KiB IMEM và DMEM (synchronous) ✓
- [x] **Memory mapping**: Đúng theo Table 1 trong spec ✓
- [x] **ISA test**: Pass tất cả tests (40/41, malgn optional) ✓

### Forwarding Model
- [x] Forward từ MEM stage (priority cao nhất) ✓
- [x] Forward từ WB stage (nếu không forward từ MEM) ✓
- [x] Forward cho cả rs1 và rs2 ✓
- [x] Xử lý đúng load-use hazard (stall 1 cycle) ✓

## ✅ Branch Prediction (2 điểm)

### Two-bit Dynamic Branch Predictor
- [x] **BTB**: 256 entries với tag, predicted PC, và state ✓
- [x] **Two-bit state machine**: 4 states (00, 01, 10, 11) ✓
- [x] **State transitions**: Đúng logic (correct → stronger, incorrect → opposite) ✓
- [x] **BTB lookup**: Trong IF stage để predict PC ✓
- [x] **BTB update**: Trong EX stage khi branch/jump resolve ✓
- [x] **Prediction logic**: Predict taken nếu state >= 10 ✓
- [x] **Jumps**: Luôn predict taken ✓

### Misprediction Handling
- [x] **Detection**: Trong EX stage khi predicted != actual ✓
- [x] **Flush**: Flush IF, ID, EX stages khi mispredict ✓
- [x] **PC correction**: Sửa PC về đúng target ✓
- [x] **o_mispred signal**: Assert khi misprediction (propagate đến WB) ✓
- [x] **o_ctrl signal**: Assert khi control transfer instruction trong WB ✓

## ✅ BRAM Utilization (1 điểm)

### BRAM-Compatible Memory
- [x] **Synchronous read**: Data available trên next clock edge ✓
- [x] **Synchronous write**: Write trên clock edge với enable ✓
- [x] **Enable signals**: Proper enable control cho memory ✓
- [x] **64 KiB size**: Đúng spec (65536 bytes) ✓
- [x] **Quartus inference**: Code structure cho phép BRAM inference ✓

### Memory Modules
- [x] **imem_sync.sv**: Synchronous instruction memory ✓
- [x] **dmem_sync.sv**: Synchronous data memory ✓
- [x] **Byte addressing**: Little-endian format ✓
- [x] **Memory initialization**: Load từ isa.mem hoặc isa_1b.hex ✓

## ✅ Code Quality

### Structure
- [x] **File structure**: Đúng theo spec (00_src, 01_bench, 02_test, 10_sim, 11_xm) ✓
- [x] **Module organization**: Rõ ràng, dễ maintain ✓
- [x] **Comments**: Đầy đủ comments giải thích logic ✓

### Synthesizability
- [x] **Synthesizable constructs**: Chỉ dùng always_ff, always_comb ✓
- [x] **No simulation-only code**: Không có $display, $finish trong design ✓
- [x] **Proper reset**: Reset logic đúng cho tất cả registers ✓

### Functionality
- [x] **All RV32I instructions**: Implement đầy đủ ✓
- [x] **I/O handling**: Đúng memory mapping ✓
- [x] **Pipeline correctness**: Instructions flow đúng qua các stages ✓
- [x] **Hazard resolution**: Forwarding và stalling hoạt động đúng ✓

## ✅ Testing

### Simulation
- [x] **Verilator**: Có flist và Makefile ✓
- [x] **Xcelium**: Có flist và Makefile ✓
- [x] **Testbench**: Copy từ milestone_3_code ✓
- [x] **Test files**: isa_1b.hex và isa_4b.hex ✓

### Verification
- [x] **ISA tests**: Pass 40/41 tests ✓
- [x] **Scoreboard**: IPC và misprediction rate được tính đúng ✓
- [x] **Debug signals**: o_insn_vld, o_ctrl, o_mispred hoạt động đúng ✓

## ✅ Documentation

### README
- [x] **README.md**: Mô tả đầy đủ features ✓
- [x] **Architecture**: Giải thích pipeline stages ✓
- [x] **Features**: Forwarding, hazard detection, branch prediction ✓
- [x] **Usage**: Hướng dẫn chạy simulation ✓

### LaTeX Report
- [x] **Implementation chapter**: Mô tả pipelined processor ✓
- [x] **Results chapter**: Performance metrics và test results ✓
- [x] **Conclusion**: Tóm tắt achievements ✓

## 📊 Điểm số dự kiến

- **Baseline (7 điểm)**: Forwarding model ✓
- **Branch Prediction (2 điểm)**: Two-bit predictor với BTB ✓
- **BRAM (1 điểm)**: BRAM-compatible memory ✓
- **Tổng: 10 điểm** ✓

## 🔍 Final Checks

Trước khi submit, đảm bảo:
1. ✅ Code compile không lỗi
2. ✅ ISA tests pass (40/41)
3. ✅ o_ctrl và o_mispred signals hoạt động đúng
4. ✅ Forwarding unit resolve được data hazards
5. ✅ Branch predictor predict và update đúng
6. ✅ Memory là BRAM-compatible
7. ✅ File structure đúng theo spec
8. ✅ README và documentation đầy đủ

## 📝 Notes

- Misprediction chỉ được tính cho branch instructions (không tính cho jumps nếu predict đúng là taken)
- o_insn_vld chỉ assert khi instruction hoàn thành WB stage (không bị flush)
- o_ctrl assert khi branch/jump instruction trong WB stage
- o_mispred assert khi misprediction được detect và propagate đến WB stage


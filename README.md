# ✨ Milestone 3 – Pipelined RV32I (Forwarding + Two-Bit BP + BRAM) ✨

🚀 “Build fast, stall less, predict smarter.”  
🎯 Mục tiêu: 10/10 điểm (Baseline 7 + BP 2 + BRAM 1).

## 🌈 ToC “màu mè”
- [Kiến trúc nhanh](#-kiến-trúc-nhanh)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Tính năng nổi bật](#-tính-năng-nổi-bật)
- [Build & Run](#-build--run)
- [Tín hiệu quan trọng](#-tín-hiệu-quan-trọng)
- [Checklist 10đ](#-checklist-10đ)
- [Tài liệu](#-tài-liệu)
- [Mở rộng](#-mở-rộng)

## 🏗 Kiến trúc nhanh
```
IF -> ID -> EX -> MEM -> WB
   ^    ^      ^       |
   |    |      |       |
   |    |  flush/mispred
   |    +-- forwarding (MEM > WB)
   +-- BTB predict PC (two-bit FSM)
```

## 📁 Cấu trúc thư mục
```
docs/milestone-3/pl-test-model-2/
├── 00_src/      # RTL: pipelined.sv, alu, control_unit, regfile, imem_sync, dmem_sync
├── 01_bench/    # Testbench: tbench, driver, scoreboard, tlib
├── 02_test/     # ISA hex: isa_1b.hex, isa_4b.hex
├── 10_sim/      # Verilator: flist, Makefile
├── 11_xm/       # Xcelium: flist, Makefile
├── README.md    # Bạn đang đọc
└── CHECKLIST_10DIEM.md
```

## 🌟 Tính năng nổi bật
- 5-stage pipeline với enable/flush cho từng stage.
- Forwarding MEM > WB, giảm stall tối đa.
- Hazard Detection: stall 1 chu kỳ cho load-use; flush IF/ID/EX khi mispredict.
- Two-bit Branch Predictor + BTB 256 entries (lookup IF, update EX).
- Mispredict: detect EX, flush, correct PC; `o_mispred` ở WB.
- IMEM/DMEM synchronous 64 KiB, enable-gated, BRAM-friendly.
- Memory map chuẩn spec: RAM 0x0000_0000–0x0000_FFFF; I/O LED/HEX/LCD/SW 0x1000_xxxx, SW 0x1001_0000.

## 🛠 Build & Run
### Verilator
```
cd docs/milestone-3/pl-test-model-2/10_sim
make
```
### Xcelium
```
cd docs/milestone-3/pl-test-model-2/11_xm
make
```

## 🔎 Tín hiệu quan trọng
- `o_insn_vld`: 1 khi instruction hoàn thành WB (không bị flush).
- `o_ctrl`: 1 khi branch/jump ở WB.
- `o_mispred`: 1 khi mispredict propagate tới WB.
- Scoreboard: `num_cycle`, `num_insn`, `num_ctrl`, `num_mispred`, IPC, mispred rate.

## ✅ Checklist 10đ (rút gọn)
- Baseline 7đ: Forwarding + hazard detection, pass ISA 40/41 (malgn optional).
- Branch Prediction 2đ: Two-bit predictor + BTB, flush/correct PC.
- BRAM 1đ: IMEM/DMEM synchronous 64 KiB, enable-gated.
- Đủ flist/Makefile cho Verilator & Xcelium; đúng file structure.

## 📚 Tài liệu
- LaTeX đã bổ sung: kiến trúc pipeline, BTB/predictor, forwarding/hazard, bảng so sánh SC vs Pipeline.
- `CHECKLIST_10DIEM.md`: tiêu chí chấm điểm + kiểm cuối.

## 🌱 Mở rộng
- Thêm TikZ cho BTB/forwarding nếu muốn rực rỡ hơn.
- Benchmark tự chọn để lấy bonus (nếu có).


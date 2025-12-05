# Milestone 3 - Pipelined Processor Model 2

## Mô tả

Đây là implementation của Pipelined RISC-V Processor với các tính năng sau:

1. **Forwarding Unit**: Giải quyết data hazards bằng cách forward dữ liệu từ MEM và WB stages
2. **Hazard Detection**: Phát hiện và xử lý load-use hazards bằng stall
3. **Two-bit Dynamic Branch Predictor**: Dự đoán nhánh động với 2-bit state machine
4. **Branch Target Buffer (BTB)**: Lưu trữ predicted PC cho các branch/jump instructions
5. **BRAM Memory**: Sử dụng synchronous memory tương thích với BRAM cho synthesis

## Cấu trúc thư mục

```
pl-test-model-2/
├── 00_src/          # Source code files
│   ├── pipelined.sv      # Top-level pipelined processor
│   ├── alu.sv            # ALU module
│   ├── control_unit.sv    # Control unit
│   ├── register_file.sv   # Register file
│   ├── imem_sync.sv       # Synchronous instruction memory (BRAM)
│   └── dmem_sync.sv       # Synchronous data memory (BRAM)
├── 01_bench/        # Testbench files
│   ├── driver.sv
│   ├── scoreboard.sv
│   ├── tbench.sv
│   └── tlib.svh
├── 02_test/         # Test files
│   ├── isa_1b.hex
│   └── isa_4b.hex
├── 10_sim/          # Verilator simulation
│   ├── flist
│   └── Makefile
└── 11_xm/           # Xcelium simulation
    ├── flist
    └── Makefile
```

## Tính năng chính

### 1. Forwarding Unit
- Forward từ MEM stage (priority cao nhất)
- Forward từ WB stage (nếu không forward từ MEM)
- Giải quyết hầu hết data hazards mà không cần stall

### 2. Hazard Detection
- Load-use hazard: Stall pipeline khi load instruction trong EX stage và dependent instruction trong ID stage
- Control hazard: Flush pipeline khi misprediction được phát hiện

### 3. Two-bit Branch Predictor
- State machine với 4 states:
  - `00`: Strongly not-taken
  - `01`: Weakly not-taken
  - `10`: Weakly taken
  - `11`: Strongly taken
- Cập nhật state dựa trên kết quả thực tế của branch

### 4. Branch Target Buffer (BTB)
- 256 entries
- Lưu trữ: tag, predicted PC, và two-bit predictor state
- Lookup trong IF stage để predict PC
- Update trong EX stage khi branch/jump được resolve

### 5. Memory Mapping
- Instruction Memory: 64 KiB (0x0000_0000 - 0x0000_FFFF)
- Data Memory: 64 KiB (0x0000_0000 - 0x0000_FFFF)
- I/O Mapping theo spec:
  - LEDR: 0x1000_0000 - 0x1000_0FFF
  - LEDG: 0x1000_1000 - 0x1000_1FFF
  - HEX0-3: 0x1000_2000 - 0x1000_2FFF
  - HEX4-7: 0x1000_3000 - 0x1000_3FFF
  - LCD: 0x1000_4000 - 0x1000_4FFF
  - SW: 0x1001_0000 - 0x1001_0FFF

## Cách chạy simulation

### Verilator
```bash
cd 10_sim
make
```

### Xcelium
```bash
cd 11_xm
make
```

## Điểm số dự kiến

- **Baseline (7 điểm)**: Forwarding model ✓
- **Branch Prediction (2 điểm)**: Two-bit Dynamic Branch Prediction ✓
- **BRAM (1 điểm)**: BRAM-compatible memory ✓

**Tổng: 10 điểm**

## Lưu ý

1. Memory sử dụng synchronous read/write để tương thích với BRAM trong Quartus
2. BTB được khởi tạo với state "weakly not-taken" (01)
3. Jumps luôn được predict là taken và không có misprediction
4. Misprediction chỉ được tính cho branch instructions


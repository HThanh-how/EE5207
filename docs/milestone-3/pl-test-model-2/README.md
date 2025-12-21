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

### 5. BRAM-Compatible Synchronous Memory
- **Instruction Memory (IMEM)**: 
  - 64 KiB (0x0000_0000 - 0x0000_FFFF)
  - Synchronous read (BRAM compatible)
  - Supports multiple file formats: `isa.mem`, `isa_1b.hex`, `isa_4b.hex`
  - Auto-detects and loads appropriate format
- **Data Memory (DMEM)**:
  - 64 KiB (0x0000_0000 - 0x0000_FFFF)
  - Synchronous read/write (BRAM compatible)
  - Supports byte, halfword, and word operations (SB, SH, SW)
  - Memory-mapped I/O integration

### 6. I/O Memory Mapping
- **Memory-mapped I/O** theo spec Milestone 3:
  - **LEDR (Red LEDs)**: 0x1000_0000 - 0x1000_0FFF (Write-only, 32-bit)
  - **LEDG (Green LEDs)**: 0x1000_1000 - 0x1000_1FFF (Write-only, 32-bit)
  - **HEX0-3 (7-segment displays)**: 0x1000_2000 - 0x1000_2FFF (Write-only)
    - Supports byte, halfword, and word writes
    - Each HEX display: 7 bits (segments a-g)
  - **HEX4-7 (7-segment displays)**: 0x1000_3000 - 0x1000_3FFF (Write-only)
    - Supports byte, halfword, and word writes
  - **LCD**: 0x1000_4000 - 0x1000_4FFF (Read/Write, 32-bit)
  - **SW (Switches)**: 0x1001_0000 - 0x1001_0FFF (Read-only, 32-bit)
- **I/O Read**: Memory-mapped I/O được đọc như memory thông thường (load instructions)
- **I/O Write**: Memory-mapped I/O được ghi như memory thông thường (store instructions)

### 7. Debug và Monitoring Signals
- **`o_pc_debug`**: Program counter từ IF stage (32-bit)
- **`o_insn_vld`**: Instruction valid signal từ WB stage
  - Asserted khi instruction hoàn thành và được write back
  - Dùng để đếm số instructions đã execute
- **`o_ctrl`**: Control transfer signal từ WB stage
  - Asserted khi instruction là branch hoặc jump
  - Dùng để monitor control flow instructions
- **`o_mispred`**: Misprediction signal từ WB stage
  - Asserted khi branch/jump được mispredicted
  - Dùng để đo branch prediction accuracy

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

## Tính năng nâng cao

### 1. BRAM-Compatible Memory Architecture
- **Synchronous Memory**: Tất cả memory operations là synchronous (clocked)
- **Quartus Synthesis**: Memory được synthesize thành BRAM (altsyncram) trong Quartus
- **Performance**: BRAM cho phép tần số cao hơn và sử dụng ít logic elements hơn
- **Memory Size**: 64 KiB cho cả IMEM và DMEM (theo yêu cầu Milestone 3)

### 2. Advanced I/O Handling
- **Memory-mapped I/O**: I/O peripherals được map vào memory address space
- **Flexible HEX Display**: Hỗ trợ write byte, halfword, và word cho HEX displays
- **LCD Support**: Full 32-bit read/write cho LCD register
- **Switch Reading**: Read-only access đến switch inputs

### 3. Branch Prediction Accuracy
- **Two-bit State Machine**: 4 states cho accurate prediction
- **BTB Learning**: BTB tự động học branch/jump targets sau lần execute đầu tiên
- **Misprediction Tracking**: Signal `o_mispred` để monitor prediction accuracy
- **Jump Optimization**: Jumps được predict là always taken (không có misprediction)

### 4. Pipeline Control Signals
- **Stall/Flush Mechanism**: Fine-grained control cho pipeline stages
- **Enable Signals**: Mỗi pipeline stage có enable signal để control flow
- **Instruction Validity**: `o_insn_vld` đảm bảo chỉ valid instructions được đếm

## Lưu ý Implementation

1. **Memory**: 
   - Sử dụng synchronous read/write để tương thích với BRAM trong Quartus
   - Memory được khởi tạo từ file trong `02_test/` directory
   - Auto-detection cho nhiều file formats

2. **BTB**: 
   - Được khởi tạo với state "weakly not-taken" (01)
   - 256 entries với tag-based lookup
   - Update trong EX stage khi branch/jump được resolve

3. **Branch Prediction**:
   - Jumps luôn được predict là taken (không có misprediction)
   - Misprediction chỉ được tính cho branch instructions
   - Two-bit predictor state được update dựa trên actual branch outcome

4. **I/O Mapping**:
   - I/O read/write được handle trong MEM stage
   - Address decoder xác định memory region vs I/O region
   - I/O data được forward qua pipeline như memory data

5. **Forwarding Priority**:
   - MEM stage có priority cao hơn WB stage
   - Đảm bảo dữ liệu mới nhất được sử dụng
   - Load-use hazards vẫn cần stall (không thể forward)


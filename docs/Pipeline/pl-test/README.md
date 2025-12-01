# Pipelined RISC-V Processor - Milestone 3

## Tổng quan
Đây là implementation của RISC-V 32-bit Pipelined Processor cho Milestone 3 môn Computer Architecture.

## Cấu trúc thư mục
```
pl-test/
├── 00_src/           # Verilog source files
│   ├── pipelined.sv      # Top-level pipelined processor module
│   ├── imem_sync.sv      # Synchronous Instruction Memory (64 KiB)
│   ├── dmem_sync.sv      # Synchronous Data Memory (64 KiB)
│   ├── register_file.sv  # Register file (32 registers)
│   ├── alu.sv            # Arithmetic Logic Unit
│   └── control_unit.sv   # Control unit
├── 01_bench/        # Testbench files
│   ├── tbench.sv         # Top testbench
│   ├── scoreboard.sv     # Scoreboard checker
│   ├── driver.sv         # Input driver
│   └── tlib.svh          # Test library
├── 02_test/         # Test hex files
│   ├── isa_1b.hex        # ISA test file (byte format)
│   └── isa_4b.hex         # ISA test file (word format)
├── 10_sim/          # Verilator simulation
│   ├── flist              # File list for Verilator
│   └── Makefile           # Makefile for simulation
└── 11_xm/           # Xcelium simulation
    ├── flist              # File list for Xcelium
    └── Makefile           # Makefile for simulation
```

## Memory Mapping (64 KiB)
- **Instruction Memory (IMEM)**: 64 KiB (65536 bytes), load từ isa.mem file
- **Data Memory (DMEM)**: 64 KiB (0x0000_0000 - 0x0000_FFFF)
- **I/O Switch Input**: 0x1001_0000 - 0x1001_0FFF
- **I/O LEDR Output**: 0x1000_0000 - 0x1000_0FFF
- **I/O LEDG Output**: 0x1000_1000 - 0x1000_1FFF
- **I/O HEX0-3**: 0x1000_2000 - 0x1000_2FFF
- **I/O HEX4-7**: 0x1000_3000 - 0x1000_3FFF
- **I/O LCD Output**: 0x1000_4000 - 0x1000_4FFF

## Pipeline Stages
Processor được chia thành 5 stages:
1. **IF (Instruction Fetch)**: Fetch instruction từ instruction memory
2. **ID (Instruction Decode)**: Decode instruction và đọc register file
3. **EX (Execute)**: Thực hiện ALU operations và branch comparison
4. **MEM (Memory Access)**: Truy cập data memory hoặc I/O
5. **WB (Write Back)**: Ghi kết quả vào register file

## Các Models

### Model 1: Non-forwarding (Baseline)
- Hazard Detection Unit phát hiện data hazards
- Stall pipeline khi cần thiết
- Flush pipeline khi branch/jump taken

### Model 2: Forwarding (Baseline)
- Forwarding Unit để forward data từ MEM và WB stages
- Giảm số lượng stalls
- Vẫn cần stall cho load-use hazards

## Signals mới
- `o_ctrl`: Assert khi có control transfer instruction (branch/jump) trong WB stage
- `o_mispred`: Assert khi có misprediction (branch/jump predicted sai)
- `o_insn_vld`: Assert khi instruction valid trong WB stage

## Để chạy simulation

### Verilator:
```bash
cd 10_sim
make
make wave  # Để xem waveforms
```

### Xcelium:
```bash
cd 11_xm
make
make gui  # Để xem waveforms
```

## Test
Test sẽ tự động:
1. Load `isa.mem` vào instruction memory (fallback to `isa_1b.hex` nếu không tìm thấy)
2. Chạy processor từ PC = 0x0000_0000
3. Kiểm tra output tại các PC tương ứng
4. Verify memory-mapped I/O operations
5. Tính IPC và Misprediction Rate

## Yêu cầu
- SystemVerilog simulator (xrun/Cadence hoặc Verilator)
- Testbench đã được cung cấp sẵn
- Memory mapping giữ nguyên như yêu cầu

## Lưu ý
- Implementation hiện tại đã có forwarding cơ bản
- Cần tách thành 2 models riêng: Non-forwarding và Forwarding
- Cần implement branch prediction cho các models nâng cao
- Cần verify kỹ với ISA test để đảm bảo tất cả tests PASS

## Các bước tiếp theo
1. Test với ISA test và fix các bugs
2. Tách thành 2 models riêng (Non-forwarding và Forwarding)
3. Implement branch prediction (Two-bit, G-share)
4. Benchmark và so sánh performance


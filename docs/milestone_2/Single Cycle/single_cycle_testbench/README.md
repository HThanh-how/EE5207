# Single Cycle RISC-V Processor Implementation

## Tổng quan
Đây là implementation đầy đủ của RISC-V 32-bit Single Cycle Processor cho Milestone 2 môn Computer Architecture.

## Cấu trúc thư mục
```
single_cycle_testbench/
├── 00_src/           # Source code của processor
│   ├── single_cycle.sv      # Top-level module
│   ├── register_file.sv     # Register file (32 registers)
│   ├── alu.sv               # Arithmetic Logic Unit
│   ├── imem.sv              # Instruction Memory (16KB)
│   ├── dmem.sv              # Data Memory (2KB)
│   └── control_unit.sv      # Control unit
├── 01_bench/        # Testbench files
│   ├── tbench.sv            # Top testbench
│   ├── scoreboard.sv        # Scoreboard checker
│   ├── driver.sv            # Input driver
│   └── tlib.svh             # Test library
├── 02_test/         # Test hex files
│   ├── isa_1b.hex           # ISA test file (byte format)
│   └── isa_4b.hex            # ISA test file (word format)
└── 03_sim/          # Simulation files
    └── makefile              # Makefile cho simulation
```

## Memory Mapping
- **Instruction Memory (IMEM)**: 16KB (16384 bytes), load từ isa.mem file
- **Data Memory (DMEM)**: 2KB (0x0000_0000 - 0x0000_07FF)
- **I/O Switch Input**: 0x1001_0000 - 0x1001_0FFF
- **I/O LEDR Output**: 0x1000_0000 - 0x1000_0FFF
- **I/O LEDG Output**: 0x1000_1000 - 0x1000_1FFF
- **I/O HEX0-3**: 0x1000_2000 - 0x1000_2FFF
- **I/O HEX4-7**: 0x1000_3000 - 0x1000_3FFF
- **I/O LCD Output**: 0x1000_4000 - 0x1000_4FFF

## Các instruction đã implement
### R-type (Register operations)
- ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU

### I-type (Immediate operations)
- ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU
- LW, LH, LHU, LB, LBU
- JALR

### S-type (Store operations)
- SW, SH, SB

### B-type (Branch operations)
- BEQ, BNE, BLT, BGE, BLTU, BGEU

### U-type (Upper immediate)
- LUI, AUIPC

### J-type (Jump)
- JAL

## Để chạy simulation
```bash
cd 03_sim
make create_filelist
make sim
```

## Test
Test sẽ tự động:
1. Load `isa.mem` vào instruction memory (fallback to `isa_1b.hex` nếu không tìm thấy)
2. Chạy processor từ PC = 0x0000_0000
3. Kiểm tra output tại các PC tương ứng
4. Verify memory-mapped I/O operations

## Yêu cầu
- SystemVerilog simulator (xrun/Cadence hoặc tương đương)
- Testbench đã được cung cấp sẵn
- Memory mapping giữ nguyên như yêu cầu


# Pipeline Model 1: Non-Forwarding

## Tổng quan
Đây là implementation của RISC-V 32-bit Pipelined Processor **không có forwarding** (Model 1) cho Milestone 3.

## Đặc điểm chính

### Model 1: Non-Forwarding
- **Không có Forwarding Unit**: Data hazards được giải quyết bằng cách stall pipeline
- **Hazard Detection**: 
  - Stall khi instruction trong ID phụ thuộc vào instruction trong EX hoặc MEM
  - Stall 1 cycle cho load-use hazards
- **Branch Prediction**: Two-bit dynamic branch predictor với BTB (256 entries)
- **Memory**: BRAM-compatible synchronous memory (IMEM/DMEM)

## So sánh với Model 2

| Feature | Model 1 (Non-Forwarding) | Model 2 (Forwarding) |
|---------|---------------------------|----------------------|
| Forwarding | ❌ Không có | ✅ Có (MEM > WB priority) |
| Data Hazard | Stall pipeline | Forward từ MEM/WB |
| Load-Use Hazard | Stall 1 cycle | Stall 1 cycle |
| Performance | Thấp hơn (nhiều stall) | Cao hơn (ít stall) |
| IPC | Thấp hơn | Cao hơn |

## Cấu trúc thư mục

```
pl-test-model-1/
├── 00_src/           # Source code
│   ├── pipelined.sv      # Top-level module (NO FORWARDING)
│   ├── alu.sv            # ALU
│   ├── control_unit.sv   # Control unit
│   ├── register_file.sv  # Register file
│   ├── imem_sync.sv     # Instruction memory (synchronous)
│   └── dmem_sync.sv     # Data memory (synchronous)
├── 01_bench/        # Testbench
│   ├── tbench.sv         # Top testbench
│   ├── scoreboard.sv     # Scoreboard checker
│   ├── driver.sv         # Input driver
│   └── tlib.svh          # Test library
├── 02_test/         # Test files
│   ├── isa.mem           # ISA test (server)
│   ├── isa_1b.hex        # ISA test (local, byte format)
│   └── isa_4b.hex        # ISA test (local, word format)
├── 03_sim/          # Simulation files
│   ├── makefile          # Makefile
│   └── flist.f           # File list
├── 10_sim/          # Verilator simulation
│   ├── Makefile
│   └── flist
└── 11_xm/           # Xcelium simulation
    ├── Makefile
    └── flist
```

## Hazard Detection Logic

Model 1 sử dụng stall để giải quyết data hazards:

1. **Data Hazard (EX → ID)**: 
   - Nếu instruction trong ID cần rs1/rs2 từ instruction trong EX
   - → Stall IF, ID; Flush EX (insert bubble)

2. **Data Hazard (MEM → ID)**:
   - Nếu instruction trong ID cần rs1/rs2 từ instruction trong MEM
   - → Stall IF, ID; Flush EX (insert bubble)

3. **Load-Use Hazard**:
   - Nếu load trong EX và instruction trong ID phụ thuộc
   - → Stall IF, ID; Flush EX (insert bubble)

## Chạy simulation

### Verilator
```bash
cd 10_sim
make              # Compile and run
make wave         # Open GTKWave
```

### Xcelium
```bash
cd 11_xm
module load xcelium
make              # Run simulation
make gui          # Open SimVision GUI
```

## Kết quả mong đợi

Model 1 sẽ có:
- **IPC thấp hơn** Model 2 do nhiều stall cycles
- **Tất cả tests PASS** (giống Model 2)
- **Misprediction rate** tương tự Model 2 (cùng branch predictor)

## Lưu ý

- Model 1 được dùng để so sánh performance với Model 2
- Không có forwarding → nhiều stall → IPC thấp hơn
- Code structure giống Model 2, chỉ khác ở forwarding unit và hazard detection

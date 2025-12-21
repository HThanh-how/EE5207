# Pipeline Model 1: Non-Forwarding RISC-V Processor

## Tổng quan

Đây là implementation của RISC-V 32-bit Pipelined Processor **không có forwarding** (Model 1) cho Milestone 3. Model này được thiết kế để so sánh performance với Model 2 (Forwarding) và minh họa tác động của forwarding mechanism lên pipeline performance.

## Đặc điểm chính

### Model 1: Non-Forwarding
- **❌ Không có Forwarding Unit**: Data hazards được giải quyết hoàn toàn bằng cách stall pipeline
- **✅ Hazard Detection**: 
  - Stall pipeline khi phát hiện data hazards
  - Stall 1 cycle cho load-use hazards
  - Flush pipeline khi mispredicted branch/jump
- **✅ Branch Prediction**: Two-bit dynamic branch predictor với BTB (256 entries)
- **✅ Memory**: BRAM-compatible synchronous memory (IMEM/DMEM)
- **✅ I/O Mapping**: Hỗ trợ đầy đủ I/O peripherals (LED, HEX, LCD, Switch)

## So sánh với Model 2 (Forwarding)

| Feature | Model 1 (Non-Forwarding) | Model 2 (Forwarding) |
|---------|---------------------------|----------------------|
| **Forwarding Unit** | ❌ Không có | ✅ Có (MEM > WB priority) |
| **Data Hazard Resolution** | Stall pipeline | Forward từ MEM/WB |
| **Load-Use Hazard** | Stall 1 cycle | Stall 1 cycle |
| **Performance (IPC)** | Thấp hơn (nhiều stall) | Cao hơn (ít stall) |
| **Pipeline Bubbles** | Nhiều | Ít |
| **Hardware Complexity** | Đơn giản hơn | Phức tạp hơn |
| **Branch Predictor** | ✅ Two-bit + BTB | ✅ Two-bit + BTB |
| **I/O Support** | ✅ Đầy đủ | ✅ Đầy đủ |

## Cấu trúc thư mục

```
pl-test-model-1/
├── 00_src/           # Source code
│   ├── pipelined.sv      # Top-level module (NO FORWARDING)
│   ├── alu.sv            # ALU module
│   ├── control_unit.sv   # Control unit
│   ├── register_file.sv  # Register file
│   ├── imem_sync.sv     # Instruction memory (synchronous, BRAM)
│   └── dmem_sync.sv     # Data memory (synchronous, BRAM)
├── 01_bench/        # Testbench
│   ├── tbench.sv         # Top testbench
│   ├── scoreboard.sv     # Scoreboard checker
│   ├── driver.sv         # Input driver
│   └── tlib.svh          # Test library
├── 02_test/         # Test files
│   ├── isa.mem           # ISA test (server format)
│   ├── isa_1b.hex        # ISA test (local, byte format)
│   └── isa_4b.hex        # ISA test (local, word format)
├── 03_sim/          # Simulation files (legacy)
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

### 1. Forwarding Unit (DISABLED)

Trong Model 1, Forwarding Unit luôn trả về `2'b00` (không forward):

```systemverilog
// Forwarding Unit (DISABLED for Model 1)
always_comb begin
    forward_a = 2'b00;  // Always use register file (no forwarding)
    forward_b = 2'b00;  // Always use register file (no forwarding)
end
```

**Kết quả:** ALU luôn sử dụng dữ liệu từ register file (ID/EX register), không forward từ MEM/WB stages.

### 2. Data Hazard Detection

**Vấn đề:** Khi instruction trong EX stage cần dữ liệu từ instruction trong MEM hoặc WB stage, dữ liệu chưa có trong register file.

**Giải pháp:** Stall pipeline cho đến khi dữ liệu có trong register file.

**Ví dụ:**
```
Cycle 1: ADD x1, x2, x3    (EX stage - tính x1)
Cycle 2: ADD x4, x1, x5    (ID stage - cần x1)  <- HAZARD!
         → Stall IF, ID; Flush EX (insert bubble)
Cycle 3: ADD x1, x2, x3    (MEM stage)
         ADD x4, x1, x5    (ID stage - vẫn cần x1)  <- Vẫn HAZARD!
         → Stall IF, ID; Flush EX (insert bubble)
Cycle 4: ADD x1, x2, x3    (WB stage - write x1 vào register file)
         ADD x4, x1, x5    (ID stage - x1 đã có trong register file)
         → Không stall, tiếp tục
```

### 3. Load-Use Hazard Detection

**Vấn đề:** Load instruction cần 2 cycles để có dữ liệu (EX → MEM → WB), không thể forward.

**Giải pháp:** Stall 1 cycle khi load trong EX và instruction trong ID phụ thuộc.

```systemverilog
// Load-use hazard: stall if load in EX and dependent instruction in ID
if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
    if ((id_rs1_addr == ex_rd_addr && id_reg_write) ||
        (id_rs2_addr == ex_rd_addr && (id_mem_write || id_branch))) begin
        stall_if = 1'b1;
        stall_id = 1'b1;
        flush_ex = 1'b1;  // Insert bubble
    end
end
```

**Ví dụ:**
```
Cycle 1: LW x1, 0(x2)      (EX stage - load x1)
Cycle 2: ADD x3, x1, x4    (ID stage - cần x1)  <- LOAD-USE HAZARD!
         → Stall IF, ID; Flush EX (insert bubble)
Cycle 3: LW x1, 0(x2)      (MEM stage - đọc từ memory)
         ADD x3, x1, x4    (ID stage - vẫn cần x1)
         → Stall IF, ID; Flush EX (insert bubble)
Cycle 4: LW x1, 0(x2)      (WB stage - write x1 vào register file)
         ADD x3, x1, x4    (ID stage - x1 đã có trong register file)
         → Không stall, tiếp tục
```

### 4. Control Hazard Detection

**Vấn đề:** Mispredicted branch/jump gây ra wrong-path instructions trong pipeline.

**Giải pháp:** Flush pipeline khi phát hiện misprediction.

```systemverilog
// Control hazard: flush if mispredicted branch/jump
if (ex_is_ctrl && ex_enable) begin
    logic actual_taken;
    logic [31:0] actual_target;
    
    if (ex_branch) begin
        actual_taken = ex_branch_taken;
        actual_target = ex_branch_target;
    end else begin
        actual_taken = 1'b1;  // Jumps always taken
        actual_target = ex_jump_target;
    end
    
    // Misprediction: predicted != actual
    if (ex_predicted_taken != actual_taken) begin
        flush_if = 1'b1;
        flush_id = 1'b1;
        flush_ex = 1'b1;
    end
end
```

## Pipeline Stages

### IF (Instruction Fetch)
- Fetch instruction từ IMEM dựa trên PC
- BTB lookup để predict branch/jump target
- Tính PC+4 cho sequential execution

### ID (Instruction Decode)
- Decode instruction và extract fields (rs1, rs2, rd, immediate)
- Control Unit tạo control signals
- Register File đọc rs1 và rs2
- Immediate Generator tạo immediate value
- Hazard Detection kiểm tra data hazards

### EX (Execute)
- ALU thực hiện operations (sử dụng dữ liệu từ register file, KHÔNG forward)
- Branch comparison (sử dụng dữ liệu từ register file)
- Tính branch/jump target addresses
- Phát hiện misprediction

### MEM (Memory Access)
- Data Memory read/write operations
- I/O memory mapping (LED, HEX, LCD, Switch)
- ALU result được lưu trong EX/MEM register

### WB (Write Back)
- Writeback MUX chọn dữ liệu (ALU result, memory data, PC+4, I/O data)
- Write vào Register File
- Dữ liệu có sẵn cho instruction tiếp theo

## Branch Prediction

Model 1 sử dụng **Two-bit Dynamic Branch Predictor** với **BTB (256 entries)**:

- **BTB Lookup**: Trong IF stage, kiểm tra PC có trong BTB không
- **Two-bit State Machine**: 
  - `00`: Strongly not-taken
  - `01`: Weakly not-taken
  - `10`: Weakly taken
  - `11`: Strongly taken
- **BTB Update**: Trong EX stage, khi branch/jump được resolve, cập nhật BTB và predictor state

## Performance Characteristics

### IPC (Instructions Per Cycle)
- **Thấp hơn Model 2** do nhiều pipeline stalls
- Nhiều data hazards không thể forward → nhiều bubbles
- Load-use hazards luôn cần stall

### Stall Cycles
- **Data hazards**: 1-2 stall cycles (tùy thuộc vào instruction type)
- **Load-use hazards**: 1 stall cycle (bắt buộc)
- **Control hazards**: Flush (không stall, nhưng mất cycles do wrong-path)

### So sánh với Model 2
```
Example: ADD x1, x2, x3; ADD x4, x1, x5

Model 1 (Non-Forwarding):
- Cycle 1: ADD x1 (EX)
- Cycle 2: ADD x4 (ID) → Stall (wait for x1)
- Cycle 3: ADD x1 (MEM), ADD x4 (ID) → Stall
- Cycle 4: ADD x1 (WB), ADD x4 (ID) → Continue
- Cycle 5: ADD x4 (EX)
→ Total: 5 cycles (2 stalls)

Model 2 (Forwarding):
- Cycle 1: ADD x1 (EX)
- Cycle 2: ADD x4 (ID)
- Cycle 3: ADD x1 (MEM), ADD x4 (EX) → Forward x1 from MEM
- Cycle 4: ADD x1 (WB), ADD x4 (MEM)
- Cycle 5: ADD x4 (WB)
→ Total: 5 cycles (0 stalls, forward từ MEM)
```

## Chạy Simulation

### Verilator (Local)
```bash
cd 10_sim
make              # Compile and run
make wave         # Open GTKWave (nếu có waveform)
```

### Xcelium (Server)
```bash
cd 11_xm
module load xcelium  # Load Xcelium module (nếu cần)
make                 # Run simulation
make gui            # Open SimVision GUI
```

## Tính năng nâng cao

### 1. BRAM-Compatible Synchronous Memory
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

### 2. I/O Memory Mapping
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

### 3. Branch Prediction với BTB
- **Two-bit Dynamic Branch Predictor**: 
  - State machine với 4 states (00, 01, 10, 11)
  - Cập nhật state dựa trên actual branch outcome
- **Branch Target Buffer (BTB)**:
  - 256 entries với tag-based lookup
  - Lưu trữ: tag, predicted PC, và two-bit predictor state
  - Lookup trong IF stage để predict PC
  - Update trong EX stage khi branch/jump được resolve
- **Misprediction Handling**:
  - Flush pipeline khi misprediction được phát hiện
  - Correct PC được set trong cycle tiếp theo

### 4. Debug và Monitoring Signals
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

## Kết quả mong đợi

### Functional Correctness
- ✅ **Tất cả ISA tests PASS** (giống Model 2)
- ✅ **I/O operations hoạt động đúng**
- ✅ **Branch prediction hoạt động đúng**
- ✅ **Memory operations hoạt động đúng** (64 KiB, BRAM compatible)

### Performance Metrics
- ⚠️ **IPC thấp hơn Model 2** (do nhiều stalls)
- ⚠️ **Nhiều pipeline bubbles hơn**
- ✅ **Misprediction rate tương tự Model 2** (cùng branch predictor)
- ✅ **Memory performance tương tự Model 2** (cùng BRAM architecture)

### Benchmarking
Khi benchmark, Model 1 sẽ cho thấy:
- Số lượng stall cycles cao hơn
- IPC thấp hơn
- Tổng số cycles cao hơn cho cùng một program

## Use Cases

Model 1 được sử dụng để:
1. **So sánh performance** với Model 2 (Forwarding)
2. **Hiểu tác động của forwarding** lên pipeline performance
3. **Baseline implementation** trước khi thêm forwarding
4. **Educational purposes** để minh họa data hazards và stall mechanism

## Lưu ý Implementation

### Forwarding Unit
- Forwarding Unit code vẫn có trong file nhưng **luôn trả về `2'b00`**
- Forwarding MUXes vẫn có nhưng luôn chọn input `00` (register file data)
- Điều này cho phép dễ dàng chuyển đổi sang Model 2 bằng cách enable forwarding

### Hazard Detection
- Chỉ detect load-use hazards (bắt buộc phải stall)
- Các data hazards khác được "giải quyết" bằng cách đợi dữ liệu có trong register file
- Không có logic phức tạp để detect tất cả data hazards (vì không cần forward)
- Control hazards được handle bằng flush mechanism

### Code Structure
- Code structure giống Model 2
- Dễ dàng so sánh và chuyển đổi giữa 2 models
- Chỉ khác ở Forwarding Unit logic

### Memory Architecture
- **Synchronous Memory**: Tất cả memory operations là synchronous (clocked)
- **BRAM Compatibility**: Memory được thiết kế để synthesize thành BRAM trong Quartus
- **64 KiB Size**: Cả IMEM và DMEM đều 64 KiB (theo yêu cầu Milestone 3)
- **Auto File Detection**: Memory tự động detect và load file format phù hợp

### I/O Implementation
- **Memory-mapped I/O**: I/O peripherals được map vào memory address space
- **Address Decoder**: Decode address để xác định memory region vs I/O region
- **Flexible HEX Support**: Hỗ trợ write byte, halfword, và word cho HEX displays
- **I/O Pipeline**: I/O data được forward qua pipeline như memory data

## Troubleshooting

### Nhiều stalls không mong đợi
- Kiểm tra Forwarding Unit có đang trả về `2'b00` không
- Kiểm tra Hazard Detection có đang stall đúng không

### Performance thấp
- Đây là behavior mong đợi của Model 1
- So sánh với Model 2 để thấy sự khác biệt

### Tests fail
- Kiểm tra Hazard Detection logic
- Kiểm tra stall/flush signals có đúng không
- So sánh với Model 2 để tìm lỗi

## Tài liệu tham khảo

- `FORWARDING_EXPLANATION.md`: Giải thích chi tiết về forwarding mechanism
- `../pl-test-model-2/README.md`: README của Model 2 (Forwarding)
- `milestone-3.pdf`: Tài liệu yêu cầu Milestone 3

## Kết luận

Model 1 (Non-Forwarding) là baseline implementation để so sánh với Model 2 (Forwarding). Mặc dù performance thấp hơn do nhiều stalls, nhưng Model 1 vẫn đảm bảo functional correctness và là foundation tốt để hiểu tác động của forwarding mechanism lên pipeline performance.

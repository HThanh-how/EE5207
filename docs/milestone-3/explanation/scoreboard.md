# Giải Thích File: scoreboard.sv

## 📋 Tổng Quan

File `scoreboard.sv` chứa module **Scoreboard** - đây là "giám khảo" của testbench. Scoreboard theo dõi và thống kê performance của processor, đồng thời in kết quả test.

## 🎯 Module Làm Gì?

Scoreboard giống như một **giám khảo thi đấu**:
- Đếm số cycles (số chu kỳ clock)
- Đếm số instructions (số lệnh đã thực hiện)
- Đếm số branch instructions
- Đếm số mispredictions
- Tính IPC (Instructions Per Cycle)
- Tính misprediction rate
- In kết quả test từ chương trình

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module scoreboard(
  input  logic         i_clk     ,    // Xung nhịp
  input  logic         i_reset   ,   // Reset signal
  // Input peripherals
  input  logic [31:0]  i_io_sw   ,   // Switches (không dùng trong scoreboard)
  // Output peripherals (để đọc kết quả test)
  input  logic [31:0]  o_io_ledr ,  // LED đỏ (chứa kết quả test)
  input  logic [31:0]  o_io_ledg ,  // LED xanh (không dùng)
  input  logic [ 6:0]  o_io_hex0 ,  // HEX displays (không dùng)
  ...
  input  logic [31:0]  o_io_lcd  ,  // LCD (không dùng)
  // Debug signals
  input  logic         o_ctrl    ,   // Control transfer signal (branch/jump)
  input  logic         o_mispred ,  // Misprediction signal
  input  logic [31:0]  o_pc_debug,  // Program Counter (để biết chương trình đang ở đâu)
  input  logic         o_insn_vld   // Instruction valid signal
);
```

**Giải thích**:
- `i_clk`, `i_reset`: Clock và reset
- `o_io_ledr`: LED đỏ - chứa kết quả test (PASS/ERROR messages)
- `o_ctrl`: = 1 khi instruction là branch/jump
- `o_mispred`: = 1 khi branch/jump bị mispredicted
- `o_pc_debug`: Program Counter - để biết chương trình đang ở đâu
- `o_insn_vld`: = 1 khi instruction hợp lệ (đã hoàn thành)

### 2. Khai Báo Biến Thống Kê

```systemverilog
real num_cycle;      // Số cycles đã thực hiện
real num_insn;       // Số instructions đã thực hiện
real num_ctrl;       // Số control transfer instructions (branch/jump)
real num_mispred;    // Số mispredictions
real ipc;            // Instructions Per Cycle
real misprd_rate;    // Misprediction Rate (%)
```

**Giải thích**:
- Dùng `real` (số thực) để tính toán chính xác
- `num_cycle`: Đếm số chu kỳ clock
- `num_insn`: Đếm số lệnh đã thực hiện
- `num_ctrl`: Đếm số branch/jump instructions
- `num_mispred`: Đếm số lần dự đoán sai
- `ipc`: Tính từ `num_insn / num_cycle`
- `misprd_rate`: Tính từ `num_mispred / num_ctrl * 100`

### 3. Hiển Thị Tên Test

```systemverilog
initial begin
  $display("\nPIPELINE - ISA tests\n");
end
```

**Giải thích**:
- `initial begin`: Chạy một lần khi simulation bắt đầu
- In tiêu đề test

### 4. Đếm Thống Kê

```systemverilog
always @(negedge i_clk) begin : counters
    if (!i_reset) begin
      num_cycle   <= '0;      // Reset về 0
      num_ctrl    <= '0;
      num_insn    <= '0;
      num_mispred <= '0;
    end
    else begin
      num_cycle   <=              num_cycle   + 1;           // Mỗi cycle tăng 1
      num_ctrl    <= o_ctrl     ? num_ctrl    + 1 : num_ctrl; // Tăng nếu có branch/jump
      num_insn    <= o_insn_vld ? num_insn    + 1 : num_insn; // Tăng nếu có instruction hợp lệ
      num_mispred <= o_mispred  ? num_mispred + 1 : num_mispred; // Tăng nếu có misprediction
    end
end
```

**Giải thích từng phần**:

#### `always @(negedge i_clk)`
- Chạy tại cạnh xuống của clock (negedge)
- Để tránh race condition với processor (processor dùng posedge)

#### `if (!i_reset)`
- Khi reset (reset = 0), reset tất cả counters về 0

#### `num_cycle <= num_cycle + 1`
- Mỗi cycle tăng 1 (luôn tăng khi không reset)

#### `num_ctrl <= o_ctrl ? num_ctrl + 1 : num_ctrl`
- Chỉ tăng khi `o_ctrl = 1` (có branch/jump instruction)

#### `num_insn <= o_insn_vld ? num_insn + 1 : num_insn`
- Chỉ tăng khi `o_insn_vld = 1` (có instruction hợp lệ)
- Không đếm bubbles (stall cycles)

#### `num_mispred <= o_mispred ? num_mispred + 1 : num_mispred`
- Chỉ tăng khi `o_mispred = 1` (có misprediction)

### 5. In Kết Quả Test Từ Chương Trình

```systemverilog
always @(negedge i_clk) begin : debug
    if (o_insn_vld && (o_pc_debug == 32'h18)) begin
        $write("%s", o_io_ledr[7:0]);
    end
end
```

**Giải thích**:
- Khi PC = 0x18 và có instruction hợp lệ
- In ký tự từ `o_io_ledr[7:0]` (8 bits thấp)
- Chương trình test ghi kết quả (PASS/ERROR) vào LED đỏ tại PC = 0x18

**Ví dụ**:
- Chương trình test ghi "PASS" vào `o_io_ledr[7:0]` tại PC = 0x18
- Scoreboard in "PASS" ra màn hình

### 6. In Kết Quả Thống Kê và Kết Thúc

```systemverilog
always @(negedge i_clk) begin : result
    if (o_insn_vld && ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20))) begin
        $display("\n=================== Result ===================");
        
        // In số cycles
        if (num_cycle != 0) $display("Total Clock Cycles Executed = %1.0f", num_cycle);
        else                $display("Total Clock Cycles Executed = N/A");
        
        // In số instructions
        if (num_insn  != 0) $display("Total Instructions Executed = %1.0f", num_insn);
        else                $display("Total Instructions Executed = N/A");
        
        // In số branch instructions
        if (num_cycle != 0) $display("Total Branch Instructions   = %1.0f", num_ctrl);
        else                $display("Total Branch Instructions   = N/A");
        
        // In số mispredictions
        if (num_cycle != 0) $display("Total Branch Mispredictions = %1.0f", num_mispred);
        else                $display("Total Branch Mispredictions = N/A");
        
        $display("\n----------------------------------------------");
        
        // Tính và in IPC
        if (num_cycle != 0) $display("Instruction Per Cycle (IPC) = %1.2f", num_insn/num_cycle);
        else                $display("Instruction Per Cycle (IPC) = N/A");
        
        // Tính và in misprediction rate
        if (num_ctrl != 0)  $display("Branch Misprediction Rate   = %2.2f %%", num_mispred/num_ctrl * 100);
        else                $display("Branch Misprediction Rate   = N/A");
        
        $display("\nEND of ISA tests\n");
        $finish;  // Kết thúc simulation
    end
end
```

**Giải thích từng phần**:

#### Điều Kiện Kích Hoạt
```systemverilog
if (o_insn_vld && ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20)))
```
- Khi PC = 0x1c hoặc 0x20 và có instruction hợp lệ
- Chương trình test kết thúc tại PC = 0x1c hoặc 0x20

#### In Số Cycles
```systemverilog
$display("Total Clock Cycles Executed = %1.0f", num_cycle);
```
- In số cycles đã thực hiện (format số nguyên)

#### In Số Instructions
```systemverilog
$display("Total Instructions Executed = %1.0f", num_insn);
```
- In số lệnh đã thực hiện

#### In Số Branch Instructions
```systemverilog
$display("Total Branch Instructions   = %1.0f", num_ctrl);
```
- In số branch/jump instructions

#### In Số Mispredictions
```systemverilog
$display("Total Branch Mispredictions = %1.0f", num_mispred);
```
- In số lần dự đoán sai

#### Tính và In IPC
```systemverilog
$display("Instruction Per Cycle (IPC) = %1.2f", num_insn/num_cycle);
```
- IPC = số lệnh / số cycles
- Format 2 chữ số thập phân

**Ví dụ**:
- `num_insn = 100`, `num_cycle = 120` → `IPC = 0.83`

#### Tính và In Misprediction Rate
```systemverilog
$display("Branch Misprediction Rate   = %2.2f %%", num_mispred/num_ctrl * 100);
```
- Misprediction rate = (số mispredictions / số branch instructions) × 100%
- Format 2 chữ số thập phân

**Ví dụ**:
- `num_mispred = 5`, `num_ctrl = 50` → `Rate = 10.00%`

#### Kết Thúc Simulation
```systemverilog
$finish;
```
- Kết thúc simulation khi in xong kết quả

## 🎬 Ví Dụ Thực Tế

### Ví Dụ 1: Đếm Cycles và Instructions

**Giả sử**: Processor chạy 100 instructions trong 120 cycles

**Scoreboard đếm**:
- `num_cycle = 120` (mỗi cycle tăng 1)
- `num_insn = 100` (chỉ tăng khi `o_insn_vld = 1`, không đếm bubbles)

**Kết quả**:
- `IPC = 100 / 120 = 0.83`

### Ví Dụ 2: Đếm Branch Instructions và Mispredictions

**Giả sử**: Có 50 branch instructions, 5 lần mispredicted

**Scoreboard đếm**:
- `num_ctrl = 50` (mỗi khi `o_ctrl = 1` tăng 1)
- `num_mispred = 5` (mỗi khi `o_mispred = 1` tăng 1)

**Kết quả**:
- `Misprediction Rate = 5 / 50 × 100% = 10.00%`

### Ví Dụ 3: In Kết Quả Test

**Chương trình test**:
- Tại PC = 0x18: Ghi "PASS" vào `o_io_ledr[7:0]`
- Tại PC = 0x1c: Kết thúc chương trình

**Scoreboard**:
- Tại PC = 0x18: In "PASS" ra màn hình
- Tại PC = 0x1c: In thống kê và kết thúc

## 📊 Output Mẫu

```
PIPELINE - ISA tests

PASS

=================== Result ===================
Total Clock Cycles Executed = 120
Total Instructions Executed = 100
Total Branch Instructions   = 50
Total Branch Mispredictions = 5

----------------------------------------------
Instruction Per Cycle (IPC) = 0.83
Branch Misprediction Rate   = 10.00 %

END of ISA tests
```

## 🔍 Điểm Quan Trọng

### 1. Negedge Clock

- Scoreboard dùng `negedge` để tránh race condition với processor (processor dùng `posedge`)
- Đảm bảo đọc giá trị đúng

### 2. Instruction Valid Signal

- Chỉ đếm khi `o_insn_vld = 1` (instruction hợp lệ)
- Không đếm bubbles (stall cycles)

### 3. PC-Based Triggering

- In kết quả test tại PC = 0x18
- In thống kê và kết thúc tại PC = 0x1c hoặc 0x20
- Chương trình test phải tuân theo convention này

### 4. Real Number Arithmetic

- Dùng `real` để tính toán chính xác
- Format output: `%1.0f` (số nguyên), `%1.2f` (2 chữ số thập phân), `%2.2f` (2 chữ số thập phân, 2 chữ số trước dấu chấm)

## 🎓 Kết Luận

Scoreboard là module quan trọng trong testbench, theo dõi và thống kê performance của processor. Module này:
- Đếm cycles, instructions, branches, mispredictions
- Tính IPC và misprediction rate
- In kết quả test từ chương trình
- In thống kê và kết thúc simulation


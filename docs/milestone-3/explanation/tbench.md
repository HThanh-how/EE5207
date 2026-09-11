# Giải Thích File: tbench.sv

## 📋 Tổng Quan

File `tbench.sv` chứa module **Testbench** - đây là module top-level của testbench, kết nối tất cả các module lại với nhau và tạo clock/reset.

## 🎯 Module Làm Gì?

Testbench giống như một **phòng thí nghiệm**:
- Tạo clock và reset
- Kết nối processor (DUT - Device Under Test)
- Kết nối driver (cung cấp input)
- Kết nối scoreboard (theo dõi và thống kê)
- Tạo waveform dump (để xem signal trong simulation)

## 📝 Code Chi Tiết

### 1. Định Nghĩa Constants

```systemverilog
`define RESET_PERIOD 51      // Thời gian reset (51 time units)
`define CLOCK_PERIOD 2       // Chu kỳ clock (2 time units = 1 cycle)
`define TIMEOUT      50_000  // Timeout (50,000 time units)
```

**Giải thích**:
- `RESET_PERIOD = 51`: Reset kéo dài 51 time units
- `CLOCK_PERIOD = 2`: Mỗi chu kỳ clock = 2 time units (1 time unit cho high, 1 cho low)
- `TIMEOUT = 50_000`: Nếu simulation chạy quá 50,000 time units → timeout (có thể có lỗi)

### 2. Khai Báo Module

```systemverilog
module tbench;

  // Clock and reset generator
  logic clk;
  logic rstn;
```

**Giải thích**:
- `clk`: Clock signal
- `rstn`: Reset signal (active low - `rstn = 0` nghĩa là reset)

### 3. Tạo Clock và Reset

```systemverilog
initial tsk_clock_gen(clk , `CLOCK_PERIOD);
initial tsk_reset    (rstn, `RESET_PERIOD);
initial tsk_timeout  (`TIMEOUT);
```

**Giải thích**:
- `tsk_clock_gen()`: Task tạo clock với chu kỳ `CLOCK_PERIOD`
- `tsk_reset()`: Task tạo reset signal với thời gian `RESET_PERIOD`
- `tsk_timeout()`: Task kiểm tra timeout

**Các task này được định nghĩa trong `tlib.svh`**

### 4. Wave Dumping

```systemverilog
initial begin: proc_dump_shm
    $shm_open("wave.shm");
    $shm_probe(dut, "AS");
end
```

**Giải thích**:
- `$shm_open("wave.shm")`: Mở file waveform dump
- `$shm_probe(dut, "AS")`: Probe tất cả signals trong `dut` (processor)
- "AS" = All Signals (tất cả signals)

**Mục đích**: Để xem waveform trong SimVision hoặc GTKWave

### 5. Khai Báo Signals

```systemverilog
logic [31:0]  pc_debug;
logic [31:0]  io_sw  ;
logic [31:0]  io_lcd ;
logic [31:0]  io_ledr;
logic [31:0]  io_ledg;
logic [ 6:0]  io_hex0;
...
logic         ctrl    ;
logic         mispred ;
logic         insn_vld;
```

**Giải thích**:
- Các signals để kết nối giữa các module
- `pc_debug`, `ctrl`, `mispred`, `insn_vld`: Debug signals từ processor
- `io_sw`, `io_lcd`, `io_ledr`, ...: I/O signals

### 6. Kết Nối Processor (DUT)

```systemverilog
pipelined dut (
  .i_clk     (clk      ),
  .i_reset   (rstn     ),
  // Input peripherals
  .i_io_sw   (io_sw    ),
  // Output peripherals
  .o_io_lcd  (io_lcd   ),
  .o_io_ledr (io_ledr  ),
  .o_io_ledg (io_ledg  ),
  .o_io_hex0 (io_hex0  ),
  ...
  // Debug
  .o_ctrl    (ctrl     ),
  .o_mispred (mispred  ),
  .o_pc_debug(pc_debug ),
  .o_insn_vld(insn_vld )
);
```

**Giải thích**:
- `dut` (Device Under Test) = processor
- Kết nối tất cả inputs và outputs
- Clock, reset, I/O, và debug signals

### 7. Kết Nối Driver

```systemverilog
driver driver (
  .i_clk  (clk   ),
  .i_reset(rstn  ),
  .i_io_sw(io_sw )
);
```

**Giải thích**:
- Driver cung cấp giá trị cho `io_sw`
- Processor đọc `io_sw` thông qua memory-mapped I/O

### 8. Kết Nối Scoreboard

```systemverilog
scoreboard  scoreboard(
  .i_clk     (clk      ),
  .i_reset   (rstn     ),
  // Input peripherals
  .i_io_sw   (io_sw    ),
  // Output peripherals
  .o_io_lcd  (io_lcd   ),
  .o_io_ledr (io_ledr  ),
  ...
  // Debug
  .o_ctrl    (ctrl     ),
  .o_mispred (mispred  ),
  .o_pc_debug(pc_debug ),
  .o_insn_vld(insn_vld )
);
```

**Giải thích**:
- Scoreboard nhận tất cả signals từ processor
- Theo dõi và thống kê performance
- In kết quả test

## 🎬 Ví Dụ Thực Tế

### Timeline Simulation

```
Time 0:
  - Reset = 0 (active) → Processor reset
  - Clock bắt đầu chạy

Time 0-51:
  - Reset = 0 → Processor vẫn reset
  - Clock tiếp tục chạy

Time 51:
  - Reset = 1 → Processor bắt đầu chạy
  - Processor fetch lệnh đầu tiên

Time 51+:
  - Processor chạy chương trình
  - Scoreboard đếm cycles, instructions, ...
  - Driver cung cấp input cho switches

Time khi PC = 0x1c hoặc 0x20:
  - Scoreboard in kết quả và kết thúc simulation
```

## 🔍 Điểm Quan Trọng

### 1. Clock và Reset Generation

- Clock và reset được tạo bằng tasks trong `tlib.svh`
- Reset kéo dài 51 time units
- Clock có chu kỳ 2 time units

### 2. Waveform Dumping

- Tạo file `wave.shm` để xem waveform
- Probe tất cả signals trong processor
- Có thể mở bằng SimVision hoặc GTKWave

### 3. Module Instantiation

- `dut`: Processor (Device Under Test)
- `driver`: Cung cấp input
- `scoreboard`: Theo dõi và thống kê

### 4. Signal Naming

- Tên signals trong testbench khớp với tên trong processor
- Dễ debug và theo dõi

## 📊 Sơ Đồ Kết Nối

```
┌─────────────┐
│   Driver    │───io_sw───┐
└─────────────┘           │
                          ▼
                    ┌──────────┐
                    │ Processor│
                    │  (DUT)   │
                    └──────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
  ┌──────────┐    ┌──────────┐    ┌──────────┐
  │   I/O    │    │  Debug   │    │Scoreboard│
  │ Signals  │    │ Signals  │    │          │
  └──────────┘    └──────────┘    └──────────┘
```

## 🎓 Kết Luận

Testbench là module top-level, kết nối tất cả các module lại với nhau và tạo môi trường test cho processor. Module này:
- Tạo clock và reset
- Kết nối processor, driver, và scoreboard
- Tạo waveform dump
- Quản lý simulation




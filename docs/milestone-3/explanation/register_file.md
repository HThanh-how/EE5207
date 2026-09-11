# Giải Thích File: register_file.sv

## 📋 Tổng Quan

File `register_file.sv` chứa module **Register File** - đây là "kho lưu trữ" của processor. Register File lưu trữ 32 thanh ghi (x0-x31) và cho phép đọc/ghi dữ liệu.

## 🎯 Module Làm Gì?

Register File giống như một **tủ có 32 ngăn kéo**:
- Mỗi ngăn kéo là một thanh ghi (32 bits)
- Có thể đọc từ 2 ngăn kéo cùng lúc (rs1 và rs2)
- Có thể ghi vào 1 ngăn kéo (rd)

**Ví dụ đơn giản**:
- Đọc: "Lấy giá trị từ ngăn kéo số 2 (x2) và ngăn kéo số 3 (x3)"
- Ghi: "Ghi giá trị 100 vào ngăn kéo số 1 (x1)"

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module register_file (
    input  logic         clk,        // Xung nhịp
    input  logic         we,         // Write enable - cho phép ghi
    input  logic [ 4:0]  addr_rs1,   // Địa chỉ thanh ghi nguồn 1 (đọc)
    input  logic [ 4:0]  addr_rs2,   // Địa chỉ thanh ghi nguồn 2 (đọc)
    input  logic [ 4:0]  addr_rd,    // Địa chỉ thanh ghi đích (ghi)
    input  logic [31:0]  wdata,      // Dữ liệu cần ghi
    output logic [31:0]  rdata_rs1,  // Dữ liệu đọc từ rs1
    output logic [31:0]  rdata_rs2   // Dữ liệu đọc từ rs2
);
```

**Giải thích**:
- `clk`: Xung nhịp (cần cho thao tác ghi)
- `we`: Write enable - chỉ ghi khi `we = 1`
- `addr_rs1`, `addr_rs2`: Địa chỉ 2 thanh ghi cần đọc (0-31)
- `addr_rd`: Địa chỉ thanh ghi cần ghi (0-31)
- `wdata`: Dữ liệu 32 bits cần ghi
- `rdata_rs1`, `rdata_rs2`: Dữ liệu 32 bits đọc được

### 2. Khai Báo Mảng Thanh Ghi

```systemverilog
logic [31:0] registers [0:31];
```

**Giải thích**:
- `registers` là mảng 32 phần tử, mỗi phần tử 32 bits
- `registers[0]` = x0, `registers[1]` = x1, ..., `registers[31]` = x31

**Ví dụ**:
- `registers[1] = 100` nghĩa là x1 = 100
- `registers[2] = 200` nghĩa là x2 = 200

### 3. Logic Ghi (Write)

```systemverilog
always_ff @(posedge clk) begin
    if (we && addr_rd != 5'b0) begin
        registers[addr_rd] <= wdata;
    end
end
```

**Giải thích từng phần**:

#### `always_ff @(posedge clk)`
- `always_ff`: Sequential logic (cần clock)
- `@(posedge clk)`: Chỉ thực hiện khi có cạnh lên của clock

#### `if (we && addr_rd != 5'b0)`
- `we`: Chỉ ghi khi write enable = 1
- `addr_rd != 5'b0`: Không ghi vào x0 (theo đặc tả RISC-V, x0 luôn = 0)

#### `registers[addr_rd] <= wdata`
- Ghi `wdata` vào thanh ghi tại địa chỉ `addr_rd`
- Dùng `<=` (non-blocking assignment) cho sequential logic

**Ví dụ**:
- `we = 1`, `addr_rd = 1`, `wdata = 100`
- → `registers[1] = 100` (x1 = 100)

**Ví dụ không ghi**:
- `we = 0` → Không ghi (dù `addr_rd` và `wdata` có giá trị gì)
- `addr_rd = 0` → Không ghi vào x0 (x0 luôn = 0)

### 4. Logic Đọc (Read)

```systemverilog
assign rdata_rs1 = (addr_rs1 == 5'b0) ? 32'b0 : registers[addr_rs1];
assign rdata_rs2 = (addr_rs2 == 5'b0) ? 32'b0 : registers[addr_rs2];
```

**Giải thích**:

#### `assign rdata_rs1 = ...`
- `assign`: Combinational logic (không cần clock, đọc ngay lập tức)
- `(addr_rs1 == 5'b0) ? 32'b0 : registers[addr_rs1]`
  - Nếu đọc từ x0 (`addr_rs1 = 0`) → trả về 0
  - Ngược lại → trả về giá trị trong `registers[addr_rs1]`

**Ví dụ**:
- `addr_rs1 = 1`, `registers[1] = 100` → `rdata_rs1 = 100`
- `addr_rs1 = 0` → `rdata_rs1 = 0` (x0 luôn = 0)

**Lưu ý quan trọng**:
- Đọc là **combinational** (ngay lập tức)
- Ghi là **sequential** (cần clock)

## 🎬 Ví Dụ Thực Tế

### Ví Dụ 1: Đọc 2 Thanh Ghi

**Lệnh**: `ADD x1, x2, x3` (x1 = x2 + x3)

**Giả sử**: `x2 = 10`, `x3 = 20`

**Register File nhận**:
- `addr_rs1 = 2` (x2)
- `addr_rs2 = 3` (x3)
- `we = 0` (chưa ghi)

**Register File trả về**:
- `rdata_rs1 = registers[2] = 10`
- `rdata_rs2 = registers[3] = 20`

**Kết quả**: ALU nhận `op_a = 10`, `op_b = 20`, tính `10 + 20 = 30`

### Ví Dụ 2: Ghi Vào Thanh Ghi

**Sau khi ALU tính xong** (x1 = 30):

**Register File nhận**:
- `we = 1` ✅
- `addr_rd = 1` (x1)
- `wdata = 30`

**Tại cạnh lên của clock**:
- `registers[1] <= 30`
- → `x1 = 30` ✅

### Ví Dụ 3: Đọc và Ghi Cùng Lúc

**Lệnh**: `ADD x1, x1, x2` (x1 = x1 + x2)

**Giả sử**: `x1 = 10`, `x2 = 5`

**Cycle 1 - Đọc**:
- `addr_rs1 = 1` (x1) → `rdata_rs1 = 10`
- `addr_rs2 = 2` (x2) → `rdata_rs2 = 5`
- ALU tính: `10 + 5 = 15`

**Cycle 2 - Ghi** (tại cạnh lên của clock):
- `we = 1`, `addr_rd = 1`, `wdata = 15`
- `registers[1] <= 15`
- → `x1 = 15` ✅

**Lưu ý**: Đọc và ghi có thể xảy ra cùng lúc (đọc từ thanh ghi khác, ghi vào thanh ghi khác)

### Ví Dụ 4: X0 Luôn = 0

**Lệnh**: `ADD x1, x0, x2` (x1 = x0 + x2 = 0 + x2 = x2)

**Register File nhận**:
- `addr_rs1 = 0` (x0)
- `addr_rs2 = 2` (x2)

**Register File trả về**:
- `rdata_rs1 = 0` (x0 luôn = 0, dù `registers[0]` có giá trị gì)
- `rdata_rs2 = registers[2]`

**Kết quả**: `x1 = x2` (copy x2 vào x1)

**Lưu ý**: Dù có cố ghi vào x0 (`we = 1`, `addr_rd = 0`), x0 vẫn = 0!

## 🔍 Điểm Quan Trọng

### 1. X0 Luôn = 0

Theo đặc tả RISC-V, thanh ghi x0 luôn = 0 và không thể thay đổi:
- Đọc từ x0 → luôn trả về 0
- Ghi vào x0 → không có tác dụng (code kiểm tra `addr_rd != 5'b0`)

### 2. Đọc là Combinational, Ghi là Sequential

- **Đọc**: `assign` → ngay lập tức, không cần clock
- **Ghi**: `always_ff @(posedge clk)` → cần clock, ghi tại cạnh lên

**Lý do**: 
- Đọc cần nhanh (dùng ngay cho ALU)
- Ghi cần đồng bộ (tránh race condition)

### 3. Có Thể Đọc 2 Thanh Ghi Cùng Lúc

RISC-V instructions thường cần 2 thanh ghi làm input:
- `ADD x1, x2, x3` → cần x2 và x3
- `SUB x1, x2, x3` → cần x2 và x3
- `BEQ x1, x2, label` → cần x1 và x2 để so sánh

### 4. Write-After-Read (WAR) Hazard

**Vấn đề**: Đọc và ghi cùng một thanh ghi trong cùng cycle?

**Giải pháp trong code**:
- Đọc là combinational → đọc giá trị **cũ** (trước khi ghi)
- Ghi là sequential → ghi giá trị **mới** (sau clock edge)

**Ví dụ**:
```
Cycle N:
  - Đọc x1 (combinational) → đọc giá trị cũ
  - Ghi x1 = 100 (sequential) → chưa ghi

Cycle N+1:
  - Đọc x1 (combinational) → đọc giá trị mới (100)
```

## 📊 Bảng Tóm Tắt

| Thao Tác | Loại Logic | Cần Clock? | Ví Dụ |
|----------|------------|-------------|-------|
| Đọc rs1 | Combinational | ❌ Không | `rdata_rs1 = registers[addr_rs1]` |
| Đọc rs2 | Combinational | ❌ Không | `rdata_rs2 = registers[addr_rs2]` |
| Ghi rd | Sequential | ✅ Có | `registers[addr_rd] <= wdata` |

## 🎓 Kết Luận

Register File là module đơn giản nhưng quan trọng, lưu trữ 32 thanh ghi và cho phép đọc/ghi dữ liệu. Module này đảm bảo:
- X0 luôn = 0
- Đọc nhanh (combinational)
- Ghi an toàn (sequential, cần clock)




# Giải Thích File: alu.sv

## 📋 Tổng Quan

File `alu.sv` chứa module **ALU (Arithmetic Logic Unit)** - đây là "bộ não tính toán" của processor. ALU thực hiện tất cả các phép toán số học và logic.

## 🎯 Module Làm Gì?

ALU nhận 2 số (32 bits mỗi số) và một mã lệnh, sau đó thực hiện phép toán tương ứng và trả về kết quả.

**Ví dụ đơn giản**:
- Input: `op_a = 10`, `op_b = 5`, `alu_op = 0000` (cộng)
- Output: `alu_out = 15` (10 + 5)

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module alu (
    input  logic [31:0]  op_a,      // Toán hạng 1 (số thứ nhất)
    input  logic [31:0]  op_b,      // Toán hạng 2 (số thứ hai)
    input  logic [ 3:0]  alu_op,    // Mã lệnh (phép toán nào?)
    output logic [31:0] alu_out,    // Kết quả
    output logic        alu_zero    // Cờ zero (kết quả = 0?)
);
```

**Giải thích**:
- `op_a`, `op_b`: Hai số cần tính toán (mỗi số 32 bits)
- `alu_op`: Mã 4 bits để chọn phép toán (16 phép toán khác nhau)
- `alu_out`: Kết quả của phép toán (32 bits)
- `alu_zero`: Bằng 1 nếu kết quả = 0 (dùng cho branch instructions)

### 2. Logic Tính Toán

```systemverilog
always_comb begin
    case (alu_op)
        4'b0000: alu_out = op_a + op_b;              // Cộng
        4'b0001: alu_out = op_a - op_b;              // Trừ
        4'b0010: alu_out = op_a & op_b;              // AND (bitwise)
        4'b0011: alu_out = op_a | op_b;              // OR (bitwise)
        4'b0100: alu_out = op_a ^ op_b;              // XOR (bitwise)
        4'b0101: alu_out = op_a << op_b[4:0];        // Shift left
        4'b0110: alu_out = op_a >> op_b[4:0];        // Shift right (logical)
        4'b0111: alu_out = $signed(op_a) >>> op_b[4:0]; // Shift right (arithmetic)
        4'b1000: alu_out = ($signed(op_a) < $signed(op_b)) ? 32'b1 : 32'b0; // So sánh < (signed)
        4'b1001: alu_out = (op_a < op_b) ? 32'b1 : 32'b0; // So sánh < (unsigned)
        default: alu_out = 32'b0;
    endcase
end
```

**Giải thích từng phép toán**:

#### 4'b0000: Cộng (ADD)
```systemverilog
alu_out = op_a + op_b;
```
**Ví dụ**: `op_a = 10`, `op_b = 5` → `alu_out = 15`

#### 4'b0001: Trừ (SUB)
```systemverilog
alu_out = op_a - op_b;
```
**Ví dụ**: `op_a = 10`, `op_b = 5` → `alu_out = 5`

#### 4'b0010: AND (Bitwise AND)
```systemverilog
alu_out = op_a & op_b;
```
**Ví dụ**: 
- `op_a = 5` (binary: `0000_0101`)
- `op_b = 3` (binary: `0000_0011`)
- `alu_out = 1` (binary: `0000_0001`) - chỉ bit nào cả 2 đều là 1 thì mới là 1

#### 4'b0011: OR (Bitwise OR)
```systemverilog
alu_out = op_a | op_b;
```
**Ví dụ**:
- `op_a = 5` (binary: `0000_0101`)
- `op_b = 3` (binary: `0000_0011`)
- `alu_out = 7` (binary: `0000_0111`) - bit nào có ít nhất 1 số là 1 thì là 1

#### 4'b0100: XOR (Bitwise XOR)
```systemverilog
alu_out = op_a ^ op_b;
```
**Ví dụ**:
- `op_a = 5` (binary: `0000_0101`)
- `op_b = 3` (binary: `0000_0011`)
- `alu_out = 6` (binary: `0000_0110`) - bit nào khác nhau thì là 1

#### 4'b0101: Shift Left (Dịch trái)
```systemverilog
alu_out = op_a << op_b[4:0];
```
**Giải thích**: Dịch `op_a` sang trái `op_b[4:0]` bits (chỉ lấy 5 bits thấp của op_b)

**Ví dụ**:
- `op_a = 5` (binary: `0000_0101`)
- `op_b = 2`
- `alu_out = 20` (binary: `0001_0100`) - dịch trái 2 bits = nhân với 4

#### 4'b0110: Shift Right Logical (Dịch phải logic)
```systemverilog
alu_out = op_a >> op_b[4:0];
```
**Giải thích**: Dịch `op_a` sang phải, điền 0 vào bên trái

**Ví dụ**:
- `op_a = 20` (binary: `0001_0100`)
- `op_b = 2`
- `alu_out = 5` (binary: `0000_0101`) - dịch phải 2 bits = chia cho 4

#### 4'b0111: Shift Right Arithmetic (Dịch phải số học)
```systemverilog
alu_out = $signed(op_a) >>> op_b[4:0];
```
**Giải thích**: Dịch `op_a` sang phải, giữ nguyên bit dấu (bit 31)

**Ví dụ với số âm**:
- `op_a = -20` (binary: `1110_1100` trong 2's complement)
- `op_b = 2`
- `alu_out = -5` (binary: `1111_1011`) - dịch phải nhưng giữ bit dấu

#### 4'b1000: So Sánh < (Signed - Có dấu)
```systemverilog
alu_out = ($signed(op_a) < $signed(op_b)) ? 32'b1 : 32'b0;
```
**Giải thích**: Nếu `op_a < op_b` (coi như số có dấu) thì trả về 1, ngược lại 0

**Ví dụ**:
- `op_a = -5`, `op_b = 10` → `alu_out = 1` (vì -5 < 10)
- `op_a = 10`, `op_b = 5` → `alu_out = 0` (vì 10 không < 5)

#### 4'b1001: So Sánh < (Unsigned - Không dấu)
```systemverilog
alu_out = (op_a < op_b) ? 32'b1 : 32'b0;
```
**Giải thích**: Nếu `op_a < op_b` (coi như số không dấu) thì trả về 1, ngược lại 0

**Ví dụ**:
- `op_a = 5`, `op_b = 10` → `alu_out = 1`
- `op_a = 10`, `op_b = 5` → `alu_out = 0`

### 3. Cờ Zero

```systemverilog
assign alu_zero = (alu_out == 32'b0);
```

**Giải thích**: `alu_zero = 1` nếu kết quả bằng 0, ngược lại `alu_zero = 0`

**Ví dụ**:
- `alu_out = 0` → `alu_zero = 1`
- `alu_out = 5` → `alu_zero = 0`

**Dùng cho**: Branch instructions (BEQ, BNE...) để kiểm tra điều kiện

## 🎬 Ví Dụ Thực Tế

### Ví Dụ 1: ADD Instruction

**Lệnh**: `ADD x1, x2, x3` (x1 = x2 + x3)

**Giả sử**: `x2 = 10`, `x3 = 20`

**ALU nhận**:
- `op_a = 10` (từ x2)
- `op_b = 20` (từ x3)
- `alu_op = 0000` (ADD)

**ALU tính**:
- `alu_out = 10 + 20 = 30`
- `alu_zero = 0` (vì 30 ≠ 0)

**Kết quả**: `x1 = 30`

### Ví Dụ 2: SUB Instruction

**Lệnh**: `SUB x1, x2, x3` (x1 = x2 - x3)

**Giả sử**: `x2 = 20`, `x3 = 5`

**ALU nhận**:
- `op_a = 20`
- `op_b = 5`
- `alu_op = 0001` (SUB)

**ALU tính**:
- `alu_out = 20 - 5 = 15`
- `alu_zero = 0`

**Kết quả**: `x1 = 15`

### Ví Dụ 3: AND Instruction

**Lệnh**: `AND x1, x2, x3` (x1 = x2 & x3)

**Giả sử**: `x2 = 5` (binary: `0000_0101`), `x3 = 3` (binary: `0000_0011`)

**ALU nhận**:
- `op_a = 5`
- `op_b = 3`
- `alu_op = 0010` (AND)

**ALU tính**:
- `alu_out = 5 & 3 = 1` (binary: `0000_0001`)
- `alu_zero = 0`

**Kết quả**: `x1 = 1`

### Ví Dụ 4: Shift Left

**Lệnh**: `SLL x1, x2, x3` (x1 = x2 << x3)

**Giả sử**: `x2 = 5`, `x3 = 2`

**ALU nhận**:
- `op_a = 5` (binary: `0000_0101`)
- `op_b = 2`
- `alu_op = 0101` (SLL)

**ALU tính**:
- `alu_out = 5 << 2 = 20` (binary: `0001_0100`)
- `alu_zero = 0`

**Kết quả**: `x1 = 20` (5 × 4 = 20)

## 🔍 Điểm Quan Trọng

1. **Combinational Logic**: ALU dùng `always_comb`, nghĩa là kết quả tính ngay lập tức (không cần clock)

2. **Bit Selection**: `op_b[4:0]` nghĩa là chỉ lấy 5 bits thấp của `op_b` (cho shift operations)

3. **Signed vs Unsigned**: 
   - `$signed()` để xử lý số có dấu
   - Không có `$signed()` để xử lý số không dấu

4. **Zero Flag**: Dùng cho branch instructions để kiểm tra điều kiện

## 📊 Bảng Tóm Tắt

| alu_op | Phép Toán | Ví Dụ | Kết Quả |
|--------|----------|-------|---------|
| 0000 | ADD | 10 + 5 | 15 |
| 0001 | SUB | 10 - 5 | 5 |
| 0010 | AND | 5 & 3 | 1 |
| 0011 | OR | 5 \| 3 | 7 |
| 0100 | XOR | 5 ^ 3 | 6 |
| 0101 | SLL | 5 << 2 | 20 |
| 0110 | SRL | 20 >> 2 | 5 |
| 0111 | SRA | -20 >>> 2 | -5 |
| 1000 | SLT (signed) | -5 < 10 | 1 |
| 1001 | SLTU (unsigned) | 5 < 10 | 1 |

## 🎓 Kết Luận

ALU là module đơn giản nhưng quan trọng, thực hiện tất cả các phép toán số học và logic của processor. Module này nhận 2 số và mã lệnh, trả về kết quả và cờ zero.




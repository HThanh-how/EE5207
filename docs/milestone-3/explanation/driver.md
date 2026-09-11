# Giải Thích File: driver.sv

## 📋 Tổng Quan

File `driver.sv` chứa module **Driver** - đây là module đơn giản cung cấp input cho processor trong testbench. Driver cung cấp giá trị cho switches (công tắc).

## 🎯 Module Làm Gì?

Driver giống như một **người điều khiển công tắc**:
- Cung cấp giá trị cố định cho switches
- Processor có thể đọc giá trị này thông qua memory-mapped I/O

**Ví dụ đơn giản**:
- Driver set `i_io_sw = 0x12345678`
- Processor đọc từ địa chỉ 0x1001_0000 (SW region) → nhận được `0x12345678`

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module driver (
  input  logic        i_clk  ,      // Xung nhịp (không dùng trong code này)
  input  logic        i_reset,      // Reset signal (không dùng trong code này)
  output logic [31:0] i_io_sw        // Switches output (32 bits)
);
```

**Giải thích**:
- `i_clk`, `i_reset`: Clock và reset (không dùng trong code này, nhưng có thể dùng trong tương lai)
- `i_io_sw`: Output 32 bits - giá trị cho switches

### 2. Khởi Tạo Giá Trị

```systemverilog
initial begin
  i_io_sw = 32'h12345678;
end
```

**Giải thích**:
- `initial begin`: Chạy một lần khi simulation bắt đầu
- `i_io_sw = 32'h12345678`: Set giá trị cố định `0x12345678` cho switches

**Ví dụ**:
- Processor đọc từ địa chỉ `0x1001_0000` (SW region)
- → Nhận được giá trị `0x12345678`

## 🎬 Ví Dụ Thực Tế

### Ví Dụ: Processor Đọc Switches

**Lệnh**: `LW x1, 0x10010000(x0)` (Đọc từ địa chỉ 0x1001_0000 vào x1)

**Driver cung cấp**:
- `i_io_sw = 0x12345678`

**Processor**:
- Đọc từ địa chỉ 0x1001_0000 (SW region)
- → `x1 = 0x12345678` ✅

## 🔍 Điểm Quan Trọng

### 1. Đơn Giản

- Module rất đơn giản, chỉ set giá trị cố định
- Có thể mở rộng để thay đổi giá trị theo thời gian (nếu cần)

### 2. Memory-Mapped I/O

- Switches được map vào địa chỉ `0x1001_0000 - 0x1001_0FFF`
- Processor đọc như đọc memory thông thường

### 3. Có Thể Mở Rộng

- Có thể thêm logic để thay đổi giá trị theo thời gian
- Có thể thêm logic để phản ứng với clock/reset

## 🎓 Kết Luận

Driver là module đơn giản, cung cấp giá trị cố định cho switches. Module này có thể được mở rộng để phức tạp hơn nếu cần.




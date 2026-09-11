# Giải Thích Code - Pipeline Processor

## 📚 Mục Lục

Tài liệu này giải thích chi tiết từng file `.sv` trong project Pipeline Processor (Model 1 và Model 2).

## 📁 Cấu Trúc Thư Mục

```
explanation/
├── README.md              # File này
├── alu.md                 # Giải thích ALU module
├── control_unit.md        # Giải thích Control Unit module
├── register_file.md       # Giải thích Register File module
├── imem_sync.md          # Giải thích Instruction Memory module
├── dmem_sync.md          # Giải thích Data Memory module
├── pipelined.md          # Giải thích Pipeline Processor (file chính)
├── scoreboard.md         # Giải thích Scoreboard module
├── driver.md             # Giải thích Driver module
└── tbench.md             # Giải thích Testbench module
```

## 🎯 Các Module Chính

### 1. Source Files (00_src/)

#### `alu.sv` - Arithmetic Logic Unit
- **Chức năng**: Thực hiện các phép toán số học và logic
- **Input**: 2 số (32 bits) và mã lệnh
- **Output**: Kết quả và cờ zero
- **Xem**: [alu.md](alu.md)

#### `control_unit.sv` - Control Unit
- **Chức năng**: Giải mã lệnh và tạo tín hiệu điều khiển
- **Input**: Opcode, funct3, funct7
- **Output**: Các tín hiệu điều khiển (reg_write, mem_write, alu_op...)
- **Xem**: [control_unit.md](control_unit.md)

#### `register_file.sv` - Register File
- **Chức năng**: Lưu trữ 32 thanh ghi (x0-x31)
- **Chức năng**: Đọc/ghi dữ liệu từ/ vào thanh ghi
- **Xem**: [register_file.md](register_file.md)

#### `imem_sync.sv` - Instruction Memory
- **Chức năng**: Lưu trữ các lệnh của chương trình
- **Chức năng**: Đọc lệnh theo địa chỉ (PC)
- **Xem**: [imem_sync.md](imem_sync.md)

#### `dm em_sync.sv` - Data Memory
- **Chức năng**: Lưu trữ dữ liệu của chương trình
- **Chức năng**: Đọc/ghi dữ liệu với nhiều kích thước (byte/halfword/word)
- **Xem**: [dmem_sync.md](dmem_sync.md)

#### `pipelined.sv` - Pipeline Processor (File Chính)
- **Chức năng**: Module top-level, kết nối tất cả các module
- **Chức năng**: Thực hiện 5-stage pipeline (IF, ID, EX, MEM, WB)
- **Chức năng**: Xử lý hazards (data hazards, control hazards)
- **Chức năng**: Branch prediction (Two-bit + BTB)
- **Xem**: [pipelined.md](pipelined.md)

### 2. Testbench Files (01_bench/)

#### `tbench.sv` - Testbench Top-Level
- **Chức năng**: Module top-level của testbench
- **Chức năng**: Tạo clock/reset, kết nối các module
- **Xem**: [tbench.md](tbench.md)

#### `scoreboard.sv` - Scoreboard
- **Chức năng**: Theo dõi và thống kê performance
- **Chức năng**: Đếm cycles, instructions, branches, mispredictions
- **Chức năng**: Tính IPC và misprediction rate
- **Xem**: [scoreboard.md](scoreboard.md)

#### `driver.sv` - Driver
- **Chức năng**: Cung cấp input cho processor
- **Chức năng**: Set giá trị cho switches
- **Xem**: [driver.md](driver.md)

## 🔄 Luồng Dữ Liệu

```
┌─────────────┐
│   IMEM      │───Lệnh───┐
└─────────────┘           │
                          ▼
                    ┌──────────┐
                    │   IF     │───Lấy lệnh
                    └──────────┘
                          │
                          ▼
                    ┌──────────┐
                    │   ID     │───Giải mã lệnh
                    │          │───Đọc thanh ghi
                    └──────────┘
                          │
                          ▼
                    ┌──────────┐
                    │   EX     │───ALU tính toán
                    └──────────┘
                          │
                          ▼
                    ┌──────────┐
                    │   MEM    │───Đọc/ghi bộ nhớ
                    └──────────┘
                          │
                          ▼
                    ┌──────────┐
                    │   WB     │───Ghi vào thanh ghi
                    └──────────┘
```

## 📖 Cách Đọc Tài Liệu

1. **Bắt đầu với**: [README.md](README.md) (file này)
2. **Đọc các module cơ bản**:
   - [alu.md](alu.md) - Bộ tính toán
   - [control_unit.md](control_unit.md) - Bộ điều khiển
   - [register_file.md](register_file.md) - Thanh ghi
3. **Đọc các module memory**:
   - [imem_sync.md](imem_sync.md) - Bộ nhớ lệnh
   - [dmem_sync.md](dmem_sync.md) - Bộ nhớ dữ liệu
4. **Đọc module chính**:
   - [pipelined.md](pipelined.md) - Pipeline processor
5. **Đọc testbench**:
   - [tbench.md](tbench.md) - Testbench
   - [scoreboard.md](scoreboard.md) - Scoreboard
   - [driver.md](driver.md) - Driver

## 🎓 Kiến Thức Cần Thiết

- **SystemVerilog**: Ngôn ngữ mô tả hardware
- **Pipeline**: Kỹ thuật xử lý song song
- **RISC-V**: Kiến trúc instruction set
- **Hazards**: Data hazards, control hazards
- **Branch Prediction**: Dự đoán nhánh

## 📝 Lưu Ý

- Tất cả các file giải thích đều bằng tiếng Việt, dễ hiểu
- Mỗi file có ví dụ cụ thể
- Code comments bằng tiếng Anh (theo convention)
- Giải thích từ cơ bản đến nâng cao

## 🔗 Liên Kết

- [Tài liệu tổng quan](../GIAI_THICH_TUNG_MODEL.md) - So sánh Model 1 và Model 2
- [Tài liệu chi tiết](../GIAI_THICH_CODE_CHI_TIET.md) - Giải thích tổng quan




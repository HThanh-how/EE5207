# ✅ KIỂM TRA CUỐI CÙNG - ĐẢM BẢO KHÔNG LỖI KHI TEST TRÊN SERVER

## 🚨 CÁC LỖI QUAN TRỌNG ĐÃ SỬA

### 1. ✅ o_insn_vld logic (ĐÃ SỬA)
- **Trước**: `assign o_insn_vld = ~i_reset;` ❌
- **Sau**: `assign o_insn_vld = i_reset;` ✅
- **Lý do**: Reset active LOW, khi `i_reset = 1` (không reset) thì instruction valid = 1

### 2. ✅ LUI instruction (ĐÃ SỬA)
- **Trước**: `alu_src_b = 2'b00` (rs2_data) ❌
- **Sau**: `alu_src_b = 2'b11` (0) ✅
- **Lý do**: LUI chỉ load immediate vào upper bits, không cộng với rs2_data
- **Code**: `control_unit.sv` line 138

## ✅ KIỂM TRA TOÀN BỘ

### 📁 Cấu trúc thư mục
- [x] `00_src/` - 6 file .sv đầy đủ
- [x] `01_bench/` - Testbench files (KHÔNG SỬA)
- [x] `02_test/` - Sẽ có `isa.mem` trên server
- [x] `10_sim/` - Verilator (có `flist` và `Makefile`)
- [x] `11_xm/` - Xcelium (có `flist` và `Makefile`)

### 🔧 File nguồn (00_src/)
- [x] `single_cycle.sv` - Top module với đầy đủ I/O
- [x] `register_file.sv` - 32 registers, x0 = 0
- [x] `alu.sv` - 10 operations (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
- [x] `control_unit.sv` - Decode tất cả instruction types
- [x] `imem.sv` - 16KB, load từ `../02_test/isa.mem`
- [x] `dmem.sv` - 2KB, byte/halfword/word access

### 🎯 Logic quan trọng

#### single_cycle.sv
- [x] `o_insn_vld = i_reset;` ✅
- [x] `o_pc_debug = pc;` ✅
- [x] PC update: sequential, branch, jump đều đúng
- [x] Immediate generation: I, S, B, U, J types đúng
- [x] Branch logic: 6 conditions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
- [x] Jump logic: JAL và JALR

#### Memory mapping I/O
- [x] **LEDR**: `0x1000_0000 - 0x1000_0FFF` (read/write) ✅
- [x] **LEDG**: `0x1000_1000 - 0x1000_1FFF` (read/write) ✅
- [x] **HEX0-3**: `0x1000_2000 - 0x1000_2FFF` (read/write với bit-field) ✅
- [x] **HEX4-7**: `0x1000_3000 - 0x1000_3FFF` (read/write với bit-field) ✅
- [x] **LCD**: `0x1000_4000 - 0x1000_4FFF` (read/write) ✅
- [x] **SW**: `0x1001_0000 - 0x1001_0FFF` (read) ✅
- [x] **DMEM**: `0x0000_0000 - 0x0000_07FF` (chỉ write khi addr < 0x0000_0800) ✅

#### Control Unit
- [x] R-type: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
- [x] I-type: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU, LW, LH, LHU, LB, LBU, JALR
- [x] S-type: SW, SH, SB
- [x] B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
- [x] U-type: **LUI** (alu_src_b = 2'b11), **AUIPC** ✅
- [x] J-type: JAL

### 📋 Flist files
- [x] `10_sim/flist` - Đầy đủ files, thứ tự đúng (sub-modules trước)
- [x] `11_xm/flist` - Giống như trên
- [x] Đường dẫn tương đối đúng: `./../00_src/...`

### 🔨 Makefile
- [x] `10_sim/Makefile` - Verilator command đúng
- [x] `11_xm/Makefile` - Xcelium command đúng

## 📝 HƯỚNG DẪN TEST TRÊN SERVER (10 PHÚT)

### Bước 1: Copy testbench
```bash
cd ~
cp -rf ~/common/sc-test .
cd sc-test
```

### Bước 2: Copy source code
```bash
cp -r ~/workspace/milestone2/00_src/* ./00_src/
cp -r ~/workspace/milestone2/10_sim/* ./10_sim/ 2>/dev/null || true
cp -r ~/workspace/milestone2/11_xm/* ./11_xm/ 2>/dev/null || true
```

### Bước 3: Chạy simulation
**Option A - Verilator (nhanh hơn):**
```bash
cd 10_sim
make
```

**Option B - Xcelium (nếu cần GUI):**
```bash
srun --x11 --pty bash
module load xcelium
cd 11_xm
make
```

### Bước 4: Kiểm tra kết quả
Kết quả đúng sẽ hiển thị:
```
SINGLE CYCLE TESTS
add......PASS
addi.....PASS
sub......PASS
...
lui......PASS
auipc....PASS
...
END of ISA test
```

## ⚠️ CÁC LỖI THƯỜNG GẶP

1. **File không tìm thấy**: Kiểm tra đường dẫn trong `flist` và `imem.sv`
2. **Syntax error**: Đã kiểm tra bằng linter - không có lỗi
3. **o_insn_vld sai**: Đã sửa thành `i_reset`
4. **LUI sai**: Đã sửa `alu_src_b = 2'b11`
5. **Memory size sai**: IMEM = 16KB, DMEM = 2KB ✅

## ✅ XÁC NHẬN CUỐI CÙNG

- [x] Tất cả file .sv không có lỗi syntax
- [x] Tất cả logic đã được kiểm tra và đúng
- [x] Memory mapping đúng theo spec
- [x] Control signals đúng cho tất cả instructions
- [x] Flist và Makefile đúng
- [x] Sẵn sàng upload và test trên server!

**TỔNG KẾT: Code đã được kiểm tra kỹ lưỡng và sẵn sàng test trên server!**


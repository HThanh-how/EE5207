# ✅ CHECKLIST TRƯỚC KHI TEST TRÊN SERVER (10 PHÚT)

## 🚨 QUAN TRỌNG: Kiểm tra từng mục này TRƯỚC khi upload lên server

### 1. ✅ CẤU TRÚC THỨ MỤC
- [x] Folder `milestone2` hoặc tên project đúng
- [x] `00_src/` - chứa tất cả file .sv
- [x] `01_bench/` - testbench files (KHÔNG SỬA)
- [x] `02_test/` - folder để chứa `isa.mem` (file này sẽ có trên server)
- [x] `10_sim/` - Verilator simulation (có `flist` và `Makefile`)
- [x] `11_xm/` - Xcelium simulation (có `flist` và `Makefile`)

### 2. ✅ FILE NGUỒN (00_src/)
- [x] `single_cycle.sv` - Top-level module
- [x] `register_file.sv` - Register file 32x32
- [x] `alu.sv` - ALU operations
- [x] `control_unit.sv` - Control unit
- [x] `imem.sv` - Instruction memory (16KB)
- [x] `dmem.sv` - Data memory (2KB)

### 3. ✅ LOGIC QUAN TRỌNG TRONG single_cycle.sv
- [x] `o_insn_vld = i_reset;` (NOT ~i_reset!)
- [x] `o_pc_debug = pc;`
- [x] Memory mapping I/O:
  - LEDR: `0x1000_0000 - 0x1000_0FFF`
  - LEDG: `0x1000_1000 - 0x1000_1FFF`
  - HEX0-3: `0x1000_2000 - 0x1000_2FFF`
  - HEX4-7: `0x1000_3000 - 0x1000_3FFF`
  - LCD: `0x1000_4000 - 0x1000_4FFF`
  - SW: `0x1001_0000 - 0x1001_0FFF`
- [x] DMEM: `0x0000_0000 - 0x0000_07FF` (chỉ write khi addr < 0x0000_0800)
- [x] I/O read: LEDR, LEDG, HEX, LCD, SW đều có logic read

### 4. ✅ IMEM.SV
- [x] `MEM_SIZE = 16384;` (16KB, không phải 8192)
- [x] `$readmemh("../02_test/isa.mem", mem);` (đúng đường dẫn tương đối)
- [x] Byte addressing đúng (little-endian)

### 5. ✅ FLIST FILES
**10_sim/flist:**
- [x] Có đầy đủ file nguồn từ `00_src/`
- [x] Có đầy đủ testbench từ `01_bench/`
- [x] Thứ tự: sub-modules trước, top module sau
- [x] Đường dẫn tương đối đúng: `./../00_src/...`

**11_xm/flist:**
- [x] Giống như trên

### 6. ✅ MAKEFILE
**10_sim/Makefile:**
- [x] Verilator command đúng: `verilator --cc --exe --build --top-module tbench -f ./flist`
- [x] Run command: `./obj_dir/Vtbench`

**11_xm/Makefile:**
- [x] Xcelium command đúng: `xrun -64bit -access +rwc -f ./flist`

### 7. ✅ KIỂM TRA TRƯỚC KHI UPLOAD
- [x] Tất cả file .sv không có lỗi syntax
- [x] Không có lỗi typo trong tên biến
- [x] Tất cả signals được khai báo
- [x] Clock và reset logic đúng
- [x] Memory addresses đúng (không có overlap)

### 8. ✅ SAU KHI UPLOAD LÊN SERVER
1. **Copy testbench từ common:**
   ```bash
   cd ~
   cp -rf ~/common/sc-test .
   cd sc-test
   ```

2. **Copy source code của bạn:**
   ```bash
   cp -r ~/workspace/milestone2/00_src/* ./00_src/
   ```

3. **Chạy simulation (chọn 1 trong 2):**
   
   **Option A - Verilator:**
   ```bash
   cd 10_sim
   make
   ```
   
   **Option B - Xcelium:**
   ```bash
   srun --x11 --pty bash
   module load xcelium
   cd 11_xm
   make
   ```

### 9. ✅ CÁC LỖI THƯỜNG GẶP
- ❌ **Lỗi file không tìm thấy**: Kiểm tra đường dẫn trong `flist` và `imem.sv`
- ❌ **Lỗi syntax**: Kiểm tra lại bằng `read_lints` hoặc compile local trước
- ❌ **Lỗi memory**: Kiểm tra `MEM_SIZE` và địa chỉ memory mapping
- ❌ **Lỗi o_insn_vld**: Phải là `i_reset`, không phải `~i_reset`
- ❌ **Lỗi top module**: Đảm bảo tên module trong code khớp với testbench

### 10. ✅ VERIFICATION
Sau khi chạy simulation, kết quả đúng sẽ hiển thị:
```
SINGLE CYCLE TESTS
add......PASS
addi.....PASS
sub......PASS
...
END of ISA test
```

Nếu có ERROR hoặc không hiển thị PASS → kiểm tra lại code!





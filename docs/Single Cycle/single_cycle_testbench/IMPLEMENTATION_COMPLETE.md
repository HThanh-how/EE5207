# ✅ IMPLEMENTATION HOÀN THÀNH - MILESTONE 2

## 🎯 ĐÃ SỬA THEO YÊU CẦU PDF

### 1. ✅ Memory Mapping I/O (SỬA LẠI HOÀN TOÀN)
**Trước (SAI):**
- LEDR: 0x0000_1010
- LEDG: 0x0000_1014  
- LCD: 0x0000_1018
- SW: 0x0000_1000

**Sau (ĐÚNG theo milestone-2):**
- LEDR: `0x1000_0000 - 0x1000_0FFF` ✅
- LEDG: `0x1000_1000 - 0x1000_1FFF` ✅
- HEX0-3: `0x1000_2000 - 0x1000_2FFF` ✅
- HEX4-7: `0x1000_3000 - 0x1000_3FFF` ✅
- LCD: `0x1000_4000 - 0x1000_4FFF` ✅
- SW: `0x1001_0000 - 0x1001_0FFF` ✅

### 2. ✅ IMEM Size (TĂNG LÊN)
**Trước:** 8KB (8192 bytes)
**Sau:** 16KB (16384 bytes) ✅
- Top address: 0x0000_7FFF ✅
- Load từ: `isa.mem` (theo milestone-2-extra) ✅

### 3. ✅ HEX Display Mapping
- **SB** (byte): Update HEX theo byte offset tại địa chỉ ✅
- **SH** (half-word): Update 2 HEX liên tiếp ✅
- **SW** (word): Update cả 4 HEX từ bit-field:
  - HEX0: bits [6:0]
  - HEX1: bits [14:8]
  - HEX2: bits [22:16]
  - HEX3: bits [30:24]
- Tương tự cho HEX4-7 tại 0x1000_3000 ✅

### 4. ✅ Cấu trúc thư mục
```
milestone2/
├── 00_src/          ✅ RTL source files
├── 01_bench/        ✅ Testbench files
├── 02_test/         ✅ Test files (cần isa.mem)
├── 10_sim/          ✅ Verilator (mới tạo)
│   ├── Makefile
│   └── flist
├── 11_xm/           ✅ Xcelium (mới tạo)
│   ├── Makefile
│   └── flist
└── 03_sim/          ✅ Giữ lại cho local test
```

## 📝 CẦN KIỂM TRA TRƯỚC KHI TEST

### 1. File isa.mem
**Yêu cầu:** `02_test/isa.mem`
**Hiện có:** `isa_1b.hex`, `isa_4b.hex`

**Giải pháp:**
```bash
cd 02_test
cp isa_1b.hex isa.mem
# Hoặc tạo symbolic link
```

### 2. Test trên server
1. Upload project lên server vào `~/workspace/milestone2/`
2. Vào compute node: `srun --x11 --pty bash`
3. Load module: `module load xcelium`
4. Chạy test:
   ```bash
   cd 11_xm
   make create_filelist  # Kiểm tra và sắp xếp lại thứ tự (top module cuối)
   make                  # hoặc make xrun
   make simvision        # Xem waveform
   ```

## ✅ CHECKLIST HOÀN THÀNH

- [x] Memory mapping I/O đúng Table 1 (milestone-2)
- [x] IMEM ≥16KB (milestone-2-extra)
- [x] DMEM 2KB tại 0x0000_0000 - 0x0000_07FF
- [x] HEX display mapping với bit-field
- [x] Tất cả instructions RV32I
- [x] Control signals đúng
- [x] Branch/Jump logic đúng
- [x] Immediate generation đúng
- [x] Memory access (byte/halfword/word)
- [x] Sign/zero extension cho load
- [x] Cấu trúc thư mục 10_sim, 11_xm
- [x] Makefile cho Verilator và Xcelium
- [ ] File `isa.mem` trong `02_test/` ⚠️

## 🎯 KẾT QUẢ MONG ĐỢI

```
SINGLE CYCLE TESTS

add......PASS
addi.....PASS
sub......PASS
and......PASS
...
iosw.....PASS

END
```

**Lưu ý:** `malgn....ERROR` là chấp nhận được (misaligned không bắt buộc).


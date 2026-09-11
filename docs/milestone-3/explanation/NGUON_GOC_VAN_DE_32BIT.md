# 🔍 Nguồn Gốc Vấn Đề: Đọc 32-bit Hex Từ File

## 📋 Tóm Tắt Vấn Đề

**Vấn đề**: Code không chạy đúng khi đọc file `isa_4b.hex` (mỗi dòng là 32-bit instruction word).

**Nguyên nhân**: Cách đọc 32-bit hex từ file không xử lý đúng các giá trị có bit 31 = 1 (giá trị >= 0x8000_0000).

---

## 🎯 Chi Tiết Vấn Đề

### 1. Code Cũ (Có Vấn Đề)

```systemverilog
initial begin
    integer fd;
    integer code;
    logic [31:0] word;  // ❌ Vấn đề ở đây
    integer addr_idx;
    string  line_buf;
    
    // ...
    while (!$feof(fd) && (addr_idx + 3) < MEM_SIZE) begin
        code = $fscanf(fd, "%h\n", word);  // ❌ Đọc trực tiếp vào logic[31:0]
        if (code == 1) begin
            mem[addr_idx+0] = word[7:0];
            mem[addr_idx+1] = word[15:8];
            mem[addr_idx+2] = word[23:16];
            mem[addr_idx+3] = word[31:24];
            addr_idx = addr_idx + 4;
        end
    end
end
```

### 2. Vấn Đề Cụ Thể

#### Vấn Đề 1: `$fscanf` với `logic [31:0]`

- `$fscanf` trong SystemVerilog được thiết kế để đọc vào các kiểu dữ liệu **integer** (signed/unsigned integer, real, string)
- Khi đọc trực tiếp vào `logic [31:0]`, một số simulator có thể:
  - Không đọc đúng 32-bit
  - Xử lý sai format
  - Gây lỗi compilation hoặc runtime

#### Vấn Đề 2: Signed vs Unsigned

Nếu code cũ dùng `int word;` (signed integer):

```systemverilog
int word;  // ❌ Signed 32-bit integer
code = $fscanf(fd, "%h\n", word);
```

**Ví dụ minh họa**:
```
File isa_4b.hex có dòng: 0CC0006F
→ Giá trị hex: 0x0CC0006F = 214,958,191 (decimal)

Nhưng nếu bit 31 = 1 (ví dụ: 0x80000000):
→ Với signed int: -2,147,483,648 (số âm!)
→ Với unsigned: 2,147,483,648 (số dương)
```

**Tại sao quan trọng?**
- RISC-V instructions là **unsigned 32-bit**
- Nhiều instruction có bit 31 = 1 (ví dụ: các lệnh jump với offset âm)
- Nếu xử lý như signed, giá trị sẽ sai → instruction sai → processor chạy sai!

---

## ✅ Giải Pháp

### Code Mới (Đã Sửa)

```systemverilog
initial begin
    integer fd;
    integer code;
    integer word_int;  // ✅ Đọc vào integer trước
    logic [31:0] word; // ✅ Sau đó cast sang unsigned
    integer addr_idx;
    string  line_buf;
    
    // ...
    while (!$feof(fd) && (addr_idx + 3) < MEM_SIZE) begin
        code = $fscanf(fd, "%h", word_int);  // ✅ Đọc vào integer
        if (code == 1) begin
            // ✅ Cast sang unsigned 32-bit
            word = word_int[31:0];
            // Little-endian: byte 0 is least-significant
            mem[addr_idx+0] = word[7:0];
            mem[addr_idx+1] = word[15:8];
            mem[addr_idx+2] = word[23:16];
            mem[addr_idx+3] = word[31:24];
            addr_idx = addr_idx + 4;
        end
    end
end
```

### Tại Sao Giải Pháp Này Hoạt Động?

#### Bước 1: Đọc Vào `integer`
```systemverilog
integer word_int;  // Signed 32-bit integer
code = $fscanf(fd, "%h", word_int);
```
- `$fscanf` hoạt động tốt với `integer` type
- Đọc đúng 32-bit hex từ file
- Lưu trữ như signed integer (tạm thời)

#### Bước 2: Cast Sang Unsigned
```systemverilog
word = word_int[31:0];  // Lấy 32 bits thấp, xử lý như unsigned
```
- `word_int[31:0]` lấy **32 bits thấp** của integer
- Gán vào `logic [31:0] word` → được xử lý như **unsigned**
- **Quan trọng**: Dù `word_int` là signed, khi lấy `[31:0]`, ta chỉ quan tâm đến **pattern của bits**, không quan tâm đến sign!

**Ví dụ minh họa**:
```
File: 0x80000000

Bước 1: word_int = 0x80000000 (signed: -2,147,483,648)
Bước 2: word = word_int[31:0] = 0x80000000 (unsigned: 2,147,483,648) ✅
```

---

## 🔬 Ví Dụ Cụ Thể

### Ví Dụ 1: Instruction Bình Thường

**File `isa_4b.hex`**:
```
00007137
```

**Quá trình xử lý**:
1. `$fscanf` đọc: `word_int = 0x00007137` (signed: 28,983)
2. Cast: `word = word_int[31:0] = 0x00007137` (unsigned: 28,983) ✅
3. Unpack bytes:
   - `mem[0] = 0x37`
   - `mem[1] = 0x71`
   - `mem[2] = 0x00`
   - `mem[3] = 0x00`

### Ví Dụ 2: Instruction Có Bit 31 = 1

**File `isa_4b.hex`**:
```
80000000
```

**Code cũ (SAI)**:
```systemverilog
int word;  // Signed
code = $fscanf(fd, "%h\n", word);
// word = -2,147,483,648 (số âm!)
// Khi unpack: mem[3] = word[31:24] = 0x80 ✅ (may mắn vẫn đúng pattern)
```

**Code mới (ĐÚNG)**:
```systemverilog
integer word_int;
code = $fscanf(fd, "%h", word_int);
word = word_int[31:0];  // word = 0x80000000 (unsigned: 2,147,483,648) ✅
// Unpack: mem[3] = 0x80 ✅
```

### Ví Dụ 3: Jump Instruction với Offset Âm

**File `isa_4b.hex`**:
```
FFDFF06F  // JAL instruction với offset âm
```

**Quá trình xử lý**:
1. `$fscanf` đọc: `word_int = 0xFFDFF06F`
   - Nếu xử lý như signed: có thể gây confusion
2. Cast: `word = word_int[31:0] = 0xFFDFF06F` (unsigned) ✅
3. Unpack bytes:
   - `mem[0] = 0x6F`
   - `mem[1] = 0xF0`
   - `mem[2] = 0xDF`
   - `mem[3] = 0xFF`

---

## 📊 So Sánh Code Cũ vs Code Mới

| Khía Cạnh | Code Cũ | Code Mới |
|-----------|---------|----------|
| **Kiểu dữ liệu** | `logic [31:0] word` hoặc `int word` | `integer word_int` + `logic [31:0] word` |
| **Đọc file** | `$fscanf(fd, "%h\n", word)` | `$fscanf(fd, "%h", word_int)` |
| **Xử lý** | Trực tiếp | Cast: `word = word_int[31:0]` |
| **Vấn đề** | ❌ Có thể không đọc đúng 32-bit<br>❌ Signed/unsigned confusion | ✅ Đọc đúng 32-bit<br>✅ Xử lý như unsigned |
| **Tương thích** | ❌ Một số simulator không hỗ trợ | ✅ Tương thích tốt với mọi simulator |

---

## 🎓 Bài Học Rút Ra

1. **`$fscanf` hoạt động tốt với integer types**: Nên đọc vào `integer` trước, sau đó cast sang kiểu mong muốn.

2. **Signed vs Unsigned rất quan trọng**: 
   - RISC-V instructions là **unsigned 32-bit**
   - Cần đảm bảo xử lý đúng như unsigned

3. **Bit slicing là cách an toàn**: 
   - `word_int[31:0]` lấy pattern của bits, không quan tâm đến sign
   - Đảm bảo giá trị được xử lý đúng như unsigned

4. **Test với edge cases**: 
   - Test với giá trị có bit 31 = 1
   - Test với giá trị lớn (0x80000000 - 0xFFFFFFFF)

---

## 🔗 Liên Kết

- File code: `docs/milestone-3/pl-test-model-1/00_src/imem_sync.sv`
- File code: `docs/milestone-3/pl-test-model-2/00_src/imem_sync.sv`
- Giải thích imem_sync: `docs/milestone-3/explanation/imem_sync.md`

---

## 📝 Tóm Tắt

**Vấn đề**: Đọc 32-bit hex từ file không xử lý đúng các giá trị có bit 31 = 1.

**Nguyên nhân**: 
- `$fscanf` với `logic [31:0]` có thể không hoạt động đúng
- Signed/unsigned confusion khi dùng `int`

**Giải pháp**: 
- Đọc vào `integer` trước
- Cast sang `logic [31:0]` bằng `word_int[31:0]` để xử lý như unsigned

**Kết quả**: Code chạy đúng với mọi giá trị 32-bit, kể cả các instruction có bit 31 = 1.




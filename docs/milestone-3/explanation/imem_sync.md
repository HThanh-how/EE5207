# Giải Thích File: imem_sync.sv

## 📋 Tổng Quan

File `imem_sync.sv` chứa module **Instruction Memory (IMEM)** - đây là "thư viện lệnh" của processor. IMEM lưu trữ các lệnh của chương trình và cho phép đọc lệnh theo địa chỉ.

## 🎯 Module Làm Gì?

IMEM giống như một **cuốn sách lệnh**:
- Mỗi trang là một lệnh (32 bits)
- Địa chỉ (PC) là số trang
- Processor đọc lệnh từ trang đó

**Ví dụ đơn giản**:
- PC = 0 → Đọc lệnh ở trang 0
- PC = 4 → Đọc lệnh ở trang 4 (mỗi lệnh 4 bytes)

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module imem_sync (
    input  logic         clk,        // Xung nhịp
    input  logic         enable,      // Cho phép đọc
    input  logic [31:0]  addr,       // Địa chỉ lệnh (PC)
    output logic [31:0]  rdata        // Lệnh đọc được (32 bits)
);
```

**Giải thích**:
- `clk`: Xung nhịp (cần cho synchronous read)
- `enable`: Chỉ đọc khi `enable = 1`
- `addr`: Địa chỉ lệnh (Program Counter - PC)
- `rdata`: Lệnh 32 bits đọc được

### 2. Tham Số và Khai Báo

```systemverilog
parameter MEM_SIZE = 65536;  // 64 KiB
parameter ADDR_WIDTH = $clog2(MEM_SIZE);

logic [7:0] mem [0:MEM_SIZE-1];  // Bộ nhớ byte-addressable
logic [ADDR_WIDTH-1:0] byte_addr;
```

**Giải thích**:
- `MEM_SIZE = 65536`: Kích thước bộ nhớ = 64 KiB (65536 bytes)
- `ADDR_WIDTH = $clog2(65536) = 16`: Cần 16 bits để địa chỉ 65536 bytes
- `mem [0:MEM_SIZE-1]`: Mảng lưu trữ bytes (mỗi phần tử 8 bits)
- `byte_addr`: Địa chỉ byte (chỉ lấy 16 bits thấp của `addr`)

**Ví dụ**:
- `addr = 0x0000_0004` → `byte_addr = 0x0004` (chỉ lấy 16 bits thấp)

### 3. Khởi Tạo Bộ Nhớ (Load Program)

```systemverilog
initial begin
    integer fd;
    integer code;
    int     word;
    int     addr_idx;
    string  line_buf;
    
    // 1) Thử load isa.mem (byte-per-line)
    fd = $fopen("../02_test/isa.mem", "r");
    if (fd) begin
        $display("[IMEM_SYNC] Loading ../02_test/isa.mem");
        $fclose(fd);
        $readmemh("../02_test/isa.mem", mem);
    end else begin
        // 2) Thử load isa_1b.hex (byte format)
        fd = $fopen("../02_test/isa_1b.hex", "r");
        if (fd) begin
            $display("[IMEM_SYNC] Loading ../02_test/isa_1b.hex");
            $fclose(fd);
            $readmemh("../02_test/isa_1b.hex", mem);
        end else begin
            // 3) Load isa_4b.hex (word format - 32 bits/line)
            fd = $fopen("../02_test/isa_4b.hex", "r");
            if (fd) begin
                $display("[IMEM_SYNC] Loading ../02_test/isa_4b.hex");
                addr_idx = 0;
                while (!$feof(fd) && (addr_idx + 3) < MEM_SIZE) begin
                    code = $fscanf(fd, "%h\n", word);
                    if (code == 1) begin
                        // Little-endian: byte 0 là least-significant
                        mem[addr_idx+0] = word[7:0];
                        mem[addr_idx+1] = word[15:8];
                        mem[addr_idx+2] = word[23:16];
                        mem[addr_idx+3] = word[31:24];
                        addr_idx += 4;
                    end else begin
                        void'($fgets(line_buf, fd));  // Skip malformed line
                    end
                end
                $fclose(fd);
            end else begin
                $display("[IMEM_SYNC] ERROR: No file found");
            end
        end
    end
end
```

**Giải thích từng bước**:

#### Bước 1: Thử Load `isa.mem`
- Format: Mỗi dòng là 1 byte (hex)
- Dùng `$readmemh()` để load trực tiếp vào `mem`

#### Bước 2: Thử Load `isa_1b.hex`
- Format: Mỗi dòng là 1 byte (hex)
- Tương tự `isa.mem`

#### Bước 3: Load `isa_4b.hex` (Word Format)
- Format: Mỗi dòng là 1 word (32 bits = 4 bytes)
- Cần **unpack** từ word sang bytes
- **Little-endian**: Byte thấp nhất ở địa chỉ thấp nhất

**Ví dụ unpack**:
```
Word = 0x12345678
→ mem[addr+0] = 0x78 (byte thấp nhất)
→ mem[addr+1] = 0x56
→ mem[addr+2] = 0x34
→ mem[addr+3] = 0x12 (byte cao nhất)
```

### 4. Tính Địa Chỉ Byte

```systemverilog
assign byte_addr = addr[ADDR_WIDTH-1:0];
```

**Giải thích**:
- Chỉ lấy 16 bits thấp của `addr` (vì bộ nhớ chỉ 64 KiB)
- Bỏ qua các bits cao (nếu `addr > 0xFFFF`)

**Ví dụ**:
- `addr = 0x0000_0004` → `byte_addr = 0x0004`
- `addr = 0x0001_0004` → `byte_addr = 0x0004` (chỉ lấy 16 bits thấp)

### 5. Synchronous Read (Đọc Đồng Bộ)

```systemverilog
always_ff @(posedge clk) begin
    if (enable) begin
        if (byte_addr+3 < MEM_SIZE) begin
            rdata <= {mem[byte_addr+3], mem[byte_addr+2], 
                     mem[byte_addr+1], mem[byte_addr]};
        end else begin
            rdata <= 32'b0;
        end
    end
end
```

**Giải thích từng phần**:

#### `always_ff @(posedge clk)`
- Sequential logic, chỉ thực hiện tại cạnh lên của clock
- **Synchronous read** (BRAM compatible)

#### `if (enable)`
- Chỉ đọc khi `enable = 1`

#### `if (byte_addr+3 < MEM_SIZE)`
- Kiểm tra địa chỉ hợp lệ (không vượt quá bộ nhớ)
- `byte_addr+3` vì cần đọc 4 bytes (1 word = 32 bits)

#### `rdata <= {mem[byte_addr+3], ..., mem[byte_addr]}`
- Đọc 4 bytes và ghép thành 1 word (32 bits)
- **Little-endian**: Byte thấp nhất (`mem[byte_addr]`) ở bits thấp nhất

**Ví dụ**:
```
byte_addr = 0x0004
mem[0x0004] = 0x78
mem[0x0005] = 0x56
mem[0x0006] = 0x34
mem[0x0007] = 0x12

→ rdata = {0x12, 0x34, 0x56, 0x78} = 0x12345678
```

## 🎬 Ví Dụ Thực Tế

### Ví Dụ 1: Đọc Lệnh Đầu Tiên

**PC = 0x0000_0000** (bắt đầu chương trình)

**IMEM nhận**:
- `addr = 0x0000_0000`
- `enable = 1`
- `clk` có cạnh lên

**IMEM tính**:
- `byte_addr = 0x0000` (16 bits thấp)
- Đọc 4 bytes: `mem[0x0000]`, `mem[0x0001]`, `mem[0x0002]`, `mem[0x0003]`

**Giả sử**:
- `mem[0x0000] = 0x78`
- `mem[0x0001] = 0x56`
- `mem[0x0002] = 0x34`
- `mem[0x0003] = 0x12`

**IMEM trả về**:
- `rdata = 0x12345678` (lệnh đầu tiên)

### Ví Dụ 2: Đọc Lệnh Tiếp Theo

**PC = 0x0000_0004** (lệnh tiếp theo)

**IMEM nhận**:
- `addr = 0x0000_0004`
- `enable = 1`

**IMEM tính**:
- `byte_addr = 0x0004`
- Đọc 4 bytes: `mem[0x0004]`, `mem[0x0005]`, `mem[0x0006]`, `mem[0x0007]`

**IMEM trả về**:
- `rdata = lệnh thứ 2`

### Ví Dụ 3: Địa Chỉ Vượt Quá Bộ Nhớ

**PC = 0x0001_0000** (vượt quá 64 KiB)

**IMEM nhận**:
- `addr = 0x0001_0000`
- `enable = 1`

**IMEM tính**:
- `byte_addr = 0x0000` (chỉ lấy 16 bits thấp)
- `byte_addr+3 = 0x0003 < MEM_SIZE` → Hợp lệ

**IMEM trả về**:
- `rdata = lệnh tại địa chỉ 0x0000` (wrap around)

**Lưu ý**: Trong thực tế, địa chỉ vượt quá bộ nhớ sẽ trả về 0 hoặc undefined behavior.

## 🔍 Điểm Quan Trọng

### 1. Synchronous Read (BRAM Compatible)

- Đọc là **sequential** (cần clock)
- Tương thích với BRAM (Block RAM) trong FPGA
- BRAM cho phép tần số cao hơn và sử dụng ít logic elements hơn

### 2. Little-Endian Byte Order

- Byte thấp nhất ở địa chỉ thấp nhất
- Phù hợp với RISC-V specification

**Ví dụ**:
```
Word = 0x12345678
→ mem[addr+0] = 0x78 (LSB - Least Significant Byte)
→ mem[addr+1] = 0x56
→ mem[addr+2] = 0x34
→ mem[addr+3] = 0x12 (MSB - Most Significant Byte)
```

### 3. Multiple File Format Support

Module hỗ trợ 3 format:
1. **isa.mem**: Byte-per-line (mỗi dòng 1 byte)
2. **isa_1b.hex**: Byte-per-line (hex format)
3. **isa_4b.hex**: Word-per-line (mỗi dòng 1 word, cần unpack)

### 4. Address Masking

- Chỉ lấy 16 bits thấp của `addr`
- Bỏ qua các bits cao (nếu `addr > 0xFFFF`)

**Lý do**: Bộ nhớ chỉ 64 KiB, không cần nhiều hơn 16 bits để địa chỉ.

## 📊 Bảng Tóm Tắt

| Tham Số | Giá Trị | Giải Thích |
|---------|---------|------------|
| MEM_SIZE | 65536 | 64 KiB (theo yêu cầu Milestone 3) |
| ADDR_WIDTH | 16 | Cần 16 bits để địa chỉ 65536 bytes |
| Word Size | 32 bits | Mỗi lệnh RISC-V dài 32 bits |
| Byte Order | Little-endian | Byte thấp nhất ở địa chỉ thấp nhất |
| Read Type | Synchronous | Cần clock (BRAM compatible) |

## 🎓 Kết Luận

IMEM là module quan trọng, lưu trữ các lệnh của chương trình và cho phép đọc lệnh theo địa chỉ. Module này:
- Hỗ trợ nhiều file format
- Đọc đồng bộ (BRAM compatible)
- Little-endian byte order
- 64 KiB memory size




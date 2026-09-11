# Giải Thích File: dmem_sync.sv

## 📋 Tổng Quan

File `dmem_sync.sv` chứa module **Data Memory (DMEM)** - đây là "kho dữ liệu" của processor. DMEM lưu trữ dữ liệu của chương trình và cho phép đọc/ghi dữ liệu với nhiều kích thước khác nhau (byte, halfword, word).

## 🎯 Module Làm Gì?

DMEM giống như một **kho hàng**:
- Lưu trữ dữ liệu (số, biến, mảng...)
- Có thể đọc/ghi theo byte (8 bits), halfword (16 bits), hoặc word (32 bits)
- Hỗ trợ cả signed và unsigned operations

**Ví dụ đơn giản**:
- Ghi: "Ghi số 100 vào địa chỉ 0x1000"
- Đọc: "Đọc số từ địa chỉ 0x1000"

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module dmem_sync (
    input  logic         clk,        // Xung nhịp
    input  logic         enable,     // Cho phép đọc/ghi
    input  logic         we,         // Write enable - cho phép ghi
    input  logic [31:0]  addr,       // Địa chỉ dữ liệu
    input  logic [31:0]  wdata,      // Dữ liệu cần ghi
    input  logic [ 2:0]  mem_size,    // Kích thước (byte/halfword/word)
    output logic [31:0]  rdata       // Dữ liệu đọc được
);
```

**Giải thích**:
- `clk`: Xung nhịp (cần cho synchronous read/write)
- `enable`: Chỉ đọc/ghi khi `enable = 1`
- `we`: Write enable - `we = 1` để ghi, `we = 0` để đọc
- `addr`: Địa chỉ dữ liệu (32 bits)
- `wdata`: Dữ liệu 32 bits cần ghi
- `mem_size`: Kích thước (000=byte, 001=halfword, 010=word, 100=LBU, 101=LHU)
- `rdata`: Dữ liệu 32 bits đọc được (luôn 32 bits, dù đọc byte hay halfword)

### 2. Tham Số và Khai Báo

```systemverilog
parameter MEM_SIZE = 65536;  // 64 KiB
parameter ADDR_WIDTH = $clog2(MEM_SIZE);

logic [7:0] mem [0:MEM_SIZE-1];  // Bộ nhớ byte-addressable
logic [ADDR_WIDTH-1:0] byte_addr;

assign byte_addr = addr[ADDR_WIDTH-1:0];
```

**Giải thích**:
- Tương tự IMEM: 64 KiB, byte-addressable
- `byte_addr`: Chỉ lấy 16 bits thấp của `addr`

### 3. Synchronous Write (Ghi Đồng Bộ)

```systemverilog
always_ff @(posedge clk) begin
    if (enable) begin
        if (we && byte_addr < MEM_SIZE) begin
            case (mem_size)
                // SB (Store Byte)
                3'b000: begin
                    mem[byte_addr] <= wdata[7:0];
                end
                // SH (Store Halfword)
                3'b001: begin
                    if (byte_addr+1 < MEM_SIZE) begin
                        mem[byte_addr]     <= wdata[7:0];
                        mem[byte_addr+1]   <= wdata[15:8];
                    end
                end
                // SW (Store Word)
                3'b010: begin
                    if (byte_addr+3 < MEM_SIZE) begin
                        mem[byte_addr]     <= wdata[7:0];
                        mem[byte_addr+1]   <= wdata[15:8];
                        mem[byte_addr+2]   <= wdata[23:16];
                        mem[byte_addr+3]   <= wdata[31:24];
                    end
                end
                default: begin
                    // Default: ghi word
                    if (byte_addr+3 < MEM_SIZE) begin
                        mem[byte_addr]     <= wdata[7:0];
                        mem[byte_addr+1]   <= wdata[15:8];
                        mem[byte_addr+2]   <= wdata[23:16];
                        mem[byte_addr+3]   <= wdata[31:24];
                    end
                end
            endcase
        end
    end
end
```

**Giải thích từng loại ghi**:

#### SB (Store Byte) - `mem_size = 000`
```systemverilog
mem[byte_addr] <= wdata[7:0];
```
- Chỉ ghi 8 bits thấp của `wdata`
- **Ví dụ**: `wdata = 0x12345678` → chỉ ghi `0x78` vào `mem[byte_addr]`

#### SH (Store Halfword) - `mem_size = 001`
```systemverilog
mem[byte_addr]     <= wdata[7:0];   // Byte thấp
mem[byte_addr+1]   <= wdata[15:8];  // Byte cao
```
- Ghi 16 bits thấp của `wdata` (2 bytes)
- **Little-endian**: Byte thấp ở địa chỉ thấp
- **Ví dụ**: `wdata = 0x12345678` → ghi `0x78` vào `mem[addr]`, `0x56` vào `mem[addr+1]`

#### SW (Store Word) - `mem_size = 010`
```systemverilog
mem[byte_addr]     <= wdata[7:0];    // Byte 0 (LSB)
mem[byte_addr+1]   <= wdata[15:8];   // Byte 1
mem[byte_addr+2]   <= wdata[23:16];  // Byte 2
mem[byte_addr+3]   <= wdata[31:24];  // Byte 3 (MSB)
```
- Ghi toàn bộ 32 bits của `wdata` (4 bytes)
- **Little-endian**: Byte thấp nhất ở địa chỉ thấp nhất
- **Ví dụ**: `wdata = 0x12345678` → ghi `0x78, 0x56, 0x34, 0x12` vào `mem[addr...addr+3]`

### 4. Synchronous Read (Đọc Đồng Bộ)

```systemverilog
always_ff @(posedge clk) begin
    if (enable) begin
        if (byte_addr >= MEM_SIZE) begin
            rdata <= 32'b0;
        end else begin
            case (mem_size)
                // LB (Load Byte - sign-extend)
                3'b000: rdata <= {{24{mem[byte_addr][7]}}, mem[byte_addr]};
                
                // LH (Load Halfword - sign-extend)
                3'b001: rdata <= (byte_addr+1 < MEM_SIZE)
                                  ? {{16{mem[byte_addr+1][7]}}, mem[byte_addr+1], mem[byte_addr]}
                                  : {{16{mem[byte_addr][7]}}, mem[byte_addr], 16'b0};
                
                // LW (Load Word)
                3'b010: rdata <= (byte_addr+3 < MEM_SIZE)
                                  ? {mem[byte_addr+3], mem[byte_addr+2], 
                                     mem[byte_addr+1], mem[byte_addr]}
                                  : 32'b0;
                
                // LBU (Load Byte Unsigned - zero-extend)
                3'b100: rdata <= {24'b0, mem[byte_addr]};
                
                // LHU (Load Halfword Unsigned - zero-extend)
                3'b101: rdata <= (byte_addr+1 < MEM_SIZE)
                                  ? {16'b0, mem[byte_addr+1], mem[byte_addr]}
                                  : {16'b0, mem[byte_addr], 16'b0};
                
                default: rdata <= (byte_addr+3 < MEM_SIZE)
                                  ? {mem[byte_addr+3], mem[byte_addr+2], 
                                     mem[byte_addr+1], mem[byte_addr]}
                                  : 32'b0;
            endcase
        end
    end
end
```

**Giải thích từng loại đọc**:

#### LB (Load Byte - Signed) - `mem_size = 000`
```systemverilog
rdata <= {{24{mem[byte_addr][7]}}, mem[byte_addr]};
```
- Đọc 1 byte và **sign-extend** (mở rộng bit dấu)
- `{24{mem[byte_addr][7]}}`: Lặp lại bit 7 (bit dấu) 24 lần
- **Ví dụ**: 
  - `mem[addr] = 0x78` (bit 7 = 0) → `rdata = 0x00000078`
  - `mem[addr] = 0xF8` (bit 7 = 1, số âm) → `rdata = 0xFFFFFFF8` (sign-extend)

#### LH (Load Halfword - Signed) - `mem_size = 001`
```systemverilog
rdata <= {{16{mem[byte_addr+1][7]}}, mem[byte_addr+1], mem[byte_addr]};
```
- Đọc 2 bytes và **sign-extend**
- **Little-endian**: Byte thấp ở `mem[byte_addr]`, byte cao ở `mem[byte_addr+1]`
- **Ví dụ**: 
  - `mem[addr] = 0x78`, `mem[addr+1] = 0x56` → `rdata = 0x00005678`
  - `mem[addr] = 0x78`, `mem[addr+1] = 0xF6` (bit 7 = 1) → `rdata = 0xFFFFF678` (sign-extend)

#### LW (Load Word) - `mem_size = 010`
```systemverilog
rdata <= {mem[byte_addr+3], mem[byte_addr+2], 
         mem[byte_addr+1], mem[byte_addr]};
```
- Đọc 4 bytes (toàn bộ word)
- **Little-endian**: Byte thấp nhất ở địa chỉ thấp nhất
- **Ví dụ**: 
  - `mem[addr] = 0x78`, `mem[addr+1] = 0x56`, `mem[addr+2] = 0x34`, `mem[addr+3] = 0x12`
  - → `rdata = 0x12345678`

#### LBU (Load Byte Unsigned) - `mem_size = 100`
```systemverilog
rdata <= {24'b0, mem[byte_addr]};
```
- Đọc 1 byte và **zero-extend** (thêm số 0)
- **Ví dụ**: 
  - `mem[addr] = 0x78` → `rdata = 0x00000078`
  - `mem[addr] = 0xF8` → `rdata = 0x000000F8` (không sign-extend!)

#### LHU (Load Halfword Unsigned) - `mem_size = 101`
```systemverilog
rdata <= {16'b0, mem[byte_addr+1], mem[byte_addr]};
```
- Đọc 2 bytes và **zero-extend**
- **Ví dụ**: 
  - `mem[addr] = 0x78`, `mem[addr+1] = 0x56` → `rdata = 0x00005678`
  - `mem[addr] = 0x78`, `mem[addr+1] = 0xF6` → `rdata = 0x0000F678` (không sign-extend!)

## 🎬 Ví Dụ Thực Tế

### Ví Dụ 1: SW (Store Word)

**Lệnh**: `SW x1, 0(x2)` (Ghi x1 vào địa chỉ x2 + 0)

**Giả sử**: `x1 = 0x12345678`, `x2 = 0x1000`

**DMEM nhận**:
- `we = 1` ✅
- `addr = 0x1000`
- `wdata = 0x12345678`
- `mem_size = 010` (SW)

**Tại cạnh lên của clock**:
- `mem[0x1000] = 0x78` (byte thấp)
- `mem[0x1001] = 0x56`
- `mem[0x1002] = 0x34`
- `mem[0x1003] = 0x12` (byte cao)

**Kết quả**: Dữ liệu `0x12345678` được ghi vào địa chỉ `0x1000`

### Ví Dụ 2: LW (Load Word)

**Lệnh**: `LW x1, 0(x2)` (Đọc từ địa chỉ x2 + 0 vào x1)

**Giả sử**: `x2 = 0x1000`, bộ nhớ tại `0x1000` chứa `0x12345678`

**DMEM nhận**:
- `we = 0` (đọc)
- `addr = 0x1000`
- `mem_size = 010` (LW)

**Tại cạnh lên của clock**:
- Đọc 4 bytes: `mem[0x1000] = 0x78`, `mem[0x1001] = 0x56`, `mem[0x1002] = 0x34`, `mem[0x1003] = 0x12`
- `rdata = {0x12, 0x34, 0x56, 0x78} = 0x12345678`

**Kết quả**: `x1 = 0x12345678`

### Ví Dụ 3: LB vs LBU (Signed vs Unsigned)

**Giả sử**: `mem[0x1000] = 0xF8` (số âm nếu coi là signed)

**LB (Load Byte - Signed)**:
- `mem_size = 000`
- `rdata = {{24{0xF8[7]}}, 0xF8} = {{24{1'b1}}, 0xF8} = 0xFFFFFFF8` (sign-extend)
- → `x1 = -8` (nếu coi là signed)

**LBU (Load Byte Unsigned)**:
- `mem_size = 100`
- `rdata = {24'b0, 0xF8} = 0x000000F8` (zero-extend)
- → `x1 = 248` (nếu coi là unsigned)

**Khác biệt**: LB sign-extend (giữ bit dấu), LBU zero-extend (thêm số 0)

### Ví Dụ 4: SH (Store Halfword)

**Lệnh**: `SH x1, 0(x2)` (Ghi 16 bits thấp của x1 vào địa chỉ x2 + 0)

**Giả sử**: `x1 = 0x12345678`, `x2 = 0x1000`

**DMEM nhận**:
- `we = 1`
- `addr = 0x1000`
- `wdata = 0x12345678`
- `mem_size = 001` (SH)

**Tại cạnh lên của clock**:
- `mem[0x1000] = 0x78` (16 bits thấp: 0x5678)
- `mem[0x1001] = 0x56`

**Kết quả**: Chỉ 16 bits thấp (`0x5678`) được ghi, 16 bits cao (`0x1234`) bị bỏ qua

## 🔍 Điểm Quan Trọng

### 1. Signed vs Unsigned

- **Signed (LB, LH)**: Sign-extend (mở rộng bit dấu)
  - Bit 7 (byte) hoặc bit 15 (halfword) là bit dấu
  - Nếu bit dấu = 1 → điền toàn bộ bits cao = 1
  - Nếu bit dấu = 0 → điền toàn bộ bits cao = 0

- **Unsigned (LBU, LHU)**: Zero-extend (điền số 0)
  - Luôn điền bits cao = 0
  - Không quan tâm bit dấu

### 2. Little-Endian Byte Order

- Byte thấp nhất ở địa chỉ thấp nhất
- Phù hợp với RISC-V specification

**Ví dụ**:
```
Word = 0x12345678
→ mem[addr+0] = 0x78 (LSB)
→ mem[addr+1] = 0x56
→ mem[addr+2] = 0x34
→ mem[addr+3] = 0x12 (MSB)
```

### 3. Synchronous Read/Write

- Cả đọc và ghi đều là sequential (cần clock)
- BRAM compatible (cho FPGA synthesis)

### 4. Address Bounds Checking

- Kiểm tra `byte_addr < MEM_SIZE` trước khi ghi
- Kiểm tra `byte_addr+1` hoặc `byte_addr+3` trước khi đọc/ghi halfword/word

## 📊 Bảng Tóm Tắt

| mem_size | Loại Lệnh | Kích Thước | Signed/Unsigned | Ví Dụ |
|----------|-----------|------------|------------------|-------|
| 000 | SB/LB | 8 bits | Signed (LB) | `mem[addr] = wdata[7:0]` |
| 001 | SH/LH | 16 bits | Signed (LH) | `mem[addr:addr+1] = wdata[15:0]` |
| 010 | SW/LW | 32 bits | N/A | `mem[addr:addr+3] = wdata[31:0]` |
| 100 | LBU | 8 bits | Unsigned | `rdata = {24'b0, mem[addr]}` |
| 101 | LHU | 16 bits | Unsigned | `rdata = {16'b0, mem[addr:addr+1]}` |

## 🎓 Kết Luận

DMEM là module quan trọng, lưu trữ dữ liệu và cho phép đọc/ghi với nhiều kích thước khác nhau. Module này:
- Hỗ trợ byte, halfword, và word operations
- Hỗ trợ cả signed và unsigned operations
- Little-endian byte order
- Synchronous read/write (BRAM compatible)
- 64 KiB memory size




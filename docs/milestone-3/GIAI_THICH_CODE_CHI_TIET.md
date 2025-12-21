# Giải Thích Code Chi Tiết - Pipeline Processor (PL1 & PL2)

## Mục Lục
1. [Tổng Quan Về Pipeline Processor](#tổng-quan)
2. [So Sánh PL1 và PL2](#so-sánh)
3. [Giải Thích Từng Module](#từng-module)
4. [Ví Dụ Cụ Thể](#ví-dụ)

---

## Tổng Quan Về Pipeline Processor {#tổng-quan}

### Pipeline là gì?

Hãy tưởng tượng một nhà máy sản xuất xe hơi. Thay vì một công nhân làm hết tất cả các bước (lắp bánh xe, lắp động cơ, sơn xe...), nhà máy chia thành nhiều trạm:
- **Trạm 1**: Lắp bánh xe
- **Trạm 2**: Lắp động cơ  
- **Trạm 3**: Sơn xe
- **Trạm 4**: Kiểm tra chất lượng

Khi chiếc xe đầu tiên đang ở trạm 2, chiếc xe thứ 2 đã có thể vào trạm 1. Như vậy, nhiều xe được sản xuất đồng thời, nhanh hơn nhiều!

**Pipeline Processor** hoạt động tương tự:
- **IF (Instruction Fetch)**: Lấy lệnh từ bộ nhớ
- **ID (Instruction Decode)**: Giải mã lệnh, đọc dữ liệu từ thanh ghi
- **EX (Execute)**: Thực hiện phép tính (cộng, trừ, so sánh...)
- **MEM (Memory)**: Đọc/ghi dữ liệu từ bộ nhớ
- **WB (Write Back)**: Ghi kết quả vào thanh ghi

### Ví Dụ Đơn Giản

Giả sử bạn có 3 lệnh cần thực hiện:
```
Lệnh 1: ADD x1, x2, x3    (x1 = x2 + x3)
Lệnh 2: SUB x4, x1, x5    (x4 = x1 - x5)
Lệnh 3: ADD x6, x4, x7    (x6 = x4 + x7)
```

**Không dùng Pipeline** (thực hiện tuần tự):
```
Cycle 1: Lệnh 1 - IF
Cycle 2: Lệnh 1 - ID
Cycle 3: Lệnh 1 - EX
Cycle 4: Lệnh 1 - MEM
Cycle 5: Lệnh 1 - WB
Cycle 6: Lệnh 2 - IF
Cycle 7: Lệnh 2 - ID
...
Tổng: 15 cycles
```

**Dùng Pipeline** (thực hiện song song):
```
Cycle 1: Lệnh 1 - IF
Cycle 2: Lệnh 1 - ID, Lệnh 2 - IF
Cycle 3: Lệnh 1 - EX, Lệnh 2 - ID, Lệnh 3 - IF
Cycle 4: Lệnh 1 - MEM, Lệnh 2 - EX, Lệnh 3 - ID
Cycle 5: Lệnh 1 - WB, Lệnh 2 - MEM, Lệnh 3 - EX
Cycle 6: Lệnh 2 - WB, Lệnh 3 - MEM
Cycle 7: Lệnh 3 - WB
Tổng: 7 cycles (nhanh hơn 2 lần!)
```

---

## So Sánh PL1 và PL2 {#so-sánh}

### PL1 (Non-Forwarding) - Không Chuyển Dữ Liệu Trước

**Vấn đề**: Khi lệnh 2 cần dữ liệu từ lệnh 1, nhưng lệnh 1 chưa ghi xong vào thanh ghi.

**Giải pháp**: **Dừng pipeline** (stall) và đợi lệnh 1 hoàn thành.

**Ví dụ**:
```
Lệnh 1: ADD x1, x2, x3    (tính x1 = x2 + x3)
Lệnh 2: ADD x4, x1, x5    (cần x1 từ lệnh 1)
```

**PL1 xử lý**:
```
Cycle 1: Lệnh 1 - EX (đang tính x1)
Cycle 2: Lệnh 2 - ID (cần x1, nhưng x1 chưa có) → **STALL!**
Cycle 3: Lệnh 1 - MEM (x1 vẫn chưa ghi vào thanh ghi) → **STALL!**
Cycle 4: Lệnh 1 - WB (x1 đã ghi vào thanh ghi) → Tiếp tục
Cycle 5: Lệnh 2 - EX (bây giờ mới có x1)
```

**Nhược điểm**: Mất 2 cycles để đợi!

### PL2 (Forwarding) - Chuyển Dữ Liệu Trước

**Giải pháp**: **Chuyển dữ liệu trực tiếp** từ stage MEM hoặc WB của lệnh 1 sang EX của lệnh 2, không cần đợi ghi vào thanh ghi.

**Ví dụ tương tự**:
```
Cycle 1: Lệnh 1 - EX (đang tính x1)
Cycle 2: Lệnh 1 - MEM (x1 đã có kết quả), Lệnh 2 - EX → **FORWARD x1 từ MEM!**
Cycle 3: Lệnh 1 - WB, Lệnh 2 - MEM
```

**Ưu điểm**: Không cần stall, nhanh hơn!

---

## Giải Thích Từng Module {#từng-module}

### 1. Module `pipelined.sv` - Bộ Xử Lý Chính

Đây là module chính, kết nối tất cả các phần lại với nhau.

#### 1.1. Các Tín Hiệu Đầu Vào/Đầu Ra

```systemverilog
input  logic         i_clk     ,  // Xung nhịp (như nhịp tim của bộ xử lý)
input  logic         i_reset   ,  // Nút reset (khởi động lại)
input  logic [31:0]  i_io_sw   ,  // Đọc dữ liệu từ công tắc (switches)
output logic [31:0]  o_io_ledr ,  // Điều khiển đèn LED đỏ
output logic [31:0]  o_io_ledg ,  // Điều khiển đèn LED xanh
output logic [31:0]  o_io_lcd  ,  // Điều khiển màn hình LCD
output logic [ 6:0]  o_io_hex0 ,  // Điều khiển màn hình 7 đoạn (HEX0-7)
...
```

**Giải thích**:
- `i_clk`: Giống như nhịp tim, mỗi nhịp là một chu kỳ, bộ xử lý làm việc theo nhịp này
- `i_reset`: Khi bật, tất cả về trạng thái ban đầu (giống như khởi động lại máy tính)
- `i_io_sw`: Đọc trạng thái các công tắc vật lý (ví dụ: công tắc bật/tắt)
- `o_io_ledr/ledg`: Điều khiển đèn LED để hiển thị trạng thái
- `o_io_hex0-7`: Điều khiển 8 màn hình 7 đoạn (hiển thị số)

#### 1.2. Pipeline Stages - Các Giai Đoạn

##### IF Stage (Instruction Fetch) - Lấy Lệnh

```systemverilog
logic [31:0] pc;              // Program Counter - địa chỉ lệnh hiện tại
logic [31:0] pc_next;          // Địa chỉ lệnh tiếp theo
logic [31:0] pc_plus4;        // PC + 4 (lệnh tiếp theo trong bộ nhớ)
logic [31:0] if_instruction;  // Lệnh vừa lấy được
```

**Ví dụ**:
- PC = 0x0000_0000 → Lấy lệnh ở địa chỉ này
- PC + 4 = 0x0000_0004 → Lệnh tiếp theo (mỗi lệnh 4 bytes)
- Nếu là branch/jump, PC có thể nhảy đến địa chỉ khác

**Code thực tế**:
```systemverilog
assign pc_plus4 = pc + 32'h4;  // Tính địa chỉ lệnh tiếp theo

always_ff @(posedge i_clk) begin
    if (~i_reset) begin
        pc <= 32'h0000_0000;  // Reset về địa chỉ 0
    end else if (if_enable) begin
        pc <= pc_next;        // Cập nhật PC
    end
end
```

**Giải thích**:
- Mỗi khi có xung nhịp (`posedge i_clk`), nếu không reset và được phép (`if_enable`), thì cập nhật PC
- `pc_next` có thể là `pc_plus4` (lệnh tiếp theo) hoặc địa chỉ branch/jump

##### ID Stage (Instruction Decode) - Giải Mã Lệnh

```systemverilog
logic [31:0] id_instruction;  // Lệnh cần giải mã
logic [ 4:0] id_rs1_addr;     // Địa chỉ thanh ghi nguồn 1 (rs1)
logic [ 4:0] id_rs2_addr;     // Địa chỉ thanh ghi nguồn 2 (rs2)
logic [ 4:0] id_rd_addr;       // Địa chỉ thanh ghi đích (rd)
logic [31:0] id_rs1_data;     // Dữ liệu từ thanh ghi rs1
logic [31:0] id_rs2_data;     // Dữ liệu từ thanh ghi rs2
logic [31:0] id_imm;          // Giá trị hằng số (immediate)
```

**Ví dụ với lệnh**: `ADD x1, x2, x3`
- `id_rs1_addr = 2` (x2)
- `id_rs2_addr = 3` (x3)
- `id_rd_addr = 1` (x1 - nơi ghi kết quả)
- `id_rs1_data = giá trị trong x2`
- `id_rs2_data = giá trị trong x3`

**Code thực tế**:
```systemverilog
assign id_rs1_addr = id_instruction[19:15];  // Bits 19-15 là địa chỉ rs1
assign id_rs2_addr = id_instruction[24:20];  // Bits 24-20 là địa chỉ rs2
assign id_rd_addr = id_instruction[11:7];     // Bits 11-7 là địa chỉ rd

register_file u_regfile (
    .clk        (i_clk),
    .we         (wb_reg_write && wb_enable),
    .addr_rs1   (id_rs1_addr),
    .addr_rs2   (id_rs2_addr),
    .addr_rd    (wb_rd_addr),
    .wdata      (wb_reg_wdata),
    .rdata_rs1  (id_rs1_data),
    .rdata_rs2  (id_rs2_data)
);
```

**Giải thích**:
- Lệnh RISC-V có format cố định, các bit ở vị trí cố định chứa địa chỉ thanh ghi
- `register_file` đọc dữ liệu từ 2 thanh ghi (rs1, rs2) và ghi vào 1 thanh ghi (rd)

##### EX Stage (Execute) - Thực Hiện Phép Tính

```systemverilog
logic [31:0] ex_alu_a;        // Toán hạng 1 cho ALU
logic [31:0] ex_alu_b;         // Toán hạng 2 cho ALU
logic [31:0] ex_alu_result;    // Kết quả từ ALU
logic [1:0]  forward_a;        // Tín hiệu forwarding cho toán hạng 1
logic [1:0]  forward_b;         // Tín hiệu forwarding cho toán hạng 2
```

**Ví dụ**: `ADD x1, x2, x3`
- `ex_alu_a = giá trị x2`
- `ex_alu_b = giá trị x3`
- `ex_alu_result = x2 + x3`

**Forwarding trong PL2**:
```systemverilog
// Forwarding MUX - chọn dữ liệu từ đâu
always_comb begin
    case (forward_a)
        2'b00: forward_rs1_data = ex_rs1_data;      // Từ thanh ghi (bình thường)
        2'b01: forward_rs1_data = wb_reg_wdata;     // Từ WB stage (lệnh trước)
        2'b10: forward_rs1_data = mem_alu_result;   // Từ MEM stage (lệnh trước)
        default: forward_rs1_data = ex_rs1_data;
    endcase
end
```

**Giải thích**:
- `forward_a = 00`: Dùng dữ liệu từ thanh ghi (bình thường)
- `forward_a = 01`: Dùng dữ liệu từ WB stage (lệnh trước vừa ghi xong)
- `forward_a = 10`: Dùng dữ liệu từ MEM stage (lệnh trước đang ở MEM, chưa ghi nhưng đã có kết quả)

**Ví dụ cụ thể**:
```
Lệnh 1: ADD x1, x2, x3    (EX stage: đang tính x1)
Lệnh 2: ADD x4, x1, x5    (EX stage: cần x1)

PL1: forward_a = 00 → Đợi x1 ghi vào thanh ghi → STALL!
PL2: forward_a = 10 → Lấy x1 trực tiếp từ MEM stage của lệnh 1 → KHÔNG STALL!
```

##### MEM Stage (Memory Access) - Truy Cập Bộ Nhớ

```systemverilog
logic [31:0] mem_addr;        // Địa chỉ trong bộ nhớ
logic [31:0] mem_wdata;        // Dữ liệu cần ghi
logic [31:0] mem_rdata;        // Dữ liệu đọc được
logic        mem_mem_write;    // Tín hiệu ghi bộ nhớ
logic        mem_mem_read;     // Tín hiệu đọc bộ nhớ
```

**Ví dụ với lệnh**: `LW x1, 0(x2)` (Load Word - đọc từ bộ nhớ)
- `mem_addr = giá trị x2 + 0`
- `mem_mem_read = 1` (bật tín hiệu đọc)
- `mem_rdata = dữ liệu đọc được từ bộ nhớ`

**Ví dụ với lệnh**: `SW x1, 0(x2)` (Store Word - ghi vào bộ nhớ)
- `mem_addr = giá trị x2 + 0`
- `mem_wdata = giá trị x1`
- `mem_mem_write = 1` (bật tín hiệu ghi)

**Code thực tế**:
```systemverilog
dmem_sync u_dmem (
    .clk        (i_clk),
    .enable     (mem_enable),
    .we         (mem_mem_write && (mem_addr < 32'h0001_0000)),
    .addr       (mem_addr),
    .wdata      (mem_wdata),
    .mem_size   (mem_mem_size),
    .rdata      (mem_rdata)
);
```

**Giải thích**:
- `dmem_sync` là module bộ nhớ dữ liệu
- `we = 1` khi cần ghi, `we = 0` khi chỉ đọc
- `mem_size` xác định kích thước: byte (8 bits), halfword (16 bits), word (32 bits)

##### WB Stage (Write Back) - Ghi Kết Quả

```systemverilog
logic [31:0] wb_reg_wdata;    // Dữ liệu cần ghi vào thanh ghi
logic [ 4:0] wb_rd_addr;       // Địa chỉ thanh ghi đích
logic        wb_reg_write;     // Tín hiệu cho phép ghi
```

**Ví dụ**: Sau khi tính `x1 = x2 + x3`
- `wb_reg_wdata = kết quả từ ALU (x2 + x3)`
- `wb_rd_addr = 1` (x1)
- `wb_reg_write = 1` (cho phép ghi)

**Code thực tế**:
```systemverilog
always_comb begin
    case (wb_mem_to_reg)
        2'b00: wb_reg_wdata = wb_alu_result;  // Ghi kết quả từ ALU
        2'b01: wb_reg_wdata = wb_io_data;      // Ghi dữ liệu từ I/O
        2'b10: wb_reg_wdata = wb_pc_plus4;     // Ghi PC+4 (cho JAL)
        default: wb_reg_wdata = wb_alu_result;
    endcase
end
```

**Giải thích**:
- `mem_to_reg` quyết định ghi gì vào thanh ghi:
  - `00`: Kết quả từ ALU (phép tính)
  - `01`: Dữ liệu từ bộ nhớ/I/O (load instruction)
  - `10`: PC+4 (cho lệnh JAL - jump and link)

### 2. Module `alu.sv` - Bộ Tính Toán Số Học

ALU (Arithmetic Logic Unit) là "bộ não tính toán" của processor.

```systemverilog
module alu (
    input  logic [31:0]  op_a,      // Toán hạng 1
    input  logic [31:0]  op_b,      // Toán hạng 2
    input  logic [ 3:0]  alu_op,    // Mã lệnh (cộng, trừ, AND, OR...)
    output logic [31:0] alu_out,    // Kết quả
    output logic        alu_zero    // Cờ zero (kết quả = 0?)
);
```

**Các phép toán**:
```systemverilog
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
```

**Ví dụ**:
- `op_a = 5`, `op_b = 3`, `alu_op = 0000` → `alu_out = 8` (5 + 3)
- `op_a = 5`, `op_b = 3`, `alu_op = 0001` → `alu_out = 2` (5 - 3)
- `op_a = 5` (binary: 101), `op_b = 3` (binary: 011), `alu_op = 0010` → `alu_out = 1` (101 AND 011 = 001)

**Giải thích**:
- ALU nhận 2 số và một mã lệnh, trả về kết quả tương ứng
- `alu_zero = 1` nếu kết quả = 0 (dùng cho branch instructions)

### 3. Module `control_unit.sv` - Bộ Điều Khiển

Control Unit giải mã lệnh và tạo các tín hiệu điều khiển.

**Ví dụ với lệnh**: `ADD x1, x2, x3` (opcode = 0110011)
```systemverilog
7'b0110011: begin
    reg_write = 1'b1;        // Cho phép ghi vào thanh ghi
    mem_to_reg = 2'b00;      // Ghi kết quả từ ALU (không phải từ memory)
    alu_src_a = 2'b00;       // ALU input A từ thanh ghi rs1
    alu_src_b = 2'b00;       // ALU input B từ thanh ghi rs2
    alu_op = 4'b0000;        // Phép cộng
end
```

**Ví dụ với lệnh**: `LW x1, 0(x2)` (Load Word - opcode = 0000011)
```systemverilog
7'b0000011: begin
    reg_write = 1'b1;        // Cho phép ghi vào thanh ghi
    mem_read  = 1'b1;        // Đọc từ bộ nhớ
    mem_to_reg = 2'b01;      // Ghi dữ liệu từ memory (không phải từ ALU)
    alu_src_a = 2'b00;       // ALU input A từ thanh ghi rs1 (x2)
    alu_src_b = 2'b01;       // ALU input B từ immediate (0)
    alu_op    = 4'b0000;      // Phép cộng (tính địa chỉ: x2 + 0)
end
```

**Giải thích**:
- Control Unit xem 7 bit đầu của lệnh (opcode) để biết loại lệnh
- Sau đó tạo các tín hiệu điều khiển phù hợp:
  - `reg_write`: Có ghi vào thanh ghi không?
  - `mem_read/mem_write`: Có đọc/ghi bộ nhớ không?
  - `alu_op`: ALU làm phép toán gì?

### 4. Module `register_file.sv` - Bộ Thanh Ghi

Register File là nơi lưu trữ 32 thanh ghi (x0-x31).

```systemverilog
module register_file (
    input  logic         clk,
    input  logic         we,           // Write enable - cho phép ghi
    input  logic [ 4:0]  addr_rs1,     // Địa chỉ thanh ghi nguồn 1
    input  logic [ 4:0]  addr_rs2,     // Địa chỉ thanh ghi nguồn 2
    input  logic [ 4:0]  addr_rd,      // Địa chỉ thanh ghi đích
    input  logic [31:0]  wdata,        // Dữ liệu cần ghi
    output logic [31:0]  rdata_rs1,    // Dữ liệu đọc từ rs1
    output logic [31:0]  rdata_rs2     // Dữ liệu đọc từ rs2
);

logic [31:0] registers [0:31];  // 32 thanh ghi, mỗi thanh 32 bits

always_ff @(posedge clk) begin
    if (we && addr_rd != 5'b0) begin
        registers[addr_rd] <= wdata;  // Ghi dữ liệu vào thanh ghi
    end
end

assign rdata_rs1 = (addr_rs1 == 5'b0) ? 32'b0 : registers[addr_rs1];
assign rdata_rs2 = (addr_rs2 == 5'b0) ? 32'b0 : registers[addr_rs2];
endmodule
```

**Giải thích**:
- `registers[0:31]` là mảng 32 thanh ghi
- `x0` (registers[0]) luôn = 0 (theo đặc tả RISC-V)
- Đọc dữ liệu: `rdata_rs1 = registers[addr_rs1]` (không cần clock)
- Ghi dữ liệu: `registers[addr_rd] <= wdata` (cần clock, chỉ khi `we = 1`)

**Ví dụ**:
- Đọc: `addr_rs1 = 2` → `rdata_rs1 = registers[2]` (giá trị trong x2)
- Ghi: `addr_rd = 1`, `wdata = 100`, `we = 1` → `registers[1] = 100` (x1 = 100)

### 5. Module `imem_sync.sv` - Bộ Nhớ Lệnh

Instruction Memory lưu trữ các lệnh của chương trình.

```systemverilog
module imem_sync (
    input  logic         clk,
    input  logic         enable,
    input  logic [31:0]  addr,        // Địa chỉ lệnh
    output logic [31:0] rdata        // Lệnh đọc được
);

parameter MEM_SIZE = 65536;  // 64 KiB
logic [7:0] mem [0:MEM_SIZE-1];  // Bộ nhớ byte-addressable

always_ff @(posedge clk) begin
    if (enable) begin
        if (byte_addr+3 < MEM_SIZE) begin
            // Đọc 4 bytes (1 lệnh) - little-endian
            rdata <= {mem[byte_addr+3], mem[byte_addr+2], 
                     mem[byte_addr+1], mem[byte_addr]};
        end else begin
            rdata <= 32'b0;
        end
    end
end
endmodule
```

**Giải thích**:
- Bộ nhớ lưu trữ dưới dạng bytes (mỗi phần tử 8 bits)
- Mỗi lệnh RISC-V dài 32 bits = 4 bytes
- Little-endian: byte thấp nhất ở địa chỉ thấp nhất
- Đọc đồng bộ (synchronous): cần clock để đọc

**Ví dụ**:
- `addr = 0x0000_0000` → Đọc bytes tại địa chỉ 0, 1, 2, 3
- `mem[0] = 0x12`, `mem[1] = 0x34`, `mem[2] = 0x56`, `mem[3] = 0x78`
- `rdata = 0x78563412` (little-endian)

### 6. Module `dmem_sync.sv` - Bộ Nhớ Dữ Liệu

Data Memory lưu trữ dữ liệu của chương trình.

**Đọc dữ liệu**:
```systemverilog
case (mem_size)
    3'b000: rdata <= {{24{mem[byte_addr][7]}}, mem[byte_addr]};  // LB (Load Byte - sign-extend)
    3'b001: rdata <= {{16{mem[byte_addr+1][7]}}, mem[byte_addr+1], mem[byte_addr]};  // LH (Load Halfword)
    3'b010: rdata <= {mem[byte_addr+3], mem[byte_addr+2], mem[byte_addr+1], mem[byte_addr]};  // LW (Load Word)
    3'b100: rdata <= {24'b0, mem[byte_addr]};  // LBU (Load Byte Unsigned - zero-extend)
    3'b101: rdata <= {16'b0, mem[byte_addr+1], mem[byte_addr]};  // LHU (Load Halfword Unsigned)
endcase
```

**Ghi dữ liệu**:
```systemverilog
case (mem_size)
    3'b000: mem[byte_addr] <= wdata[7:0];  // SB (Store Byte)
    3'b001: begin  // SH (Store Halfword)
        mem[byte_addr]   <= wdata[7:0];
        mem[byte_addr+1] <= wdata[15:8];
    end
    3'b010: begin  // SW (Store Word)
        mem[byte_addr]   <= wdata[7:0];
        mem[byte_addr+1] <= wdata[15:8];
        mem[byte_addr+2] <= wdata[23:16];
        mem[byte_addr+3] <= wdata[31:24];
    end
endcase
```

**Giải thích**:
- `mem_size` xác định kích thước: byte (8 bits), halfword (16 bits), word (32 bits)
- Sign-extend: Mở rộng bit dấu (bit 7) cho LB/LH
- Zero-extend: Thêm số 0 cho LBU/LHU
- Little-endian: Byte thấp nhất ở địa chỉ thấp nhất

**Ví dụ**:
- Ghi: `addr = 0x1000`, `wdata = 0x12345678`, `mem_size = 010` (SW)
  - `mem[0x1000] = 0x78`
  - `mem[0x1001] = 0x56`
  - `mem[0x1002] = 0x34`
  - `mem[0x1003] = 0x12`
- Đọc: `addr = 0x1000`, `mem_size = 000` (LB)
  - `rdata = 0xFFFFFF78` (sign-extend từ 0x78)

---

## Ví Dụ Cụ Thể {#ví-dụ}

### Ví Dụ 1: ADD x1, x2, x3 (PL1 vs PL2)

**Lệnh**: `ADD x1, x2, x3` (x1 = x2 + x3)

**Giả sử**: `x2 = 10`, `x3 = 20`

#### PL1 (Non-Forwarding):

```
Cycle 1:
  IF: Lấy lệnh ADD x1, x2, x3 từ bộ nhớ
      PC = 0x0000_0000

Cycle 2:
  IF: Lấy lệnh tiếp theo (PC = 0x0000_0004)
  ID: Giải mã lệnh ADD x1, x2, x3
      Đọc x2 = 10, x3 = 20 từ register file

Cycle 3:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: ALU tính x1 = x2 + x3 = 10 + 20 = 30

Cycle 4:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: (lệnh tiếp theo)
  MEM: Lệnh ADD không cần truy cập bộ nhớ, chỉ chuyển kết quả

Cycle 5:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: (lệnh tiếp theo)
  MEM: (lệnh tiếp theo)
  WB: Ghi x1 = 30 vào register file
```

**Tổng**: 5 cycles để hoàn thành 1 lệnh

#### PL2 (Forwarding):

Tương tự PL1, nhưng nếu lệnh tiếp theo cần x1:

```
Lệnh 1: ADD x1, x2, x3
Lệnh 2: ADD x4, x1, x5    (cần x1 từ lệnh 1)

Cycle 3:
  Lệnh 1 - EX: Tính x1 = 30
  Lệnh 2 - EX: Cần x1 → Forward từ MEM stage của lệnh 1 → KHÔNG STALL!

Cycle 4:
  Lệnh 1 - MEM: x1 = 30 (đã có kết quả)
  Lệnh 2 - EX: Dùng x1 = 30 từ forwarding → Tính x4 = x1 + x5
```

**Tổng**: Không cần stall, nhanh hơn PL1!

### Ví Dụ 2: LW x1, 0(x2) (Load Word)

**Lệnh**: `LW x1, 0(x2)` (Đọc từ bộ nhớ tại địa chỉ x2 + 0, ghi vào x1)

**Giả sử**: `x2 = 0x1000`, bộ nhớ tại `0x1000` chứa `0x12345678`

```
Cycle 1:
  IF: Lấy lệnh LW x1, 0(x2)

Cycle 2:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh LW
      Đọc x2 = 0x1000 từ register file

Cycle 3:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: ALU tính địa chỉ = x2 + 0 = 0x1000

Cycle 4:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: (lệnh tiếp theo)
  MEM: Đọc từ bộ nhớ tại địa chỉ 0x1000 → rdata = 0x12345678

Cycle 5:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: (lệnh tiếp theo)
  MEM: (lệnh tiếp theo)
  WB: Ghi x1 = 0x12345678 vào register file
```

**Lưu ý**: Load instruction cần 2 cycles (MEM và WB) để có dữ liệu, không thể forward sớm hơn!

### Ví Dụ 3: Load-Use Hazard (Cả PL1 và PL2 đều cần STALL)

**Lệnh**:
```
Lệnh 1: LW x1, 0(x2)    (Đọc từ bộ nhớ vào x1)
Lệnh 2: ADD x3, x1, x4  (Cần x1 từ lệnh 1)
```

**Vấn đề**: Lệnh 2 cần x1, nhưng x1 chỉ có sau khi lệnh 1 hoàn thành WB (cycle 5).

**Giải pháp**: **STALL 1 cycle** (cả PL1 và PL2 đều phải làm vậy!)

```
Cycle 3:
  Lệnh 1 - EX: Tính địa chỉ = x2 + 0
  Lệnh 2 - ID: Cần x1, nhưng x1 chưa có → **STALL!**

Cycle 4:
  Lệnh 1 - MEM: Đọc từ bộ nhớ → x1 = 0x12345678 (chưa ghi vào register file)
  Lệnh 2 - ID: Vẫn cần x1 → **STALL!** (insert bubble vào EX)

Cycle 5:
  Lệnh 1 - WB: Ghi x1 = 0x12345678 vào register file
  Lệnh 2 - ID: Bây giờ mới có x1 → Tiếp tục
  (Bubble trong EX - không làm gì)

Cycle 6:
  Lệnh 2 - EX: Dùng x1 = 0x12345678 → Tính x3 = x1 + x4
```

**Tổng**: Mất 1 cycle để stall (không thể tránh được vì load cần 2 cycles)

### Ví Dụ 4: Branch Prediction

**Lệnh**:
```
Lệnh: BEQ x1, x2, label    (Nếu x1 == x2, nhảy đến label)
```

**Vấn đề**: Khi lệnh ở IF stage, chưa biết x1 và x2 bằng nhau hay không, nhưng cần quyết định PC ngay!

**Giải pháp**: **Branch Prediction** - Dự đoán trước!

#### Two-bit Branch Predictor:

```
State 00: Strongly not-taken (Rất chắc là không nhảy)
State 01: Weakly not-taken (Hơi chắc là không nhảy)
State 10: Weakly taken (Hơi chắc là nhảy)
State 11: Strongly taken (Rất chắc là nhảy)
```

**Ví dụ**:
```
Lần 1: BEQ x1, x2, label
  - State = 01 (weakly not-taken) → Dự đoán: KHÔNG nhảy
  - Thực tế: x1 == x2 → NHẢY!
  - Cập nhật: State = 11 (strongly taken)

Lần 2: BEQ x1, x2, label
  - State = 11 (strongly taken) → Dự đoán: NHẢY
  - Thực tế: x1 == x2 → NHẢY!
  - Cập nhật: State = 11 (giữ nguyên)

Lần 3: BEQ x1, x2, label
  - State = 11 (strongly taken) → Dự đoán: NHẢY
  - Thực tế: x1 != x2 → KHÔNG NHẢY!
  - Cập nhật: State = 10 (weakly taken)
```

**Misprediction**: Nếu dự đoán sai, phải flush pipeline và lấy lệnh đúng!

```
Cycle 1:
  IF: Dự đoán NHẢY → Lấy lệnh tại label

Cycle 2:
  IF: Lấy lệnh tiếp theo tại label
  ID: Giải mã lệnh tại label

Cycle 3:
  IF: Lấy lệnh tiếp theo
  ID: Giải mã lệnh tiếp theo
  EX: So sánh x1 và x2 → x1 != x2 → KHÔNG NHẢY! → **MISPREDICTION!**

Cycle 4:
  IF: Flush → Lấy lệnh đúng (PC+4 thay vì label)
  ID: Flush
  EX: Flush
```

**Tổng**: Mất 2 cycles do misprediction!

---

## Tóm Tắt

### PL1 (Non-Forwarding):
- ✅ Đơn giản hơn
- ❌ Nhiều stall cycles
- ❌ Performance thấp hơn

### PL2 (Forwarding):
- ✅ Ít stall cycles
- ✅ Performance cao hơn
- ❌ Phức tạp hơn (cần Forwarding Unit)

### Cả hai đều có:
- ✅ Branch Prediction (Two-bit + BTB)
- ✅ BRAM-compatible memory
- ✅ I/O support (LED, HEX, LCD, Switch)
- ✅ Load-use hazard detection (cần stall)

---

## Kết Luận

Pipeline processor giống như một dây chuyền sản xuất, cho phép nhiều lệnh được xử lý đồng thời. PL2 nhanh hơn PL1 nhờ forwarding mechanism, nhưng cả hai đều đảm bảo tính chính xác và hỗ trợ đầy đủ các tính năng cần thiết.


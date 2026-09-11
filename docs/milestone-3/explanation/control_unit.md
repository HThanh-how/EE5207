# Giải Thích File: control_unit.sv

## 📋 Tổng Quan

File `control_unit.sv` chứa module **Control Unit** - đây là "bộ não điều khiển" của processor. Control Unit đọc lệnh (instruction) và tạo ra các tín hiệu điều khiển để các module khác biết phải làm gì.

## 🎯 Module Làm Gì?

Control Unit giống như một **người chỉ huy**:
- Nhìn vào lệnh (instruction)
- Phân tích lệnh đó là gì (ADD, SUB, LW, SW, BEQ...)
- Ra lệnh cho các module khác: "Làm cái này!", "Làm cái kia!"

**Ví dụ đơn giản**:
- Input: Lệnh `ADD x1, x2, x3`
- Output: "Bật ALU, dùng phép cộng, ghi vào thanh ghi x1"

## 📝 Code Chi Tiết

### 1. Khai Báo Module

```systemverilog
module control_unit (
    input  logic [6:0]  opcode,      // 7 bits đầu của lệnh (loại lệnh)
    input  logic [2:0]  funct3,       // 3 bits tiếp theo (chi tiết lệnh)
    input  logic [6:0]  funct7,       // 7 bits cuối (chi tiết thêm)
    output logic        reg_write,   // Có ghi vào thanh ghi không?
    output logic        mem_write,   // Có ghi vào bộ nhớ không?
    output logic        mem_read,    // Có đọc từ bộ nhớ không?
    output logic [1:0]  mem_to_reg,  // Ghi gì vào thanh ghi? (ALU result / memory / PC+4)
    output logic [1:0]  alu_src_a,   // ALU input A từ đâu?
    output logic [1:0]  alu_src_b,   // ALU input B từ đâu?
    output logic [3:0]  alu_op,      // ALU làm phép toán gì?
    output logic        branch,      // Có phải branch instruction không?
    output logic        jump,        // Có phải jump instruction không?
    output logic [2:0]  mem_size,    // Kích thước memory access (byte/halfword/word)
    output logic        pc_src      // PC source (không dùng trong pipeline)
);
```

**Giải thích các tín hiệu**:

- **Inputs**:
  - `opcode`: 7 bits đầu của lệnh RISC-V, xác định loại lệnh
  - `funct3`: 3 bits tiếp theo, xác định chi tiết (ví dụ: loại branch nào)
  - `funct7`: 7 bits cuối, xác định thêm chi tiết (ví dụ: SUB vs ADD)

- **Outputs**:
  - `reg_write`: = 1 nếu cần ghi vào thanh ghi
  - `mem_write`: = 1 nếu cần ghi vào bộ nhớ (store instruction)
  - `mem_read`: = 1 nếu cần đọc từ bộ nhớ (load instruction)
  - `mem_to_reg`: Chọn dữ liệu ghi vào thanh ghi (00=ALU, 01=memory, 10=PC+4)
  - `alu_src_a/b`: Chọn input cho ALU (00=register, 01=immediate, 10=PC, 11=upper immediate)
  - `alu_op`: Mã lệnh cho ALU (cộng, trừ, AND, OR...)
  - `branch`: = 1 nếu là branch instruction (BEQ, BNE...)
  - `jump`: = 1 nếu là jump instruction (JAL, JALR...)
  - `mem_size`: Kích thước (000=byte, 001=halfword, 010=word)

### 2. Khởi Tạo Mặc Định

```systemverilog
always_comb begin
    reg_write = 1'b0;        // Mặc định: không ghi
    mem_write = 1'b0;        // Mặc định: không ghi memory
    mem_read  = 1'b0;        // Mặc định: không đọc memory
    mem_to_reg = 2'b00;      // Mặc định: ghi từ ALU
    alu_src_a  = 2'b00;      // Mặc định: ALU input A từ register
    alu_src_b  = 2'b00;      // Mặc định: ALU input B từ register
    alu_op     = 4'b0000;    // Mặc định: phép cộng
    branch     = 1'b0;       // Mặc định: không phải branch
    jump       = 1'b0;       // Mặc định: không phải jump
    mem_size   = 3'b010;     // Mặc định: word (32 bits)
    pc_src     = 1'b0;       // Mặc định: PC source
```

**Giải thích**: Tất cả tín hiệu được khởi tạo về giá trị mặc định (an toàn), sau đó sẽ được thay đổi tùy theo loại lệnh.

### 3. Decode Theo Opcode

Control Unit sử dụng `case` statement để decode opcode:

```systemverilog
case (opcode)
    // Các loại lệnh khác nhau...
endcase
```

#### 3.1. R-Type Instructions (7'b0110011)

**Ví dụ**: `ADD x1, x2, x3`, `SUB x1, x2, x3`, `AND x1, x2, x3`...

```systemverilog
7'b0110011: begin
    reg_write = 1'b1;        // Có ghi vào thanh ghi
    mem_to_reg = 2'b00;      // Ghi kết quả từ ALU
    alu_src_a = 2'b00;       // ALU input A từ register rs1
    alu_src_b = 2'b00;       // ALU input B từ register rs2
    case (funct3)
        3'b000: alu_op = (funct7[5] == 1'b1) ? 4'b0001 : 4'b0000;  // SUB nếu funct7[5]=1, ADD nếu =0
        3'b001: alu_op = 4'b0101;  // SLL (Shift Left Logical)
        3'b010: alu_op = 4'b1000;  // SLT (Set Less Than - signed)
        3'b011: alu_op = 4'b1001;  // SLTU (Set Less Than - unsigned)
        3'b100: alu_op = 4'b0100;  // XOR
        3'b101: alu_op = (funct7[5] == 1'b1) ? 4'b0111 : 4'b0110;  // SRA nếu funct7[5]=1, SRL nếu =0
        3'b110: alu_op = 4'b0011;  // OR
        3'b111: alu_op = 4'b0010;  // AND
    endcase
end
```

**Giải thích**:
- R-type dùng 2 thanh ghi làm input, ghi kết quả vào thanh ghi
- `funct3` xác định phép toán cụ thể
- `funct7[5]` phân biệt ADD/SUB và SRL/SRA

**Ví dụ**: `ADD x1, x2, x3`
- `opcode = 0110011`
- `funct3 = 000`
- `funct7[5] = 0`
- → `alu_op = 0000` (ADD)

#### 3.2. I-Type Instructions (7'b0010011)

**Ví dụ**: `ADDI x1, x2, 100`, `SLLI x1, x2, 5`...

```systemverilog
7'b0010011: begin
    reg_write = 1'b1;        // Có ghi vào thanh ghi
    mem_to_reg = 2'b00;      // Ghi kết quả từ ALU
    alu_src_a = 2'b00;       // ALU input A từ register rs1
    alu_src_b = 2'b01;       // ALU input B từ immediate (hằng số)
    case (funct3)
        3'b000: alu_op = 4'b0000;  // ADDI (Add Immediate)
        3'b001: alu_op = 4'b0101;  // SLLI (Shift Left Logical Immediate)
        3'b010: alu_op = 4'b1000;  // SLTI (Set Less Than Immediate - signed)
        3'b011: alu_op = 4'b1001;  // SLTIU (Set Less Than Immediate - unsigned)
        3'b100: alu_op = 4'b0100;  // XORI (XOR Immediate)
        3'b101: alu_op = (funct7[5] == 1'b1) ? 4'b0111 : 4'b0110;  // SRAI/SRLI
        3'b110: alu_op = 4'b0011;  // ORI (OR Immediate)
        3'b111: alu_op = 4'b0010;  // ANDI (AND Immediate)
    endcase
end
```

**Giải thích**:
- I-type dùng 1 thanh ghi và 1 hằng số (immediate) làm input
- `alu_src_b = 01` nghĩa là dùng immediate thay vì register

**Ví dụ**: `ADDI x1, x2, 100`
- `opcode = 0010011`
- `funct3 = 000`
- → `alu_op = 0000` (ADD), `alu_src_b = 01` (dùng immediate 100)

#### 3.3. Load Instructions (7'b0000011)

**Ví dụ**: `LW x1, 100(x2)`, `LB x1, 100(x2)`...

```systemverilog
7'b0000011: begin
    reg_write = 1'b1;        // Có ghi vào thanh ghi
    mem_read  = 1'b1;        // Đọc từ bộ nhớ
    mem_to_reg = 2'b01;      // Ghi dữ liệu từ memory (không phải từ ALU)
    alu_src_a = 2'b00;       // ALU input A từ register rs1 (địa chỉ base)
    alu_src_b = 2'b01;       // ALU input B từ immediate (offset)
    alu_op    = 4'b0000;     // Phép cộng (tính địa chỉ: base + offset)
    case (funct3)
        3'b000: mem_size = 3'b000;  // LB (Load Byte)
        3'b001: mem_size = 3'b001;  // LH (Load Halfword)
        3'b010: mem_size = 3'b010;  // LW (Load Word)
        3'b100: mem_size = 3'b100;  // LBU (Load Byte Unsigned)
        3'b101: mem_size = 3'b101;  // LHU (Load Halfword Unsigned)
        default: mem_size = 3'b010;
    endcase
end
```

**Giải thích**:
- Load instruction đọc từ bộ nhớ và ghi vào thanh ghi
- ALU tính địa chỉ: `base + offset` (rs1 + immediate)
- `mem_to_reg = 01` nghĩa là ghi dữ liệu từ memory, không phải từ ALU
- `funct3` xác định kích thước (byte/halfword/word) và signed/unsigned

**Ví dụ**: `LW x1, 100(x2)`
- `opcode = 0000011`
- `funct3 = 010` (LW)
- → `mem_read = 1`, `mem_size = 010` (word), `mem_to_reg = 01`

#### 3.4. Store Instructions (7'b0100011)

**Ví dụ**: `SW x1, 100(x2)`, `SB x1, 100(x2)`...

```systemverilog
7'b0100011: begin
    mem_write = 1'b1;        // Ghi vào bộ nhớ
    alu_src_a = 2'b00;       // ALU input A từ register rs1 (địa chỉ base)
    alu_src_b = 2'b01;       // ALU input B từ immediate (offset)
    alu_op    = 4'b0000;     // Phép cộng (tính địa chỉ: base + offset)
    case (funct3)
        3'b000: mem_size = 3'b000;  // SB (Store Byte)
        3'b001: mem_size = 3'b001;  // SH (Store Halfword)
        3'b010: mem_size = 3'b010;  // SW (Store Word)
        default: mem_size = 3'b010;
    endcase
end
```

**Giải thích**:
- Store instruction ghi từ thanh ghi vào bộ nhớ
- ALU tính địa chỉ: `base + offset`
- `reg_write = 0` (mặc định) vì không ghi vào thanh ghi

**Ví dụ**: `SW x1, 100(x2)`
- `opcode = 0100011`
- `funct3 = 010` (SW)
- → `mem_write = 1`, `mem_size = 010` (word)

#### 3.5. Branch Instructions (7'b1100011)

**Ví dụ**: `BEQ x1, x2, label`, `BNE x1, x2, label`...

```systemverilog
7'b1100011: begin
    branch = 1'b1;           // Đây là branch instruction
    alu_src_a = 2'b00;       // ALU input A từ register rs1
    alu_src_b = 2'b00;       // ALU input B từ register rs2
    case (funct3)
        3'b000: alu_op = 4'b0001;  // BEQ (Branch if Equal)
        3'b001: alu_op = 4'b0001;  // BNE (Branch if Not Equal)
        3'b100: alu_op = 4'b0001;  // BLT (Branch if Less Than - signed)
        3'b101: alu_op = 4'b0001;  // BGE (Branch if Greater or Equal - signed)
        3'b110: alu_op = 4'b0001;  // BLTU (Branch if Less Than - unsigned)
        3'b111: alu_op = 4'b0001;  // BGEU (Branch if Greater or Equal - unsigned)
        default: alu_op = 4'b0001;
    endcase
end
```

**Giải thích**:
- Branch instruction so sánh 2 thanh ghi và quyết định có nhảy hay không
- `funct3` xác định loại so sánh (equal, not equal, less than...)
- `alu_op = 0001` (SUB) để so sánh (rs1 - rs2)

**Ví dụ**: `BEQ x1, x2, label`
- `opcode = 1100011`
- `funct3 = 000` (BEQ)
- → `branch = 1`, `alu_op = 0001` (SUB để so sánh)

#### 3.6. JALR Instruction (7'b1100111)

**Ví dụ**: `JALR x1, x2, 100`

```systemverilog
7'b1100111: begin
    reg_write = 1'b1;        // Ghi PC+4 vào thanh ghi (link register)
    mem_to_reg = 2'b10;      // Ghi PC+4 (không phải ALU result hay memory)
    jump = 1'b1;             // Đây là jump instruction
    alu_src_a = 2'b10;       // ALU input A từ PC
    alu_src_b = 2'b01;       // ALU input B từ immediate
    alu_op = 4'b0000;        // Phép cộng (tính địa chỉ: PC + immediate)
end
```

**Giải thích**:
- JALR nhảy đến địa chỉ `rs1 + immediate` và lưu PC+4 vào `rd`
- `alu_src_a = 10` nghĩa là dùng PC thay vì register
- `mem_to_reg = 10` nghĩa là ghi PC+4 vào thanh ghi

#### 3.7. JAL Instruction (7'b1101111)

**Ví dụ**: `JAL x1, label`

```systemverilog
7'b1101111: begin
    reg_write = 1'b1;        // Ghi PC+4 vào thanh ghi
    mem_to_reg = 2'b10;      // Ghi PC+4
    jump = 1'b1;             // Đây là jump instruction
end
```

**Giải thích**:
- JAL nhảy đến địa chỉ `PC + immediate` và lưu PC+4 vào `rd`
- Địa chỉ jump được tính từ immediate trong instruction (không cần ALU)

#### 3.8. AUIPC Instruction (7'b0010111)

**Ví dụ**: `AUIPC x1, 1000`

```systemverilog
7'b0010111: begin
    reg_write = 1'b1;        // Ghi vào thanh ghi
    mem_to_reg = 2'b00;      // Ghi kết quả từ ALU
    alu_src_a = 2'b01;       // ALU input A từ PC
    alu_src_b = 2'b01;       // ALU input B từ immediate
    alu_op = 4'b0000;        // Phép cộng (PC + immediate)
end
```

**Giải thích**:
- AUIPC tính `PC + (immediate << 12)` và ghi vào thanh ghi
- Dùng để tính địa chỉ tuyệt đối (absolute address)

#### 3.9. LUI Instruction (7'b0110111)

**Ví dụ**: `LUI x1, 0x12345`

```systemverilog
7'b0110111: begin
    reg_write = 1'b1;        // Ghi vào thanh ghi
    mem_to_reg = 2'b00;      // Ghi kết quả từ ALU
    alu_src_a = 2'b11;       // ALU input A từ upper immediate
    alu_src_b = 2'b11;       // ALU input B từ upper immediate
    alu_op = 4'b0000;        // Phép cộng (thực ra chỉ cần pass through)
end
```

**Giải thích**:
- LUI load upper immediate (20 bits cao) vào thanh ghi
- `alu_src_a/b = 11` nghĩa là dùng upper immediate

## 🎬 Ví Dụ Thực Tế

### Ví Dụ 1: ADD x1, x2, x3

**Lệnh**: `ADD x1, x2, x3`

**Opcode**: `0110011` (R-type)

**Control Unit tạo**:
- `reg_write = 1` ✅
- `mem_write = 0`
- `mem_read = 0`
- `mem_to_reg = 00` (ghi từ ALU)
- `alu_src_a = 00` (từ register rs1 = x2)
- `alu_src_b = 00` (từ register rs2 = x3)
- `alu_op = 0000` (ADD)
- `branch = 0`
- `jump = 0`

**Kết quả**: ALU tính `x2 + x3`, ghi vào `x1`

### Ví Dụ 2: LW x1, 100(x2)

**Lệnh**: `LW x1, 100(x2)`

**Opcode**: `0000011` (Load)

**Control Unit tạo**:
- `reg_write = 1` ✅
- `mem_read = 1` ✅
- `mem_to_reg = 01` (ghi từ memory)
- `alu_src_a = 00` (từ register rs1 = x2)
- `alu_src_b = 01` (từ immediate = 100)
- `alu_op = 0000` (ADD để tính địa chỉ)
- `mem_size = 010` (word)

**Kết quả**: ALU tính địa chỉ `x2 + 100`, đọc từ memory, ghi vào `x1`

### Ví Dụ 3: BEQ x1, x2, label

**Lệnh**: `BEQ x1, x2, label`

**Opcode**: `1100011` (Branch)

**Control Unit tạo**:
- `reg_write = 0`
- `branch = 1` ✅
- `alu_src_a = 00` (từ register rs1 = x1)
- `alu_src_b = 00` (từ register rs2 = x2)
- `alu_op = 0001` (SUB để so sánh)

**Kết quả**: ALU so sánh `x1 - x2`, nếu = 0 thì nhảy đến label

## 📊 Bảng Tóm Tắt Opcodes

| Opcode | Loại Lệnh | Ví Dụ |
|--------|-----------|-------|
| 0110011 | R-type | ADD, SUB, AND, OR... |
| 0010011 | I-type | ADDI, SLLI, XORI... |
| 0000011 | Load | LW, LB, LH... |
| 0100011 | Store | SW, SB, SH... |
| 1100011 | Branch | BEQ, BNE, BLT... |
| 1100111 | JALR | JALR |
| 1101111 | JAL | JAL |
| 0010111 | AUIPC | AUIPC |
| 0110111 | LUI | LUI |

## 🔍 Điểm Quan Trọng

1. **Combinational Logic**: Control Unit dùng `always_comb`, tín hiệu được tạo ngay lập tức

2. **Default Values**: Tất cả tín hiệu được khởi tạo về giá trị mặc định (an toàn)

3. **Opcode-Based Decoding**: Dùng `case` statement để decode opcode

4. **Funct3 và Funct7**: Dùng để xác định chi tiết của lệnh (loại phép toán, kích thước...)

## 🎓 Kết Luận

Control Unit là module quan trọng, đọc lệnh và tạo các tín hiệu điều khiển để các module khác biết phải làm gì. Module này giống như "bộ não" của processor, quyết định mọi hoạt động.




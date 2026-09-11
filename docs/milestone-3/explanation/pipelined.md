# Giải Thích File: pipelined.sv

## 📋 Tổng Quan

File `pipelined.sv` là **module chính** của Pipeline Processor, kết nối tất cả các module lại với nhau và thực hiện 5-stage pipeline. Đây là file phức tạp nhất, chứa toàn bộ logic của processor.

## 🎯 Module Làm Gì?

Pipeline Processor giống như một **dây chuyền sản xuất** với 5 trạm:
1. **IF (Instruction Fetch)**: Lấy lệnh từ bộ nhớ
2. **ID (Instruction Decode)**: Giải mã lệnh, đọc thanh ghi
3. **EX (Execute)**: Thực hiện phép tính
4. **MEM (Memory Access)**: Đọc/ghi bộ nhớ
5. **WB (Write Back)**: Ghi kết quả vào thanh ghi

**Đặc điểm Model 1**:
- ❌ **Không có Forwarding** - luôn dùng dữ liệu từ thanh ghi
- ✅ **Hazard Detection** - phát hiện và xử lý hazards
- ✅ **Branch Prediction** - Two-bit + BTB

---

## 📝 Phần 1: Khai Báo Module và Signals

### 1.1. Module Interface

```systemverilog
module pipelined (
    input  logic         i_clk     ,    // Xung nhịp
    input  logic         i_reset   ,    // Reset signal
    input  logic [31:0]  i_io_sw   ,    // Switches input
    output logic [31:0]  o_io_ledr ,    // LED đỏ output
    output logic [31:0]  o_io_ledg ,    // LED xanh output
    output logic [31:0]  o_io_lcd  ,    // LCD output
    output logic [ 6:0]  o_io_hex0 ,    // HEX0-7 outputs
    ...
    output logic [31:0]  o_pc_debug,    // PC debug signal
    output logic         o_insn_vld,    // Instruction valid signal
    output logic         o_ctrl    ,    // Control transfer signal
    output logic         o_mispred       // Misprediction signal
);
```

**Giải thích**:
- `i_clk`, `i_reset`: Clock và reset
- `i_io_sw`: Đọc từ switches
- `o_io_ledr/ledg/lcd/hex0-7`: Điều khiển I/O peripherals
- `o_pc_debug`: PC để debug
- `o_insn_vld`: = 1 khi instruction hợp lệ
- `o_ctrl`: = 1 khi là branch/jump
- `o_mispred`: = 1 khi branch/jump bị mispredicted

### 1.2. Pipeline Stage Signals

File có rất nhiều signals, được chia thành các nhóm:

#### IF Stage Signals
```systemverilog
logic [31:0] pc;              // Program Counter
logic [31:0] pc_next;         // PC tiếp theo
logic [31:0] pc_plus4;        // PC + 4
logic [31:0] if_instruction;  // Lệnh vừa lấy được
logic        if_enable;       // Cho phép IF stage
logic        if_flush;        // Flush IF stage
```

#### ID Stage Signals
```systemverilog
logic [31:0] id_instruction;  // Lệnh cần giải mã
logic [31:0] id_rs1_data;      // Dữ liệu từ thanh ghi rs1
logic [31:0] id_rs2_data;      // Dữ liệu từ thanh ghi rs2
logic [ 4:0] id_rs1_addr;      // Địa chỉ thanh ghi rs1
logic [ 4:0] id_rs2_addr;      // Địa chỉ thanh ghi rs2
logic [ 4:0] id_rd_addr;       // Địa chỉ thanh ghi đích
logic [31:0] id_imm;           // Giá trị immediate
// ... và nhiều control signals khác
```

#### EX Stage Signals
```systemverilog
logic [31:0] ex_alu_result;    // Kết quả từ ALU
logic        ex_branch_taken;  // Branch có nhảy không?
logic [31:0] ex_branch_target;  // Địa chỉ nhảy (branch)
logic [31:0] ex_jump_target;   // Địa chỉ nhảy (jump)
// ... và nhiều signals khác
```

#### MEM Stage Signals
```systemverilog
logic [31:0] mem_addr;         // Địa chỉ memory
logic [31:0] mem_wdata;        // Dữ liệu cần ghi
logic [31:0] mem_rdata;        // Dữ liệu đọc được
logic [31:0] mem_io_data;      // Dữ liệu I/O
```

#### WB Stage Signals
```systemverilog
logic [31:0] wb_reg_wdata;     // Dữ liệu ghi vào thanh ghi
```

#### Pipeline Registers
- `IF/ID Register`: Lưu dữ liệu từ IF sang ID
- `ID/EX Register`: Lưu dữ liệu từ ID sang EX
- `EX/MEM Register`: Lưu dữ liệu từ EX sang MEM
- `MEM/WB Register`: Lưu dữ liệu từ MEM sang WB

---

## 📝 Phần 2: Branch Prediction (BTB + Two-bit)

### 2.1. Khai Báo BTB

```systemverilog
parameter BTB_SIZE = 256;  // 256 entries
parameter BTB_INDEX_WIDTH = $clog2(BTB_SIZE);  // = 8 bits

// BTB entry: {tag, predicted_pc, two_bit_state}
logic [31-BTB_INDEX_WIDTH-2:0] btb_tag [0:BTB_SIZE-1];
logic [31:0] btb_target [0:BTB_SIZE-1];
logic [1:0]  btb_state [0:BTB_SIZE-1];  // Two-bit predictor state
```

**Giải thích**:
- **BTB (Branch Target Buffer)**: Lưu trữ địa chỉ nhảy dự đoán
- **256 entries**: Có thể lưu 256 branch/jump instructions
- **btb_tag**: Tag để so khớp (xác định entry nào)
- **btb_target**: Địa chỉ nhảy dự đoán
- **btb_state**: Two-bit predictor state (00, 01, 10, 11)

### 2.2. Khởi Tạo BTB

```systemverilog
initial begin
    for (i = 0; i < BTB_SIZE; i = i + 1) begin
        btb_tag[i] = '0;
        btb_target[i] = '0;
        btb_state[i] = 2'b01;  // Start with "weakly not-taken"
    end
end
```

**Giải thích**:
- Khởi tạo tất cả entries về 0
- State khởi tạo = `01` (weakly not-taken)

### 2.3. BTB Lookup (Trong IF Stage)

```systemverilog
assign btb_index_if = pc[BTB_INDEX_WIDTH+1:2];  // Bits 9:2 của PC
assign btb_tag_if = pc[31:BTB_INDEX_WIDTH+2];   // Bits 31:10 của PC

always_comb begin
    btb_hit = 1'b0;
    predicted_pc = pc_plus4;  // Mặc định: không nhảy (PC+4)
    predict_taken = 1'b0;
    
    // Kiểm tra tag match
    if (btb_tag[btb_index_if] == btb_tag_if) begin
        // Tag khớp - entry tồn tại trong BTB
        if (btb_state[btb_index_if] >= 2'b10) begin
            // State >= 10 nghĩa là "taken" (weakly hoặc strongly taken)
            btb_hit = 1'b1;
            predicted_pc = btb_target[btb_index_if];
            predict_taken = 1'b1;
        end
        // Nếu state = 00 hoặc 01 (not-taken), dự đoán PC+4
    end
    // Nếu không có tag match, dự đoán PC+4 (mặc định)
end
```

**Giải thích**:
- **BTB Index**: Lấy từ bits 9:2 của PC (256 entries cần 8 bits index)
- **BTB Tag**: Lấy từ bits 31:10 của PC (để so khớp)
- **Dự đoán**: 
  - Nếu state >= 10 (taken) → dự đoán nhảy đến `btb_target`
  - Nếu state < 10 (not-taken) → dự đoán PC+4

**Ví dụ**:
- PC = 0x1000
- `btb_index_if = 0x1000[9:2] = 0x40`
- `btb_tag_if = 0x1000[31:10] = 0x4`
- Kiểm tra: `btb_tag[0x40] == 0x4`?
  - Nếu có và `btb_state[0x40] >= 2'b10` → dự đoán nhảy đến `btb_target[0x40]`

### 2.4. BTB Update (Trong EX Stage)

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset) begin
        // Reset BTB
        for (k = 0; k < BTB_SIZE; k = k + 1) begin
            btb_tag[k] <= '0;
            btb_target[k] <= '0;
            btb_state[k] <= 2'b01;
        end
    end else if (ex_enable && ex_is_ctrl) begin
        // Cập nhật BTB khi branch/jump được resolve
        btb_tag[btb_index_ex] <= btb_tag_ex;
        if (ex_branch) begin
            btb_target[btb_index_ex] <= ex_branch_target;
        end else if (ex_jump) begin
            btb_target[btb_index_ex] <= ex_jump_target;
        end
        
        // Cập nhật two-bit predictor state machine
        if (ex_branch) begin
            case (btb_state[btb_index_ex])
                2'b00: begin  // Strongly not-taken
                    if (ex_branch_taken) begin
                        btb_state[btb_index_ex] <= 2'b01;  // → Weakly not-taken
                    end
                end
                2'b01: begin  // Weakly not-taken
                    if (ex_branch_taken) begin
                        btb_state[btb_index_ex] <= 2'b11;  // → Weakly taken
                    end else begin
                        btb_state[btb_index_ex] <= 2'b00;  // → Strongly not-taken
                    end
                end
                2'b10: begin  // Weakly taken
                    if (ex_branch_taken) begin
                        btb_state[btb_index_ex] <= 2'b11;  // → Strongly taken
                    end else begin
                        btb_state[btb_index_ex] <= 2'b01;  // → Weakly not-taken
                    end
                end
                2'b11: begin  // Strongly taken
                    if (~ex_branch_taken) begin
                        btb_state[btb_index_ex] <= 2'b10;  // → Weakly taken
                    end
                end
            endcase
        end else if (ex_jump) begin
            // Jumps luôn taken, set về strongly taken
            btb_state[btb_index_ex] <= 2'b11;
        end
    end
end
```

**Giải thích Two-bit State Machine**:

| State | Tên | Ý Nghĩa |
|-------|-----|---------|
| 00 | Strongly not-taken | Rất chắc không nhảy |
| 01 | Weakly not-taken | Hơi chắc không nhảy |
| 10 | Weakly taken | Hơi chắc nhảy |
| 11 | Strongly taken | Rất chắc nhảy |

**Chuyển đổi state**:
- Nếu dự đoán đúng → giữ nguyên hoặc tăng độ chắc chắn
- Nếu dự đoán sai → giảm độ chắc chắn hoặc đổi chiều

**Ví dụ**:
- State = 01 (weakly not-taken), branch thực tế = taken
- → Chuyển sang 11 (weakly taken) - đổi chiều và tăng độ chắc chắn

---

## 📝 Phần 3: IF Stage (Instruction Fetch)

### 3.1. PC Selection Logic

```systemverilog
assign if_enable = ~stall_if;  // Cho phép IF khi không stall
assign if_flush = flush_if;    // Flush khi có misprediction
assign pc_plus4 = pc + 32'h4;  // PC tiếp theo (sequential)

// PC selection: dùng predicted PC hoặc corrected PC
logic [31:0] corrected_pc;
logic        use_corrected_pc;

always_comb begin
    use_corrected_pc = 1'b0;
    corrected_pc = 32'b0;
    
    // Kiểm tra misprediction trong EX stage
    if (ex_is_ctrl && ex_enable) begin
        logic actual_taken;
        logic [31:0] actual_target;
        
        if (ex_branch) begin
            actual_taken = ex_branch_taken;
            actual_target = ex_branch_target;
        end else begin
            actual_taken = 1'b1;  // Jumps luôn taken
            actual_target = ex_jump_target;
        end
        
        // Misprediction: predicted != actual
        if (ex_predicted_taken != actual_taken) begin
            use_corrected_pc = 1'b1;
            corrected_pc = actual_target;
        end
    end
    
    // Chọn PC tiếp theo
    if (use_corrected_pc) begin
        pc_next = corrected_pc;  // Dùng PC đúng (sau misprediction)
    end else if (btb_hit && predict_taken) begin
        pc_next = predicted_pc;  // Dùng predicted PC (từ BTB)
    end else begin
        pc_next = pc_plus4;      // Sequential (PC+4)
    end
end
```

**Giải thích**:
- **Ưu tiên 1**: Nếu có misprediction → dùng `corrected_pc` (PC đúng)
- **Ưu tiên 2**: Nếu BTB hit và predict taken → dùng `predicted_pc`
- **Mặc định**: Dùng `pc_plus4` (sequential)

### 3.2. PC Update

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset) begin
        pc <= 32'h0000_0000;  // Reset về địa chỉ 0
    end else if (if_enable) begin
        pc <= pc_next;  // Cập nhật PC
    end
end
```

**Giải thích**:
- Reset: PC = 0
- Nếu `if_enable = 1` (không stall) → cập nhật PC

### 3.3. Instruction Fetch

```systemverilog
imem_sync u_imem (
    .clk     (i_clk),
    .enable  (if_enable),
    .addr    (pc),
    .rdata   (if_instruction)
);
```

**Giải thích**:
- Đọc lệnh từ IMEM tại địa chỉ PC
- Lệnh được lưu vào `if_instruction`

### 3.4. IF/ID Pipeline Register

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset || if_flush) begin
        // Reset hoặc flush → clear register
        id_pc <= 32'b0;
        id_pc_plus4 <= 32'b0;
        id_instruction <= 32'b0;
        id_enable <= 1'b0;
    end else if (if_enable && ~stall_id) begin
        // Không stall → chuyển dữ liệu sang ID stage
        id_pc <= pc;
        id_pc_plus4 <= pc_plus4;
        id_instruction <= if_instruction;
        id_enable <= 1'b1;
    end
end
```

**Giải thích**:
- **Reset/Flush**: Clear register (insert bubble)
- **Stall**: Giữ nguyên giá trị cũ
- **Normal**: Chuyển dữ liệu sang ID stage

---

## 📝 Phần 4: ID Stage (Instruction Decode)

### 4.1. Extract Instruction Fields

```systemverilog
assign id_rs1_addr = id_instruction[19:15];  // Bits 19-15: rs1
assign id_rs2_addr = id_instruction[24:20];  // Bits 24-20: rs2
assign id_rd_addr = id_instruction[11:7];    // Bits 11-7: rd
```

**Giải thích**:
- RISC-V instruction format có các fields ở vị trí cố định
- Extract địa chỉ thanh ghi từ instruction

### 4.2. Control Unit

```systemverilog
control_unit u_control (
    .opcode     (id_instruction[6:0]),
    .funct3     (id_instruction[14:12]),
    .funct7     (id_instruction[31:25]),
    .reg_write  (id_reg_write),
    .mem_write  (id_mem_write),
    .mem_read   (id_mem_read),
    // ... các tín hiệu điều khiển khác
);
```

**Giải thích**:
- Control Unit giải mã lệnh và tạo các tín hiệu điều khiển
- Xem [control_unit.md](control_unit.md) để hiểu chi tiết

### 4.3. Register File

```systemverilog
register_file u_regfile (
    .clk        (i_clk),
    .we         (wb_reg_write && wb_enable),  // Ghi từ WB stage
    .addr_rs1   (id_rs1_addr),
    .addr_rs2   (id_rs2_addr),
    .addr_rd    (wb_rd_addr),
    .wdata      (wb_reg_wdata),
    .rdata_rs1  (id_rs1_data),
    .rdata_rs2  (id_rs2_data)
);
```

**Giải thích**:
- Đọc 2 thanh ghi (rs1, rs2) cho ID stage
- Ghi vào thanh ghi (rd) từ WB stage

### 4.4. Immediate Generation

```systemverilog
always_comb begin
    case (id_instruction[6:0])  // Opcode
        7'b0110111: id_imm = {id_instruction[31:12], 12'b0};  // LUI
        7'b0010111: id_imm = {id_instruction[31:12], 12'b0};  // AUIPC
        7'b1101111: id_imm = {{12{id_instruction[31]}}, ...}; // JAL
        7'b1100011: id_imm = {{20{id_instruction[31]}}, ...}; // Branch
        7'b0100011: id_imm = {{20{id_instruction[31]}}, ...}; // Store
        7'b0010011: begin
            if (id_instruction[14:12] == 3'b001 || id_instruction[14:12] == 3'b101) begin
                id_imm = {27'b0, id_instruction[24:20]};  // Shift immediate
            end else begin
                id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};  // I-type
            end
        end
        7'b0000011: id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]}; // Load
        7'b1100111: id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]}; // JALR
        default: id_imm = 32'b0;
    endcase
end
```

**Giải thích**:
- Mỗi loại lệnh có format immediate khác nhau
- Sign-extend: Lặp lại bit dấu (bit 31) để mở rộng

**Ví dụ**:
- I-type: `id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]}`
  - Bits 31:20 là immediate
  - Bits 31 được lặp lại 20 lần để sign-extend

### 4.5. ID/EX Pipeline Register

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset || flush_id) begin
        // Reset hoặc flush → clear register
        ex_pc <= 32'b0;
        ex_rs1_data <= 32'b0;
        // ... clear tất cả signals
    end else if (~stall_ex && id_enable) begin
        // Không stall → chuyển dữ liệu sang EX stage
        ex_pc <= id_pc;
        ex_rs1_data <= id_rs1_data;
        ex_rs2_data <= id_rs2_data;
        ex_imm <= id_imm;
        // ... chuyển tất cả signals
        ex_predicted_taken <= (id_branch || id_jump) ? predict_taken : 1'b0;
    end
end
```

**Giải thích**:
- Chuyển dữ liệu từ ID sang EX stage
- Lưu prediction từ IF stage để kiểm tra misprediction sau

---

## 📝 Phần 5: EX Stage (Execute)

### 5.1. Forwarding MUX (Model 1: Disabled)

```systemverilog
// Forwarding MUX for ALU inputs
always_comb begin
    case (forward_a)
        2'b00: forward_rs1_data = ex_rs1_data;      // Từ thanh ghi
        2'b01: forward_rs1_data = wb_reg_wdata;     // Từ WB stage
        2'b10: forward_rs1_data = mem_alu_result;   // Từ MEM stage
        default: forward_rs1_data = ex_rs1_data;
    endcase
    
    case (forward_b)
        2'b00: forward_rs2_data = ex_rs2_data;
        2'b01: forward_rs2_data = wb_reg_wdata;
        2'b10: forward_rs2_data = mem_alu_result;
        default: forward_rs2_data = ex_rs2_data;
    endcase
end
```

**Giải thích**:
- Forwarding MUX chọn dữ liệu từ đâu
- **Model 1**: `forward_a/b` luôn = 00 → luôn dùng từ thanh ghi
- **Model 2**: `forward_a/b` có thể = 01 hoặc 10 → forward từ WB/MEM

### 5.2. ALU Input Selection

```systemverilog
always_comb begin
    case (ex_alu_src_a)
        2'b00: ex_alu_a = forward_rs1_data;  // Từ thanh ghi (hoặc forwarded)
        2'b01: ex_alu_a = ex_pc;             // Từ PC (AUIPC)
        2'b10: ex_alu_a = ex_pc;             // Từ PC (JALR)
        2'b11: ex_alu_a = {ex_imm[31:12], 12'b0};  // Upper immediate (LUI)
        default: ex_alu_a = forward_rs1_data;
    endcase
    
    case (ex_alu_src_b)
        2'b00: ex_alu_b = forward_rs2_data;  // Từ thanh ghi
        2'b01: ex_alu_b = ex_imm;            // Từ immediate
        2'b10: ex_alu_b = 32'h4;             // Số 4 (PC+4)
        2'b11: ex_alu_b = 32'b0;             // Số 0
        default: ex_alu_b = forward_rs2_data;
    endcase
end
```

**Giải thích**:
- Chọn input cho ALU tùy theo loại lệnh
- `alu_src_a/b` được tạo bởi Control Unit

### 5.3. ALU

```systemverilog
alu u_alu (
    .op_a       (ex_alu_a),
    .op_b       (ex_alu_b),
    .alu_op     (ex_alu_op),
    .alu_out    (ex_alu_result),
    .alu_zero   (ex_alu_zero)
);
```

**Giải thích**:
- ALU thực hiện phép toán
- Xem [alu.md](alu.md) để hiểu chi tiết

### 5.4. Branch Comparison

```systemverilog
always_comb begin
    if (ex_branch) begin
        case (ex_funct3)
            3'b000: ex_branch_taken = (forward_rs1_data == forward_rs2_data);  // BEQ
            3'b001: ex_branch_taken = (forward_rs1_data != forward_rs2_data);  // BNE
            3'b100: ex_branch_taken = ($signed(forward_rs1_data) < $signed(forward_rs2_data));  // BLT
            3'b101: ex_branch_taken = ($signed(forward_rs1_data) >= $signed(forward_rs2_data)); // BGE
            3'b110: ex_branch_taken = (forward_rs1_data < forward_rs2_data);  // BLTU
            3'b111: ex_branch_taken = (forward_rs1_data >= forward_rs2_data);  // BGEU
            default: ex_branch_taken = 1'b0;
        endcase
    end else begin
        ex_branch_taken = 1'b0;
    end
end
```

**Giải thích**:
- So sánh 2 thanh ghi để quyết định branch có nhảy không
- Dùng `forward_rs1_data` và `forward_rs2_data` (có thể forward từ MEM/WB)

### 5.5. Branch/Jump Target Calculation

```systemverilog
assign ex_branch_target = ex_pc + ex_imm;  // Branch target
assign ex_jump_target = ex_jump ? (ex_pc + ex_imm) : (forward_rs1_data + ex_imm);  // Jump target
assign ex_is_ctrl = ex_branch || ex_jump;  // Có phải control transfer không?
```

**Giải thích**:
- **Branch target**: PC + immediate
- **Jump target**: 
  - JAL: PC + immediate
  - JALR: rs1 + immediate

### 5.6. EX/MEM Pipeline Register

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset || flush_ex) begin
        // Reset hoặc flush → clear register
        mem_alu_result <= 32'b0;
        // ... clear tất cả signals
    end else if (ex_enable) begin
        // Chuyển dữ liệu sang MEM stage
        mem_alu_result <= ex_alu_result;
        mem_rs2_data <= forward_rs2_data;  // Dùng forwarded data
        // ... chuyển tất cả signals
    end
end
```

**Giải thích**:
- Chuyển dữ liệu từ EX sang MEM stage
- Lưu `forward_rs2_data` (có thể forward từ WB/MEM)

---

## 📝 Phần 6: MEM Stage (Memory Access)

### 6.1. Memory Address and Data

```systemverilog
assign mem_addr = mem_alu_result;   // Địa chỉ = kết quả ALU
assign mem_wdata = mem_rs2_data;    // Dữ liệu ghi = rs2 data
```

**Giải thích**:
- Địa chỉ memory được tính từ ALU result
- Dữ liệu ghi lấy từ rs2 (đã forward nếu cần)

### 6.2. Data Memory

```systemverilog
dmem_sync u_dmem (
    .clk        (i_clk),
    .enable     (mem_enable),
    .we         (mem_mem_write && (mem_addr < 32'h0001_0000)),  // Chỉ ghi vào memory region
    .addr       (mem_addr),
    .wdata      (mem_wdata),
    .mem_size   (mem_mem_size),
    .rdata      (mem_rdata)
);
```

**Giải thích**:
- Đọc/ghi từ DMEM
- Chỉ ghi vào memory region (0x0000_0000 - 0x0000_FFFF)
- I/O region (0x1000_0000+) được xử lý riêng

### 6.3. I/O Memory Mapping

```systemverilog
always_comb begin
    if (mem_mem_read) begin
        if (mem_addr >= 32'h1000_4000 && mem_addr < 32'h1000_5000) begin
            mem_io_data = o_io_lcd;  // Đọc từ LCD
        end else if (mem_addr >= 32'h1000_3000 && mem_addr < 32'h1000_4000) begin
            mem_io_data = {1'b0, o_io_hex7, 1'b0, o_io_hex6, 1'b0, o_io_hex5, 1'b0, o_io_hex4};  // HEX4-7
        end else if (mem_addr >= 32'h1000_2000 && mem_addr < 32'h1000_3000) begin
            mem_io_data = {1'b0, o_io_hex3, 1'b0, o_io_hex2, 1'b0, o_io_hex1, 1'b0, o_io_hex0};  // HEX0-3
        end else if (mem_addr >= 32'h1000_1000 && mem_addr < 32'h1000_2000) begin
            mem_io_data = o_io_ledg;  // LED xanh
        end else if (mem_addr >= 32'h1000_0000 && mem_addr < 32'h1000_1000) begin
            mem_io_data = o_io_ledr;  // LED đỏ
        end else if (mem_addr >= 32'h1001_0000 && mem_addr < 32'h1001_1000) begin
            mem_io_data = i_io_sw;     // Switches
        end else begin
            mem_io_data = mem_rdata;   // Memory thông thường
        end
    end else begin
        mem_io_data = mem_rdata;
    end
end
```

**Giải thích**:
- **Memory-mapped I/O**: I/O được map vào memory address space
- Đọc từ I/O như đọc từ memory
- Mỗi I/O device có địa chỉ riêng

**Bảng địa chỉ I/O**:
| Địa Chỉ | I/O Device |
|---------|------------|
| 0x1000_0000 - 0x1000_0FFF | LED đỏ (LEDR) |
| 0x1000_1000 - 0x1000_1FFF | LED xanh (LEDG) |
| 0x1000_2000 - 0x1000_2FFF | HEX0-3 |
| 0x1000_3000 - 0x1000_3FFF | HEX4-7 |
| 0x1000_4000 - 0x1000_4FFF | LCD |
| 0x1001_0000 - 0x1001_0FFF | Switches (SW) |

### 6.4. MEM/WB Pipeline Register

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset) begin
        // Reset → clear register
        wb_alu_result <= 32'b0;
        wb_mem_rdata <= 32'b0;
        wb_io_data <= 32'b0;
        // ... clear tất cả signals
    end else if (mem_enable) begin
        // Chuyển dữ liệu sang WB stage
        wb_alu_result <= mem_alu_result;
        wb_mem_rdata <= mem_rdata;
        wb_io_data <= mem_io_data;
        // ... chuyển tất cả signals
        
        // Tính misprediction
        if (mem_is_branch) begin
            wb_mispred <= (mem_predicted_taken != mem_branch_taken);
        end else if (mem_is_ctrl) begin
            // Jump: mispred nếu predicted not-taken (jumps luôn taken)
            wb_mispred <= ~mem_predicted_taken;
        end else begin
            wb_mispred <= 1'b0;
        end
    end
end
```

**Giải thích**:
- Chuyển dữ liệu từ MEM sang WB stage
- Tính misprediction:
  - Branch: mispred nếu `predicted_taken != branch_taken`
  - Jump: mispred nếu `predicted_taken = 0` (jumps luôn taken)

---

## 📝 Phần 7: WB Stage (Write Back)

### 7.1. Write Back MUX

```systemverilog
always_comb begin
    case (wb_mem_to_reg)
        2'b00: wb_reg_wdata = wb_alu_result;  // Ghi từ ALU (ADD, SUB...)
        2'b01: wb_reg_wdata = wb_io_data;      // Ghi từ memory/I/O (LW...)
        2'b10: wb_reg_wdata = wb_pc_plus4;     // Ghi PC+4 (JAL, JALR)
        default: wb_reg_wdata = wb_alu_result;
    endcase
end
```

**Giải thích**:
- Chọn dữ liệu ghi vào thanh ghi:
  - `00`: Từ ALU (kết quả phép toán)
  - `01`: Từ memory/I/O (load instruction)
  - `10`: PC+4 (jump and link)

**Ví dụ**:
- `ADD x1, x2, x3` → `mem_to_reg = 00` → ghi `alu_result`
- `LW x1, 0(x2)` → `mem_to_reg = 01` → ghi `io_data` (từ memory)
- `JAL x1, label` → `mem_to_reg = 10` → ghi `pc_plus4`

### 7.2. Register File Write

Register File được gọi trong ID stage, nhưng ghi từ WB stage:
```systemverilog
register_file u_regfile (
    .we         (wb_reg_write && wb_enable),  // Write enable từ WB
    .addr_rd    (wb_rd_addr),                  // Địa chỉ đích từ WB
    .wdata      (wb_reg_wdata),                 // Dữ liệu từ WB
    // ...
);
```

**Giải thích**:
- Ghi vào thanh ghi tại WB stage
- Dữ liệu có sẵn cho instruction tiếp theo (sau 1 cycle)

---

## 📝 Phần 8: Forwarding Unit (Model 1: Disabled)

### 8.1. Forwarding Logic (Model 1)

```systemverilog
// ============================================
// Forwarding Unit (DISABLED for Model 1)
// ============================================
always_comb begin
    forward_a = 2'b00;  // Luôn dùng từ thanh ghi (KHÔNG forward)
    forward_b = 2'b00;  // Luôn dùng từ thanh ghi (KHÔNG forward)
end
```

**Giải thích**:
- **Model 1**: Forwarding Unit luôn trả về `00`
- Nghĩa là luôn dùng dữ liệu từ thanh ghi (ID/EX register)
- Không forward từ MEM/WB stages

**Kết quả**: Data hazards sẽ gây stall thay vì forward

### 8.2. Forwarding MUX (Vẫn Có, Nhưng Không Dùng)

Forwarding MUX vẫn có trong code, nhưng vì `forward_a/b = 00`, nên luôn chọn input `00` (từ thanh ghi):

```systemverilog
case (forward_a)
    2'b00: forward_rs1_data = ex_rs1_data;      // ← CHỌN NÀY (Model 1)
    2'b01: forward_rs1_data = wb_reg_wdata;     // Không dùng
    2'b10: forward_rs1_data = mem_alu_result;   // Không dùng
endcase
```

**Lý do**: Code structure giống Model 2, dễ chuyển đổi

---

## 📝 Phần 9: Hazard Detection

### 9.1. Load-Use Hazard Detection

```systemverilog
always_comb begin
    stall_if = 1'b0;
    stall_id = 1'b0;
    stall_ex = 1'b0;
    flush_if = 1'b0;
    flush_id = 1'b0;
    flush_ex = 1'b0;
    
    // Load-use hazard: stall nếu load trong EX và lệnh trong ID phụ thuộc
    if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
        // Kiểm tra lệnh trong ID có dùng kết quả load không
        if ((id_rs1_addr == ex_rd_addr && id_rs1_addr != 5'b0 && id_reg_write) ||
            (id_rs2_addr == ex_rd_addr && id_rs2_addr != 5'b0 && (id_mem_write || id_branch))) begin
            stall_if = 1'b1;  // Dừng IF stage
            stall_id = 1'b1;  // Dừng ID stage
            flush_ex = 1'b1;  // Chèn bubble vào EX stage
        end
    end
    // ...
end
```

**Giải thích**:
- **Load-use hazard**: Load instruction cần 2 cycles (MEM + WB) để có dữ liệu
- Nếu lệnh trong ID stage cần dữ liệu từ load đó → **PHẢI STALL**
- **Stall IF, ID**: Dừng 2 stages đầu
- **Flush EX**: Chèn bubble (NOP) vào EX stage

**Ví dụ**:
```
Lệnh 1: LW x1, 0(x2)    (EX stage: đang tính địa chỉ)
Lệnh 2: ADD x3, x1, x4  (ID stage: cần x1)

→ Load-use hazard! → STALL 1 cycle
```

### 9.2. Control Hazard Detection (Misprediction)

```systemverilog
// Control hazard: flush nếu mispredicted branch/jump
if (ex_is_ctrl && ex_enable) begin
    logic actual_taken;
    logic [31:0] actual_target;
    
    if (ex_branch) begin
        actual_taken = ex_branch_taken;
        actual_target = ex_branch_target;
    end else begin
        actual_taken = 1'b1;  // Jumps luôn taken
        actual_target = ex_jump_target;
    end
    
    // Misprediction: predicted != actual
    if (ex_predicted_taken != actual_taken) begin
        flush_if = 1'b1;  // Flush IF stage
        flush_id = 1'b1;  // Flush ID stage
        flush_ex = 1'b1;  // Flush EX stage
        // Correct PC sẽ được set trong cycle tiếp theo
    end
end
```

**Giải thích**:
- **Misprediction**: Dự đoán sai hướng nhảy
- **Flush**: Xóa các lệnh sai trong pipeline
- **Correct PC**: Được set trong cycle tiếp theo (từ `corrected_pc`)

**Ví dụ**:
```
Dự đoán: Branch không nhảy (PC+4)
Thực tế: Branch nhảy (target)

→ Misprediction! → Flush IF, ID, EX
→ Set PC = target trong cycle tiếp theo
```

---

## 📝 Phần 10: I/O Output Handling

### 10.1. I/O Write Logic

```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset) begin
        // Reset → clear tất cả I/O outputs
        o_io_ledr <= 32'b0;
        o_io_ledg <= 32'b0;
        o_io_lcd  <= 32'b0;
        o_io_hex0 <= 7'b0;
        // ... clear tất cả HEX displays
    end else if (mem_mem_write && mem_enable) begin
        // Ghi vào I/O khi có store instruction
        if (mem_addr >= 32'h1000_0000 && mem_addr < 32'h1000_1000) begin
            o_io_ledr <= mem_wdata;  // Ghi vào LED đỏ
        end else if (mem_addr >= 32'h1000_1000 && mem_addr < 32'h1000_2000) begin
            o_io_ledg <= mem_wdata;  // Ghi vào LED xanh
        end else if (mem_addr >= 32'h1000_2000 && mem_addr < 32'h1000_3000) begin
            // HEX0-3: Hỗ trợ byte, halfword, word writes
            case (mem_mem_size)
                3'b000: begin  // Byte write
                    case (mem_addr[1:0])
                        2'b00: o_io_hex0 <= mem_wdata[6:0];
                        2'b01: o_io_hex1 <= mem_wdata[6:0];
                        2'b10: o_io_hex2 <= mem_wdata[6:0];
                        2'b11: o_io_hex3 <= mem_wdata[6:0];
                    endcase
                end
                3'b001: begin  // Halfword write
                    if (mem_addr[1] == 1'b0) begin
                        o_io_hex0 <= mem_wdata[6:0];
                        o_io_hex1 <= mem_wdata[14:8];
                    end else begin
                        o_io_hex2 <= mem_wdata[6:0];
                        o_io_hex3 <= mem_wdata[14:8];
                    end
                end
                3'b010: begin  // Word write
                    o_io_hex0 <= mem_wdata[6:0];
                    o_io_hex1 <= mem_wdata[14:8];
                    o_io_hex2 <= mem_wdata[22:16];
                    o_io_hex3 <= mem_wdata[30:24];
                end
            endcase
        end
        // ... tương tự cho HEX4-7 và LCD
    end
end
```

**Giải thích**:
- Ghi vào I/O khi có store instruction (`mem_mem_write = 1`)
- HEX displays hỗ trợ byte, halfword, và word writes
- Mỗi HEX display: 7 bits (segments a-g)

---

## 📝 Phần 11: Debug Outputs

### 11.1. Debug Signals

```systemverilog
assign o_pc_debug = pc;                    // PC từ IF stage
assign o_insn_vld = wb_enable;             // Instruction valid từ WB stage
assign o_ctrl = wb_is_ctrl && wb_enable;   // Control transfer từ WB stage
assign o_mispred = wb_mispred && wb_enable; // Misprediction từ WB stage
```

**Giải thích**:
- **o_pc_debug**: PC hiện tại (từ IF stage)
- **o_insn_vld**: = 1 khi instruction hợp lệ (đã hoàn thành)
- **o_ctrl**: = 1 khi instruction là branch/jump
- **o_mispred**: = 1 khi branch/jump bị mispredicted

**Dùng cho**: Scoreboard để đếm và thống kê

---

## 🎬 Ví Dụ Tổng Hợp

### Ví Dụ: ADD x1, x2, x3

**Timeline**:

```
Cycle 1 (IF):
  - PC = 0x0000_0000
  - Lấy lệnh "ADD x1, x2, x3" từ IMEM
  - PC_next = 0x0000_0004

Cycle 2 (IF, ID):
  - IF: PC = 0x0000_0004, lấy lệnh tiếp theo
  - ID: Giải mã "ADD x1, x2, x3"
      - rs1 = x2, rs2 = x3
      - Đọc x2 = 10, x3 = 20 từ register file
      - Control Unit: reg_write = 1, alu_op = ADD

Cycle 3 (IF, ID, EX):
  - IF: Lấy lệnh tiếp theo
  - ID: Giải mã lệnh tiếp theo
  - EX: ALU tính x1 = 10 + 20 = 30
      - forward_a = 00 → dùng ex_rs1_data = 10
      - forward_b = 00 → dùng ex_rs2_data = 20

Cycle 4 (IF, ID, EX, MEM):
  - IF: Lấy lệnh tiếp theo
  - ID: Giải mã lệnh tiếp theo
  - EX: (lệnh tiếp theo)
  - MEM: ADD không cần memory, chỉ chuyển kết quả

Cycle 5 (IF, ID, EX, MEM, WB):
  - IF: Lấy lệnh tiếp theo
  - ID: Giải mã lệnh tiếp theo
  - EX: (lệnh tiếp theo)
  - MEM: (lệnh tiếp theo)
  - WB: Ghi x1 = 30 vào register file
```

**Kết quả**: `x1 = 30` ✅

---

## 🔍 Điểm Quan Trọng

### 1. Pipeline Stages

- 5 stages: IF, ID, EX, MEM, WB
- Mỗi stage làm việc độc lập
- Dữ liệu được chuyển qua pipeline registers

### 2. Model 1: Non-Forwarding

- Forwarding Unit luôn trả về `00`
- Data hazards gây stall
- Load-use hazards luôn cần stall

### 3. Branch Prediction

- Two-bit dynamic predictor
- BTB với 256 entries
- Misprediction được phát hiện ở EX stage

### 4. Hazard Detection

- Load-use hazard: Stall 1 cycle
- Control hazard: Flush pipeline khi misprediction

### 5. I/O Mapping

- Memory-mapped I/O
- Hỗ trợ đầy đủ I/O peripherals
- HEX displays hỗ trợ byte/halfword/word writes

---

## 🎓 Kết Luận

File `pipelined.sv` là module chính, kết nối tất cả các module lại với nhau và thực hiện 5-stage pipeline. Module này:
- Thực hiện pipeline với 5 stages
- Xử lý hazards (data hazards, control hazards)
- Branch prediction với BTB + Two-bit predictor
- I/O mapping đầy đủ
- Debug signals cho testbench

**Model 1** (Non-Forwarding) đơn giản hơn Model 2, nhưng performance thấp hơn do nhiều stalls.




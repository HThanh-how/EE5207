# Giải thích Forwarding Mechanism trong Pipelined RISC-V Processor

## 1. Tổng quan về Forwarding

Forwarding (hay Data Forwarding) là kỹ thuật cho phép dữ liệu từ các pipeline stage sau (MEM, WB) được forward trực tiếp về stage trước (EX) để giải quyết data hazards mà không cần stall pipeline.

## 2. Forwarding Unit Logic

### 2.1. Forwarding Signals

Forwarding Unit tạo ra 2 tín hiệu điều khiển 2-bit cho mỗi ALU operand:

- **`forward_a[1:0]`**: Điều khiển MUX cho ALU input A (rs1)
- **`forward_b[1:0]`**: Điều khiển MUX cho ALU input B (rs2)

### 2.2. Forwarding Priority

**Priority: MEM stage > WB stage**

```systemverilog
// Forward from MEM stage (priority cao nhất)
if (mem_reg_write && mem_enable && mem_rd_addr != 5'b0) begin
    if (mem_rd_addr == ex_rs1_addr) begin
        forward_a = 2'b10;  // Forward từ MEM
    end
    if (mem_rd_addr == ex_rs2_addr) begin
        forward_b = 2'b10;  // Forward từ MEM
    end
end

// Forward from WB stage (chỉ khi không forward từ MEM)
if (wb_reg_write && wb_enable && wb_rd_addr != 5'b0) begin
    if (forward_a == 2'b00 && wb_rd_addr == ex_rs1_addr) begin
        forward_a = 2'b01;  // Forward từ WB
    end
    if (forward_b == 2'b00 && wb_rd_addr == ex_rs2_addr) begin
        forward_b = 2'b01;  // Forward từ WB
    end
end
```

**Lý do priority MEM > WB:**
- Dữ liệu từ MEM stage mới hơn (gần EX stage hơn)
- Nếu cả MEM và WB đều có cùng rd_addr, MEM có giá trị đúng nhất

## 3. Forwarding MUX Selection

### 3.1. Forwarding MUX cho rs1 (forward_rs1_data)

```systemverilog
case (forward_a)
    2'b00: forward_rs1_data = ex_rs1_data;        // Không forward, dùng giá trị từ ID/EX
    2'b01: forward_rs1_data = wb_reg_wdata;       // Forward từ WB stage
    2'b10: forward_rs1_data = mem_alu_result;     // Forward từ MEM stage
    default: forward_rs1_data = ex_rs1_data;
endcase
```

### 3.2. Forwarding MUX cho rs2 (forward_rs2_data)

```systemverilog
case (forward_b)
    2'b00: forward_rs2_data = ex_rs2_data;        // Không forward, dùng giá trị từ ID/EX
    2'b01: forward_rs2_data = wb_reg_wdata;       // Forward từ WB stage
    2'b10: forward_rs2_data = mem_alu_result;     // Forward từ MEM stage
    default: forward_rs2_data = ex_rs2_data;
endcase
```

## 4. Forwarding Paths

### 4.1. Forward từ MEM Stage

**Nguồn dữ liệu:** `mem_alu_result` (ALU result từ EX/MEM register)

**Khi nào forward:**
- Instruction trong MEM stage có `mem_reg_write = 1`
- `mem_rd_addr != 0` (không phải x0)
- `mem_rd_addr == ex_rs1_addr` hoặc `mem_rd_addr == ex_rs2_addr`

**Ví dụ:**
```
Cycle 1: ADD x1, x2, x3    (EX stage)
Cycle 2: ADD x4, x1, x5    (ID stage)  <- Cần x1
Cycle 3: ADD x1, x2, x3    (MEM stage) <- x1 đã có trong mem_alu_result
         ADD x4, x1, x5    (EX stage)  <- Forward x1 từ MEM
```

### 4.2. Forward từ WB Stage

**Nguồn dữ liệu:** `wb_reg_wdata` (Writeback data từ MEM/WB register)

**Khi nào forward:**
- Instruction trong WB stage có `wb_reg_write = 1`
- `wb_rd_addr != 0`
- `wb_rd_addr == ex_rs1_addr` hoặc `wb_rd_addr == ex_rs2_addr`
- **VÀ** không có forward từ MEM stage (forward_a/forward_b == 2'b00)

**Ví dụ:**
```
Cycle 1: ADD x1, x2, x3    (MEM stage)
Cycle 2: ADD x1, x2, x3    (WB stage)  <- x1 đã có trong wb_reg_wdata
         ADD x4, x1, x5    (EX stage)  <- Forward x1 từ WB (nếu không có forward từ MEM)
```

## 5. Forwarding cho Branch Instructions

Forwarding cũng được áp dụng cho branch comparison:

```systemverilog
// Branch comparison sử dụng forwarded data
if (ex_branch) begin
    case (ex_funct3)
        3'b000: ex_branch_taken = (forward_rs1_data == forward_rs2_data);
        3'b001: ex_branch_taken = (forward_rs1_data != forward_rs2_data);
        3'b100: ex_branch_taken = ($signed(forward_rs1_data) < $signed(forward_rs2_data));
        // ...
    endcase
end
```

## 6. Forwarding cho Jump Instructions

JALR instruction cũng sử dụng forwarded data:

```systemverilog
assign ex_jump_target = ex_jump ? (ex_pc + ex_imm) : (forward_rs1_data + ex_imm);
```

## 7. So sánh với Hình ảnh

**Hình ảnh mô tả:**
- Forwarding paths từ EX/MEM và MEM/WB về EX stage
- MUXes cho OpA và OpB với inputs: rs1/rs2, from_ex, from_wb
- Forwarding signals điều khiển MUX selection

**Thiết kế thực tế:**
- ✅ Forward từ MEM stage (`mem_alu_result`) - tương ứng "from_ex" trong hình
- ✅ Forward từ WB stage (`wb_reg_wdata`) - tương ứng "from_wb" trong hình
- ✅ Forwarding MUXes cho rs1 và rs2
- ✅ Forwarding signals (forward_a, forward_b) điều khiển MUXes
- ✅ Priority: MEM > WB

**Kết luận:** Hình ảnh **ĐÚNG** với thiết kế forwarding của chúng ta!

## 8. Điểm khác biệt với Non-Forwarding

**Non-Forwarding:**
- Không có Forwarding Unit
- Data hazards được giải quyết bằng pipeline stall
- Performance thấp hơn (nhiều bubbles)

**Forwarding:**
- Có Forwarding Unit
- Hầu hết data hazards được giải quyết bằng forwarding
- Chỉ load-use hazards cần stall
- Performance cao hơn

## 9. Load-Use Hazard (Không thể forward)

Load-use hazard không thể forward vì:
- Load instruction trong EX stage chưa có dữ liệu từ memory
- Dữ liệu chỉ có sau khi load hoàn thành ở MEM stage
- Cần stall 1 cycle

```systemverilog
// Load-use hazard detection
if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
    if ((id_rs1_addr == ex_rd_addr && id_reg_write) ||
        (id_rs2_addr == ex_rd_addr && (id_mem_write || id_branch))) begin
        stall_if = 1'b1;
        stall_id = 1'b1;
        flush_ex = 1'b1;  // Insert bubble
    end
end
```

## 10. Tóm tắt

**Forwarding Mechanism:**
1. Forwarding Unit so sánh `ex_rs1_addr`, `ex_rs2_addr` với `mem_rd_addr`, `wb_rd_addr`
2. Tạo `forward_a` và `forward_b` signals
3. Forwarding MUXes chọn dữ liệu từ:
   - ID/EX register (00): Giá trị gốc từ register file
   - MEM stage (10): `mem_alu_result` (priority cao)
   - WB stage (01): `wb_reg_wdata` (priority thấp)
4. Forwarded data được sử dụng cho ALU, branch comparison, và jump target calculation

**Lợi ích:**
- Giảm pipeline stalls
- Tăng performance (IPC)
- Giải quyết hầu hết data hazards





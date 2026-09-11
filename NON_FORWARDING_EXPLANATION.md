# Giải thích Non-Forwarding Mechanism trong Pipelined RISC-V Processor

## 1. Tổng quan về Non-Forwarding

Non-Forwarding (hay No Forwarding) là kiến trúc pipeline **không có Forwarding Unit**. Khi data hazards xảy ra, pipeline phải **stall** (dừng lại) cho đến khi dữ liệu có sẵn trong register file. Điều này dẫn đến nhiều pipeline bubbles và performance thấp hơn so với forwarding architecture.

## 2. Tại sao cần Non-Forwarding?

Non-Forwarding được sử dụng để:
- **So sánh performance** với Forwarding architecture
- **Hiểu tác động của forwarding** lên pipeline performance
- **Baseline implementation** trước khi thêm forwarding
- **Educational purposes** để minh họa data hazards và stall mechanism

## 3. Forwarding Unit (DISABLED)

### 3.1. Forwarding Signals luôn bằng 0

Trong Non-Forwarding architecture, Forwarding Unit **luôn trả về `2'b00`** (không forward):

```systemverilog
// Forwarding Unit (DISABLED for Model 1)
always_comb begin
    forward_a = 2'b00;  // Always use register file (no forwarding)
    forward_b = 2'b00;  // Always use register file (no forwarding)
end
```

**Kết quả:**
- ALU luôn sử dụng dữ liệu từ register file (ID/EX register)
- Không forward từ MEM hoặc WB stages
- Mọi data hazard đều cần stall

### 3.2. Forwarding MUX Selection

Mặc dù Forwarding MUXes vẫn có trong code, chúng luôn chọn input `00`:

```systemverilog
case (forward_a)
    2'b00: forward_rs1_data = ex_rs1_data;        // Luôn chọn input này
    2'b01: forward_rs1_data = wb_reg_wdata;      // Không bao giờ được chọn
    2'b10: forward_rs1_data = mem_alu_result;     // Không bao giờ được chọn
    default: forward_rs1_data = ex_rs1_data;
endcase
```

**Lý do giữ Forwarding MUXes:**
- Code structure giống Model 2 (Forwarding)
- Dễ dàng chuyển đổi sang Forwarding bằng cách enable Forwarding Unit
- Không cần thay đổi ALU input selection logic

## 4. Data Hazards và Stall Mechanism

### 4.1. Data Hazard là gì?

Data hazard xảy ra khi instruction cần dữ liệu từ instruction trước đó, nhưng dữ liệu chưa có sẵn trong register file.

**Ví dụ:**
```
ADD x1, x2, x3    # Instruction 1: Tính x1 = x2 + x3
ADD x4, x1, x5    # Instruction 2: Cần x1 từ instruction 1
```

### 4.2. Data Hazard trong Non-Forwarding

**Vấn đề:** Khi instruction trong EX stage cần dữ liệu từ instruction trong MEM hoặc WB stage, dữ liệu chưa có trong register file.

**Giải pháp:** Stall pipeline cho đến khi dữ liệu có trong register file.

**Ví dụ chi tiết:**
```
Cycle 1:
  IF: ADD x4, x1, x5    (Fetch)
  ID: (empty)
  EX: ADD x1, x2, x3    (Tính x1)
  MEM: (previous instruction)
  WB: (previous instruction)

Cycle 2:
  IF: ADD x4, x1, x5    (Stall - không fetch mới)
  ID: ADD x4, x1, x5    (Decode - cần x1, nhưng x1 chưa có trong register file)
  EX: (BUBBLE - flush từ hazard detection)
  MEM: ADD x1, x2, x3   (x1 đang được tính)
  WB: (previous instruction)

Cycle 3:
  IF: ADD x4, x1, x5    (Stall - không fetch mới)
  ID: ADD x4, x1, x5    (Decode - vẫn cần x1)
  EX: (BUBBLE)
  MEM: ADD x1, x2, x3   (x1 đã có trong mem_alu_result, nhưng chưa write vào register file)
  WB: ADD x1, x2, x3    (x1 sắp được write vào register file)

Cycle 4:
  IF: (next instruction)  (Continue - không stall nữa)
  ID: ADD x4, x1, x5    (Decode - x1 đã có trong register file)
  EX: ADD x4, x1, x5    (Execute - sử dụng x1 từ register file)
  MEM: ADD x1, x2, x3   (x1 đã write vào register file)
  WB: (next instruction)
```

**Kết quả:** 2 stall cycles để đợi x1 có trong register file.

### 4.3. So sánh với Forwarding

**Với Forwarding:**
```
Cycle 1: ADD x1 (EX)
Cycle 2: ADD x4 (ID)
Cycle 3: ADD x1 (MEM), ADD x4 (EX) → Forward x1 từ MEM
→ Total: 3 cycles (0 stalls)
```

**Với Non-Forwarding:**
```
Cycle 1: ADD x1 (EX)
Cycle 2: ADD x4 (ID) → Stall (wait for x1)
Cycle 3: ADD x1 (MEM), ADD x4 (ID) → Stall
Cycle 4: ADD x1 (WB), ADD x4 (ID) → Continue (x1 có trong register file)
Cycle 5: ADD x4 (EX)
→ Total: 5 cycles (2 stalls)
```

## 5. Load-Use Hazard

### 5.1. Load-Use Hazard là gì?

Load-Use Hazard là trường hợp đặc biệt của data hazard:
- Load instruction cần **2 cycles** để có dữ liệu (EX → MEM → WB)
- Instruction tiếp theo cần dữ liệu từ load instruction
- **Không thể forward** vì dữ liệu chỉ có sau khi load hoàn thành ở MEM stage

### 5.2. Load-Use Hazard Detection

```systemverilog
// Load-use hazard: stall if load in EX and dependent instruction in ID
if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
    // Check if ID stage instruction uses the load result
    if ((id_rs1_addr == ex_rd_addr && id_rs1_addr != 5'b0 && id_reg_write) ||
        (id_rs2_addr == ex_rd_addr && id_rs2_addr != 5'b0 && (id_mem_write || id_branch))) begin
        stall_if = 1'b1;  // Stall IF stage
        stall_id = 1'b1;  // Stall ID stage
        flush_ex = 1'b1;  // Insert bubble in EX stage
    end
end
```

**Ví dụ:**
```
Cycle 1:
  EX: LW x1, 0(x2)      (Load x1 từ memory)
  ID: ADD x3, x1, x4    (Cần x1)  ← LOAD-USE HAZARD!

Cycle 2:
  IF: (Stall)
  ID: ADD x3, x1, x4    (Stall - vẫn cần x1)
  EX: (BUBBLE - flush)
  MEM: LW x1, 0(x2)     (Đọc từ memory)

Cycle 3:
  IF: (Stall)
  ID: ADD x3, x1, x4    (Stall - vẫn cần x1)
  EX: (BUBBLE)
  MEM: LW x1, 0(x2)     (x1 đã có trong mem_rdata)
  WB: LW x1, 0(x2)      (x1 sắp được write vào register file)

Cycle 4:
  IF: (next instruction)  (Continue)
  ID: ADD x3, x1, x4    (x1 đã có trong register file)
  EX: ADD x3, x1, x4    (Execute)
  MEM: (next instruction)
  WB: LW x1, 0(x2)      (x1 đã write vào register file)
```

**Kết quả:** 1 stall cycle (bắt buộc, không thể forward).

### 5.3. Tại sao Load-Use Hazard không thể Forward?

1. **Load instruction trong EX stage:**
   - Chỉ có address (từ ALU)
   - Dữ liệu chưa có (chưa đọc từ memory)

2. **Load instruction trong MEM stage:**
   - Dữ liệu mới được đọc từ memory
   - Dữ liệu có trong `mem_rdata`
   - Nhưng instruction cần dữ liệu đã ở ID stage (quá muộn để forward)

3. **Giải pháp duy nhất:** Stall 1 cycle để đợi dữ liệu có trong register file.

## 6. Control Hazard

### 6.1. Control Hazard là gì?

Control hazard xảy ra khi branch/jump instruction được mispredicted, dẫn đến wrong-path instructions trong pipeline.

### 6.2. Control Hazard Detection

```systemverilog
// Control hazard: flush if mispredicted branch/jump
if (ex_is_ctrl && ex_enable) begin
    logic actual_taken;
    logic [31:0] actual_target;
    
    if (ex_branch) begin
        actual_taken = ex_branch_taken;
        actual_target = ex_branch_target;
    end else begin
        actual_taken = 1'b1;  // Jumps always taken
        actual_target = ex_jump_target;
    end
    
    // Misprediction: predicted != actual
    if (ex_predicted_taken != actual_taken) begin
        flush_if = 1'b1;  // Flush IF stage
        flush_id = 1'b1;  // Flush ID stage
        flush_ex = 1'b1;  // Flush EX stage
    end
end
```

**Ví dụ:**
```
Cycle 1:
  IF: BEQ x1, x2, target    (Predict: taken)
  ID: (next instruction)
  EX: (previous instruction)

Cycle 2:
  IF: (instruction at target)  (Fetch từ predicted target)
  ID: BEQ x1, x2, target
  EX: (previous instruction)

Cycle 3:
  IF: (instruction at target+4)
  ID: (instruction at target)
  EX: BEQ x1, x2, target    (Resolve: actual = not taken)  ← MISPREDICTION!

Cycle 4:
  IF: (instruction at PC+4)  (Flush và fetch đúng PC)
  ID: (BUBBLE - flush)
  EX: (BUBBLE - flush)
  MEM: (previous instruction)
  WB: (previous instruction)
```

**Kết quả:** 2-3 cycles bị mất do wrong-path instructions.

## 7. Stall và Flush Signals

### 7.1. Stall Signals

**Stall** dừng pipeline stages để đợi dữ liệu:

- **`stall_if`**: Stall IF stage (không fetch instruction mới)
- **`stall_id`**: Stall ID stage (không decode instruction mới)
- **`stall_ex`**: Stall EX stage (ít khi dùng, thường flush thay vì stall)

**Implementation:**
```systemverilog
assign if_enable = ~stall_if;  // IF stage chỉ enable khi không stall

always_ff @(posedge i_clk) begin
    if (~i_reset || if_flush) begin
        // Flush pipeline register
    end else if (if_enable && ~stall_id) begin
        // Update pipeline register
    end
end
```

### 7.2. Flush Signals

**Flush** xóa wrong-path instructions trong pipeline:

- **`flush_if`**: Flush IF/ID register
- **`flush_id`**: Flush ID/EX register
- **`flush_ex`**: Flush EX/MEM register (insert bubble)

**Implementation:**
```systemverilog
always_ff @(posedge i_clk) begin
    if (~i_reset || flush_id) begin
        ex_pc <= 32'b0;
        ex_rs1_data <= 32'b0;
        // ... reset all ID/EX register fields
        ex_enable <= 1'b0;  // Mark as invalid (bubble)
    end else if (~stall_ex && id_enable) begin
        // Normal update
    end
end
```

## 8. Performance Impact

### 8.1. IPC (Instructions Per Cycle)

**Non-Forwarding:**
- IPC thấp hơn do nhiều stall cycles
- Nhiều pipeline bubbles
- Performance phụ thuộc vào instruction sequence

**Ví dụ:**
```
Program: ADD x1, x2, x3; ADD x4, x1, x5; ADD x6, x4, x7

Non-Forwarding:
- Cycle 1: ADD x1 (EX)
- Cycle 2: ADD x4 (ID) → Stall (wait for x1)
- Cycle 3: ADD x4 (ID) → Stall
- Cycle 4: ADD x4 (EX), ADD x6 (ID) → Stall (wait for x4)
- Cycle 5: ADD x6 (ID) → Stall
- Cycle 6: ADD x6 (EX)
→ Total: 6 cycles, IPC ≈ 0.5

Forwarding:
- Cycle 1: ADD x1 (EX)
- Cycle 2: ADD x4 (ID)
- Cycle 3: ADD x1 (MEM), ADD x4 (EX) → Forward x1
- Cycle 4: ADD x4 (MEM), ADD x6 (ID)
- Cycle 5: ADD x4 (WB), ADD x6 (EX) → Forward x4
- Cycle 6: ADD x6 (MEM)
→ Total: 6 cycles, IPC ≈ 0.5 (trong trường hợp này, forwarding không giúp nhiều vì có 2 dependencies liên tiếp)
```

### 8.2. Stall Cycles

**Data Hazards:**
- **EX → ID dependency**: 1-2 stall cycles
- **MEM → ID dependency**: 1 stall cycle
- **WB → ID dependency**: 0 stall cycles (dữ liệu đã có trong register file)

**Load-Use Hazards:**
- **Luôn cần 1 stall cycle** (bắt buộc)

**Control Hazards:**
- **Flush** (không stall, nhưng mất cycles do wrong-path)

### 8.3. So sánh với Forwarding

| Metric | Non-Forwarding | Forwarding |
|--------|----------------|------------|
| **Data Hazard Stalls** | Nhiều (1-2 cycles) | Ít (0 cycles, chỉ load-use) |
| **Load-Use Stalls** | 1 cycle | 1 cycle (giống nhau) |
| **IPC** | Thấp hơn | Cao hơn |
| **Hardware Complexity** | Đơn giản hơn | Phức tạp hơn |
| **Power Consumption** | Thấp hơn (ít logic) | Cao hơn (forwarding logic) |

## 9. Code Structure

### 9.1. Forwarding Unit (Disabled)

```systemverilog
// Forwarding Unit (DISABLED for Model 1)
always_comb begin
    forward_a = 2'b00;  // Always use register file (no forwarding)
    forward_b = 2'b00;  // Always use register file (no forwarding)
end
```

### 9.2. Hazard Detection (Simplified)

```systemverilog
// Hazard Detection Unit (Model 1: No Forwarding)
always_comb begin
    stall_if = 1'b0;
    stall_id = 1'b0;
    stall_ex = 1'b0;
    flush_if = 1'b0;
    flush_id = 1'b0;
    flush_ex = 1'b0;
    
    // Load-use hazard: stall if load in EX and dependent instruction in ID
    if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
        if ((id_rs1_addr == ex_rd_addr && id_reg_write) ||
            (id_rs2_addr == ex_rd_addr && (id_mem_write || id_branch))) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;  // Insert bubble
        end
    end
    
    // Control hazard: flush if mispredicted branch/jump
    if (ex_is_ctrl && ex_enable) begin
        // ... misprediction detection ...
        if (misprediction) begin
            flush_if = 1'b1;
            flush_id = 1'b1;
            flush_ex = 1'b1;
        end
    end
end
```

**Lưu ý:** Non-Forwarding chỉ detect load-use hazards và control hazards. Các data hazards khác được "giải quyết" bằng cách đợi dữ liệu có trong register file (không cần detect vì không có forwarding).

## 10. Tóm tắt

### Non-Forwarding Mechanism:

1. **Forwarding Unit luôn trả về `2'b00`** (không forward)
2. **ALU luôn sử dụng dữ liệu từ register file** (ID/EX register)
3. **Data hazards được giải quyết bằng stall** (đợi dữ liệu có trong register file)
4. **Load-use hazards luôn cần 1 stall cycle** (bắt buộc)
5. **Control hazards được giải quyết bằng flush** (xóa wrong-path instructions)

### Lợi ích:
- ✅ Hardware đơn giản hơn (không có forwarding logic)
- ✅ Power consumption thấp hơn
- ✅ Dễ hiểu và debug

### Nhược điểm:
- ❌ Performance thấp hơn (nhiều stalls)
- ❌ IPC thấp hơn
- ❌ Không tận dụng được pipeline hiệu quả

### Khi nào dùng Non-Forwarding:
- So sánh performance với Forwarding
- Baseline implementation
- Educational purposes
- Low-power applications (nếu performance không quan trọng)

## 11. Kết luận

Non-Forwarding architecture là foundation tốt để hiểu pipeline hazards và stall mechanism. Mặc dù performance thấp hơn Forwarding, nhưng nó đơn giản hơn và là bước đầu quan trọng trong việc thiết kế pipelined processor. So sánh giữa Non-Forwarding và Forwarding giúp đánh giá tác động của forwarding mechanism lên pipeline performance.





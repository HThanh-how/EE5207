# So Sánh Forwarding vs Non-Forwarding

## 📋 Tổng Quan

Đây là tài liệu giải thích **sự khác biệt chính** giữa Model 1 (Non-Forwarding) và Model 2 (Forwarding) trong code.

## 🎯 Sự Khác Biệt Chính

### Điểm Khác Biệt Duy Nhất: Forwarding Unit

**Model 1 (Non-Forwarding)** và **Model 2 (Forwarding)** chỉ khác nhau ở **Forwarding Unit logic**. Tất cả các phần khác đều giống nhau!

---

## 📝 Phần 1: Forwarding Unit - Code So Sánh

### Model 1: Non-Forwarding (KHÔNG Forward)

```systemverilog
// ============================================
// Forwarding Unit (DISABLED for Model 1)
// ============================================
// Model 1: No forwarding - always use register file data
// Data hazards will cause stalls instead
always_comb begin
    forward_a = 2'b00;  // Luôn dùng từ thanh ghi (KHÔNG forward)
    forward_b = 2'b00;  // Luôn dùng từ thanh ghi (KHÔNG forward)
end
```

**Giải thích**:
- `forward_a` và `forward_b` **LUÔN** = `00`
- Nghĩa là: **LUÔN** dùng dữ liệu từ thanh ghi (ID/EX register)
- **KHÔNG BAO GIỜ** forward từ MEM hoặc WB stage

### Model 2: Forwarding (CÓ Forward)

```systemverilog
// ============================================
// Forwarding Unit
// ============================================
always_comb begin
    forward_a = 2'b00;  // Mặc định: dùng từ thanh ghi
    forward_b = 2'b00;
    
    // Forward từ MEM stage (ưu tiên cao nhất - dữ liệu mới nhất)
    if (mem_reg_write && mem_enable && mem_rd_addr != 5'b0) begin
        if (mem_rd_addr == ex_rs1_addr) begin
            forward_a = 2'b10;  // Forward từ MEM
        end
        if (mem_rd_addr == ex_rs2_addr) begin
            forward_b = 2'b10;  // Forward từ MEM
        end
    end
    
    // Forward từ WB stage (nếu không forward từ MEM)
    if (wb_reg_write && wb_enable && wb_rd_addr != 5'b0) begin
        if (forward_a == 2'b00 && wb_rd_addr == ex_rs1_addr) begin
            forward_a = 2'b01;  // Forward từ WB
        end
        if (forward_b == 2'b00 && wb_rd_addr == ex_rs2_addr) begin
            forward_b = 2'b01;  // Forward từ WB
        end
    end
end
```

**Giải thích**:
- Kiểm tra **MEM stage trước** (ưu tiên cao)
- Kiểm tra **WB stage sau** (nếu không forward từ MEM)
- Forward khi: địa chỉ thanh ghi đích (`mem_rd_addr` hoặc `wb_rd_addr`) trùng với địa chỉ thanh ghi nguồn (`ex_rs1_addr` hoặc `ex_rs2_addr`)

---

## 📝 Phần 2: Forwarding MUX - Giống Nhau

Cả 2 model đều có **Forwarding MUX** giống hệt nhau:

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

**Khác biệt**:
- **Model 1**: `forward_a/b` luôn = `00` → luôn chọn `ex_rs1_data/ex_rs2_data` (từ thanh ghi)
- **Model 2**: `forward_a/b` có thể = `01` hoặc `10` → có thể chọn `wb_reg_wdata` hoặc `mem_alu_result` (forward)

---

## 📝 Phần 3: Hazard Detection - Khác Nhau Một Chút

### Model 1: Chỉ Stall Cho Load-Use Hazard

```systemverilog
// ============================================
// Hazard Detection Unit (Model 1: No Forwarding)
// ============================================
always_comb begin
    stall_if = 1'b0;
    stall_id = 1'b0;
    stall_ex = 1'b0;
    flush_if = 1'b0;
    flush_id = 1'b0;
    flush_ex = 1'b0;
    
    // Load-use hazard: stall nếu load trong EX và lệnh trong ID phụ thuộc
    if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
        if ((id_rs1_addr == ex_rd_addr && id_rs1_addr != 5'b0 && id_reg_write) ||
            (id_rs2_addr == ex_rd_addr && id_rs2_addr != 5'b0 && (id_mem_write || id_branch))) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;  // Insert bubble
        end
    end
    
    // Control hazard: flush nếu mispredicted branch/jump
    if (ex_is_ctrl && ex_enable) begin
        // ... (giống Model 2)
    end
end
```

**Giải thích**:
- **Chỉ** stall cho load-use hazard
- Các data hazard khác (ADD, SUB...) **KHÔNG** được detect → pipeline tự nhiên đợi (vì không forward)

### Model 2: Cũng Chỉ Stall Cho Load-Use Hazard

```systemverilog
// ============================================
// Hazard Detection Unit
// ============================================
always_comb begin
    stall_if = 1'b0;
    stall_id = 1'b0;
    stall_ex = 1'b0;
    flush_if = 1'b0;
    flush_id = 1'b0;
    flush_ex = 1'b0;
    
    // Load-use hazard: stall nếu load trong EX và lệnh trong ID phụ thuộc
    if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
        if ((id_rs1_addr == ex_rd_addr && id_reg_write) ||
            (id_rs2_addr == ex_rd_addr && (id_mem_write || id_branch))) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;  // Insert bubble
        end
    end
    
    // Control hazard: flush nếu mispredicted branch/jump
    if (ex_is_ctrl && ex_enable) begin
        // ... (giống Model 1)
    end
end
```

**Giải thích**:
- **Cũng** chỉ stall cho load-use hazard
- Các data hazard khác được **forward** → không cần stall

**Khác biệt nhỏ**: Model 1 có thêm check `id_rs1_addr != 5'b0` và `id_rs2_addr != 5'b0` (an toàn hơn, nhưng không cần thiết vì x0 luôn = 0)

---

## 🎬 Ví Dụ Cụ Thể: ADD x1, x2, x3 → ADD x4, x1, x5

### Scenario

```
Lệnh 1: ADD x1, x2, x3    (x1 = x2 + x3)
Lệnh 2: ADD x4, x1, x5    (x4 = x1 + x5, CẦN x1 từ lệnh 1!)
```

**Giả sử**: `x2 = 10`, `x3 = 20`, `x5 = 5`

### Model 1: Non-Forwarding

```
Cycle 1:
  Lệnh 1 - IF: Lấy lệnh "ADD x1, x2, x3"

Cycle 2:
  Lệnh 1 - ID: Giải mã, đọc x2=10, x3=20
  Lệnh 2 - IF: Lấy lệnh "ADD x4, x1, x5"

Cycle 3:
  Lệnh 1 - EX: ALU tính x1 = 10 + 20 = 30
              forward_a = 00 → dùng ex_rs1_data = 10
              forward_b = 00 → dùng ex_rs2_data = 20
  Lệnh 2 - ID: Giải mã, cần đọc x1 từ register file
              ❌ VẤN ĐỀ: x1 chưa có trong register file (vẫn đang ở EX stage)!
              → Đọc được giá trị CŨ của x1 (hoặc 0 nếu chưa từng ghi)

Cycle 4:
  Lệnh 1 - MEM: Chuyển kết quả x1 = 30
  Lệnh 2 - ID: Vẫn cần x1, nhưng x1 vẫn chưa có trong register file
              → Đọc được giá trị CŨ của x1

Cycle 5:
  Lệnh 1 - WB: ✅ Ghi x1 = 30 vào register file (BÂY GIỜ MỚI CÓ!)
  Lệnh 2 - ID: ✅ Bây giờ mới đọc được x1 = 30 từ register file

Cycle 6:
  Lệnh 2 - EX: ALU tính x4 = 30 + 5 = 35
              forward_a = 00 → dùng ex_rs1_data = 30 (từ register file)
              forward_b = 00 → dùng ex_rs2_data = 5
```

**Kết quả**: 
- `x1 = 30` ✅
- `x4 = 35` ✅ (nhưng mất 2 cycles để đợi x1 có trong register file)

**Vấn đề**: Nếu lệnh 2 đọc x1 ở cycle 3-4, sẽ đọc được giá trị **SAI** (giá trị cũ)!

**Giải pháp trong thực tế**: Pipeline sẽ **STALL** để đợi x1 có trong register file (nhưng code Model 1 không có logic này, nên có thể có bug!)

### Model 2: Forwarding

```
Cycle 1:
  Lệnh 1 - IF: Lấy lệnh "ADD x1, x2, x3"

Cycle 2:
  Lệnh 1 - ID: Giải mã, đọc x2=10, x3=20
  Lệnh 2 - IF: Lấy lệnh "ADD x4, x1, x5"

Cycle 3:
  Lệnh 1 - EX: ALU tính x1 = 10 + 20 = 30
              forward_a = 00 → dùng ex_rs1_data = 10
              forward_b = 00 → dùng ex_rs2_data = 20
  Lệnh 2 - ID: Giải mã, cần đọc x1

Cycle 4:
  Lệnh 1 - MEM: ✅ x1 = 30 (đã có kết quả)
  Lệnh 2 - EX: ALU tính x4 = x1 + x5
              Forwarding Unit kiểm tra:
                - mem_rd_addr = 1 (x1)
                - ex_rs1_addr = 1 (x1) ← TRÙNG!
                → forward_a = 10 (forward từ MEM)
              forward_rs1_data = mem_alu_result = 30 ✅
              forward_b = 00 → dùng ex_rs2_data = 5
              → Tính x4 = 30 + 5 = 35 ✅

Cycle 5:
  Lệnh 1 - WB: Ghi x1 = 30 vào register file
  Lệnh 2 - MEM: Chuyển kết quả x4 = 35
```

**Kết quả**: 
- `x1 = 30` ✅
- `x4 = 35` ✅
- **KHÔNG CẦN STALL!** Forward từ MEM stage → nhanh hơn!

---

## 📊 Bảng So Sánh

| Đặc Điểm | Model 1 (Non-Forwarding) | Model 2 (Forwarding) |
|----------|-------------------------|---------------------|
| **Forwarding Unit** | Luôn trả về `00` | Kiểm tra và forward từ MEM/WB |
| **forward_a/b** | Luôn = `00` | Có thể = `00`, `01`, hoặc `10` |
| **Data Hazard** | ❌ Không forward → Stall hoặc đọc giá trị sai | ✅ Forward → Không cần stall |
| **Load-Use Hazard** | ✅ Stall 1 cycle | ✅ Stall 1 cycle (bắt buộc) |
| **Performance** | ❌ Thấp (nhiều stall) | ✅ Cao (ít stall) |
| **Độ phức tạp** | ✅ Đơn giản | ❌ Phức tạp hơn |

---

## 🔍 Code So Sánh Chi Tiết

### Forwarding Unit Logic

#### Model 1:
```systemverilog
always_comb begin
    forward_a = 2'b00;  // Luôn = 00
    forward_b = 2'b00;  // Luôn = 00
end
```
**3 dòng code** - Đơn giản!

#### Model 2:
```systemverilog
always_comb begin
    forward_a = 2'b00;
    forward_b = 2'b00;
    
    // Forward từ MEM stage (ưu tiên cao)
    if (mem_reg_write && mem_enable && mem_rd_addr != 5'b0) begin
        if (mem_rd_addr == ex_rs1_addr) begin
            forward_a = 2'b10;
        end
        if (mem_rd_addr == ex_rs2_addr) begin
            forward_b = 2'b10;
        end
    end
    
    // Forward từ WB stage (nếu không forward từ MEM)
    if (wb_reg_write && wb_enable && wb_rd_addr != 5'b0) begin
        if (forward_a == 2'b00 && wb_rd_addr == ex_rs1_addr) begin
            forward_a = 2'b01;
        end
        if (forward_b == 2'b00 && wb_rd_addr == ex_rs2_addr) begin
            forward_b = 2'b01;
        end
    end
end
```
**~20 dòng code** - Phức tạp hơn!

---

## 🎯 Tóm Tắt

### Sự Khác Biệt Duy Nhất:

**Model 1 (Non-Forwarding)**:
```systemverilog
forward_a = 2'b00;  // Luôn dùng từ thanh ghi
forward_b = 2'b00;  // Luôn dùng từ thanh ghi
```

**Model 2 (Forwarding)**:
```systemverilog
// Kiểm tra và forward từ MEM/WB stages
if (mem_rd_addr == ex_rs1_addr) forward_a = 2'b10;  // Forward từ MEM
if (wb_rd_addr == ex_rs1_addr) forward_a = 2'b01;  // Forward từ WB
```

### Kết Quả:

- **Model 1**: Data hazards gây stall hoặc đọc giá trị sai → Performance thấp
- **Model 2**: Data hazards được forward → Không cần stall → Performance cao

### Điểm Giống Nhau:

- ✅ Cả 2 đều có Forwarding MUX (code giống hệt)
- ✅ Cả 2 đều stall cho load-use hazard
- ✅ Cả 2 đều có branch prediction
- ✅ Cả 2 đều có I/O mapping
- ✅ Tất cả các phần khác đều giống nhau!

---

## 🎓 Kết Luận

**Sự khác biệt duy nhất** giữa Model 1 và Model 2 là **Forwarding Unit logic**:
- **Model 1**: Luôn trả về `00` (không forward)
- **Model 2**: Kiểm tra và forward từ MEM/WB stages

Điều này dẫn đến:
- **Model 1**: Nhiều stalls → Performance thấp
- **Model 2**: Ít stalls → Performance cao

**Tất cả các phần khác đều giống nhau!** 🎯




# Giải Thích Siêu Dễ Hiểu - Model 1 và Model 2

## Mục Lục
1. [Model 1: Non-Forwarding (Không Chuyển Dữ Liệu)](#model1)
2. [Model 2: Forwarding (Có Chuyển Dữ Liệu)](#model2)
3. [So Sánh Trực Quan](#so-sánh)

---

# Model 1: Non-Forwarding (Không Chuyển Dữ Liệu) {#model1}

## 🎯 Model 1 Là Gì?

**Model 1** giống như một nhà máy **cẩn thận nhưng chậm**:
- Mỗi công nhân chỉ làm việc khi có đầy đủ nguyên liệu
- Nếu thiếu nguyên liệu, phải **DỪNG LẠI** và đợi
- Đảm bảo không có lỗi, nhưng mất thời gian

## 🔍 Cách Hoạt Động

### Ví Dụ 1: Hai Lệnh Đơn Giản

Giả sử bạn có 2 lệnh:
```
Lệnh 1: ADD x1, x2, x3    (Tính x1 = x2 + x3)
Lệnh 2: ADD x4, x1, x5    (Tính x4 = x1 + x5, CẦN x1 từ lệnh 1!)
```

**Vấn đề**: Lệnh 2 cần x1, nhưng x1 chỉ có sau khi lệnh 1 hoàn thành!

### Timeline Chi Tiết (Model 1):

```
🕐 Cycle 1:
   Lệnh 1 - IF:  Lấy lệnh "ADD x1, x2, x3" từ bộ nhớ
   Lệnh 2 -     (chưa có)

🕑 Cycle 2:
   Lệnh 1 - ID:  Giải mã lệnh, đọc x2=10, x3=20 từ thanh ghi
   Lệnh 2 - IF:  Lấy lệnh "ADD x4, x1, x5" từ bộ nhớ

🕒 Cycle 3:
   Lệnh 1 - EX:  ALU tính x1 = 10 + 20 = 30 (kết quả chưa ghi vào thanh ghi!)
   Lệnh 2 - ID:  Giải mã lệnh, cần đọc x1 từ thanh ghi
                 ❌ VẤN ĐỀ: x1 chưa có trong thanh ghi (vẫn đang ở EX stage)!
                 🛑 STALL! Dừng pipeline, đợi x1 có trong thanh ghi

🕓 Cycle 4:
   Lệnh 1 - MEM: Lệnh ADD không cần bộ nhớ, chỉ chuyển kết quả
                 (x1 = 30 vẫn chưa ghi vào thanh ghi)
   Lệnh 2 - ID:  🛑 VẪN STALL! Vẫn đợi x1
                 (Insert bubble vào EX - không làm gì)

🕔 Cycle 5:
   Lệnh 1 - WB:  ✅ Ghi x1 = 30 vào thanh ghi (BÂY GIỜ MỚI CÓ!)
   Lệnh 2 - ID:  ✅ Bây giờ mới đọc được x1 = 30 từ thanh ghi
                 (Bubble trong EX - không làm gì)

🕕 Cycle 6:
   Lệnh 1 -      (Đã xong)
   Lệnh 2 - EX:  ALU tính x4 = 30 + x5
   (Lệnh tiếp theo - ID)

🕖 Cycle 7:
   Lệnh 2 - MEM: Chuyển kết quả
   (Lệnh tiếp theo - EX)

🕗 Cycle 8:
   Lệnh 2 - WB:  Ghi x4 vào thanh ghi
   (Lệnh tiếp theo - MEM)
```

**Tổng kết**: 
- Lệnh 1: 5 cycles (bình thường)
- Lệnh 2: 5 cycles + 2 cycles stall = **7 cycles**
- **Tổng: 8 cycles** (mất 2 cycles để đợi!)

### Code Thực Tế - Forwarding Unit (Model 1):

```systemverilog
// ============================================
// Forwarding Unit (DISABLED for Model 1)
// ============================================
always_comb begin
    forward_a = 2'b00;  // Luôn dùng dữ liệu từ thanh ghi (KHÔNG forward)
    forward_b = 2'b00;  // Luôn dùng dữ liệu từ thanh ghi (KHÔNG forward)
end
```

**Giải thích**:
- `forward_a = 00` nghĩa là: "Luôn lấy dữ liệu từ thanh ghi, không lấy từ stage khác"
- Model 1 **KHÔNG BAO GIỜ** forward dữ liệu
- Nếu thiếu dữ liệu → **PHẢI ĐỢI** cho đến khi có trong thanh ghi

### Code Thực Tế - Hazard Detection (Model 1):

```systemverilog
// Load-use hazard: stall nếu load trong EX và lệnh trong ID phụ thuộc
if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
    if ((id_rs1_addr == ex_rd_addr && id_reg_write) ||
        (id_rs2_addr == ex_rd_addr && (id_mem_write || id_branch))) begin
        stall_if = 1'b1;  // Dừng IF stage
        stall_id = 1'b1;  // Dừng ID stage
        flush_ex = 1'b1;  // Chèn bubble vào EX stage
    end
end
```

**Giải thích**:
- Kiểm tra: Có load instruction trong EX stage không?
- Kiểm tra: Lệnh trong ID stage có cần dữ liệu từ load đó không?
- Nếu có → **STALL**: Dừng IF và ID, chèn bubble vào EX

### Ví Dụ 2: Load-Use Hazard

```
Lệnh 1: LW x1, 0(x2)     (Đọc từ bộ nhớ vào x1)
Lệnh 2: ADD x3, x1, x4   (Cần x1 từ lệnh 1)
```

**Timeline**:

```
🕐 Cycle 1-2: Lệnh 1 đi qua IF, ID

🕑 Cycle 3:
   Lệnh 1 - EX:  Tính địa chỉ = x2 + 0
   Lệnh 2 - ID:  Cần x1 → ❌ Chưa có!

🕒 Cycle 4:
   Lệnh 1 - MEM: Đọc từ bộ nhớ → x1 = 0x12345678 (chưa ghi vào thanh ghi)
   Lệnh 2 - ID:  🛑 STALL! Vẫn đợi x1
                 (Bubble trong EX)

🕓 Cycle 5:
   Lệnh 1 - WB:  ✅ Ghi x1 = 0x12345678 vào thanh ghi
   Lệnh 2 - ID:  ✅ Bây giờ mới có x1

🕔 Cycle 6:
   Lệnh 2 - EX:  Tính x3 = x1 + x4
```

**Tổng**: Mất 1 cycle để stall (bắt buộc, vì load cần 2 cycles)

## 📊 Đặc Điểm Model 1

### ✅ Ưu Điểm:
1. **Đơn giản**: Không cần logic forwarding phức tạp
2. **Dễ hiểu**: Dễ debug, dễ kiểm tra
3. **An toàn**: Luôn đảm bảo dữ liệu đúng

### ❌ Nhược Điểm:
1. **Chậm**: Nhiều stall cycles
2. **Performance thấp**: IPC (Instructions Per Cycle) thấp
3. **Lãng phí**: Nhiều pipeline bubbles (chu kỳ không làm gì)

### 📈 Performance:

**Ví dụ với 100 lệnh**:
- Số lệnh: 100
- Số stall cycles: ~30-40 (do data hazards)
- **Tổng cycles: ~140-150**
- **IPC ≈ 0.67-0.71** (trung bình 0.67-0.71 lệnh/cycle)

---

# Model 2: Forwarding (Có Chuyển Dữ Liệu) {#model2}

## 🎯 Model 2 Là Gì?

**Model 2** giống như một nhà máy **thông minh và nhanh**:
- Công nhân có thể "mượn" nguyên liệu từ công nhân khác
- Không cần đợi nguyên liệu về kho, lấy trực tiếp từ dây chuyền
- Nhanh hơn nhiều, nhưng logic phức tạp hơn

## 🔍 Cách Hoạt Động

### Ví Dụ 1: Hai Lệnh Đơn Giản (Giống Model 1)

```
Lệnh 1: ADD x1, x2, x3    (Tính x1 = x2 + x3)
Lệnh 2: ADD x4, x1, x5    (Tính x4 = x1 + x5, CẦN x1 từ lệnh 1!)
```

### Timeline Chi Tiết (Model 2):

```
🕐 Cycle 1:
   Lệnh 1 - IF:  Lấy lệnh "ADD x1, x2, x3" từ bộ nhớ
   Lệnh 2 -     (chưa có)

🕑 Cycle 2:
   Lệnh 1 - ID:  Giải mã lệnh, đọc x2=10, x3=20 từ thanh ghi
   Lệnh 2 - IF:  Lấy lệnh "ADD x4, x1, x5" từ bộ nhớ

🕒 Cycle 3:
   Lệnh 1 - EX:  ALU tính x1 = 10 + 20 = 30
                 ✅ Kết quả có ngay (x1 = 30)
   Lệnh 2 - ID:  Giải mã lệnh, cần đọc x1
                 ❌ x1 chưa có trong thanh ghi
                 ✅ NHƯNG: Forwarding Unit phát hiện x1 đang ở MEM stage!
                 ✅ FORWARD x1 = 30 từ MEM stage của lệnh 1!

🕓 Cycle 4:
   Lệnh 1 - MEM: Chuyển kết quả x1 = 30
                 (Forwarding Unit có thể forward từ đây)
   Lệnh 2 - EX:  ✅ Dùng x1 = 30 từ forwarding → Tính x4 = 30 + x5
                 🚀 KHÔNG CẦN STALL!

🕔 Cycle 5:
   Lệnh 1 - WB:  Ghi x1 = 30 vào thanh ghi (để các lệnh sau dùng)
   Lệnh 2 - MEM: Chuyển kết quả x4
   (Lệnh tiếp theo - EX)

🕕 Cycle 6:
   Lệnh 2 - WB:  Ghi x4 vào thanh ghi
   (Lệnh tiếp theo - MEM)
```

**Tổng kết**: 
- Lệnh 1: 5 cycles
- Lệnh 2: 5 cycles, **KHÔNG STALL!**
- **Tổng: 6 cycles** (tiết kiệm 2 cycles so với Model 1!)

### Code Thực Tế - Forwarding Unit (Model 2):

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

**Giải thích từng bước**:

1. **Kiểm tra MEM stage**:
   - Có lệnh trong MEM stage đang ghi vào thanh ghi không? (`mem_reg_write`)
   - Địa chỉ thanh ghi đích của lệnh đó (`mem_rd_addr`) có trùng với thanh ghi nguồn của lệnh hiện tại (`ex_rs1_addr`) không?
   - Nếu có → `forward_a = 10` (forward từ MEM stage)

2. **Kiểm tra WB stage** (nếu không forward từ MEM):
   - Tương tự, kiểm tra WB stage
   - Nếu có → `forward_a = 01` (forward từ WB stage)

3. **Ưu tiên**: MEM > WB (vì MEM stage gần hơn, dữ liệu mới hơn)

### Ví Dụ Cụ Thể - Forwarding Logic:

**Tình huống**:
```
Lệnh 1: ADD x1, x2, x3    (EX stage: đang tính x1)
Lệnh 2: ADD x4, x1, x5    (ID stage: cần x1)
```

**Forwarding Unit kiểm tra**:
```
Cycle 3:
  Lệnh 1 ở EX stage:
    - mem_rd_addr = 1 (x1)
    - mem_reg_write = 1 (sẽ ghi vào x1)
  
  Lệnh 2 ở ID stage, chuẩn bị vào EX:
    - ex_rs1_addr = 1 (x1) ← Trùng với mem_rd_addr!
    
  → forward_a = 10 (forward từ MEM)
```

**Forwarding MUX chọn dữ liệu**:
```systemverilog
always_comb begin
    case (forward_a)
        2'b00: forward_rs1_data = ex_rs1_data;      // Từ thanh ghi
        2'b01: forward_rs1_data = wb_reg_wdata;     // Từ WB stage
        2'b10: forward_rs1_data = mem_alu_result;   // Từ MEM stage ← CHỌN NÀY!
        default: forward_rs1_data = ex_rs1_data;
    endcase
end
```

**Kết quả**: Lệnh 2 dùng `x1 = 30` từ MEM stage của lệnh 1, **KHÔNG CẦN ĐỢI**!

### Ví Dụ 2: Forward Từ WB Stage

```
Lệnh 1: ADD x1, x2, x3    (WB stage: vừa ghi x1 vào thanh ghi)
Lệnh 2: ADD x4, x1, x5    (EX stage: cần x1)
```

**Tình huống**: Lệnh 1 đã ở WB stage, không còn ở MEM stage nữa.

**Forwarding Unit**:
```
Cycle 5:
  Lệnh 1 ở WB stage:
    - wb_rd_addr = 1 (x1)
    - wb_reg_write = 1
  
  Lệnh 2 ở EX stage:
    - ex_rs1_addr = 1 (x1) ← Trùng với wb_rd_addr!
    - forward_a = 00 (chưa set) → Kiểm tra WB
    
  → forward_a = 01 (forward từ WB)
```

**Kết quả**: Lệnh 2 dùng `x1 = 30` từ WB stage của lệnh 1.

### Ví Dụ 3: Load-Use Hazard (Vẫn Phải Stall!)

```
Lệnh 1: LW x1, 0(x2)      (Đọc từ bộ nhớ vào x1)
Lệnh 2: ADD x3, x1, x4    (Cần x1 từ lệnh 1)
```

**Vấn đề**: Load instruction cần 2 cycles (MEM và WB) để có dữ liệu. Không thể forward sớm hơn!

**Timeline**:

```
🕐 Cycle 3:
   Lệnh 1 - EX:  Tính địa chỉ
   Lệnh 2 - ID:  Cần x1 → ❌ Chưa có (vẫn đang tính địa chỉ)

🕑 Cycle 4:
   Lệnh 1 - MEM: Đọc từ bộ nhớ → x1 = 0x12345678
                 ❌ Dữ liệu chưa sẵn sàng để forward (vẫn đang đọc)
   Lệnh 2 - ID:  🛑 STALL! Phải đợi

🕒 Cycle 5:
   Lệnh 1 - WB:  ✅ x1 = 0x12345678 (bây giờ mới có thể forward)
   Lệnh 2 - ID:  ✅ Có thể forward từ WB → Tiếp tục

🕓 Cycle 6:
   Lệnh 2 - EX:  Dùng x1 từ forwarding → Tính x3
```

**Tổng**: Vẫn mất 1 cycle stall (bắt buộc cho load-use hazard)

### Code Thực Tế - Hazard Detection (Model 2):

```systemverilog
// Load-use hazard: stall nếu load trong EX và lệnh trong ID phụ thuộc
if (ex_is_load && ex_enable && ex_rd_addr != 5'b0) begin
    if ((id_rs1_addr == ex_rd_addr && id_reg_write) ||
        (id_rs2_addr == ex_rd_addr && (id_mem_write || id_branch))) begin
        stall_if = 1'b1;  // Dừng IF
        stall_id = 1'b1;  // Dừng ID
        flush_ex = 1'b1;  // Chèn bubble vào EX
    end
end
```

**Giải thích**:
- Model 2 cũng phải stall cho load-use hazard (giống Model 1)
- Nhưng các data hazard khác (ADD, SUB...) có thể forward → không cần stall!

## 📊 Đặc Điểm Model 2

### ✅ Ưu Điểm:
1. **Nhanh**: Ít stall cycles hơn Model 1
2. **Hiệu quả**: IPC cao hơn
3. **Tối ưu**: Tận dụng tối đa pipeline

### ❌ Nhược Điểm:
1. **Phức tạp**: Cần Forwarding Unit logic
2. **Khó debug**: Nhiều đường dữ liệu hơn
3. **Tốn tài nguyên**: Cần thêm MUX và logic

### 📈 Performance:

**Ví dụ với 100 lệnh**:
- Số lệnh: 100
- Số stall cycles: ~10-15 (chỉ load-use hazards)
- **Tổng cycles: ~115-120**
- **IPC ≈ 0.83-0.87** (trung bình 0.83-0.87 lệnh/cycle)

**So với Model 1**: Nhanh hơn **~20-30%**!

---

# So Sánh Trực Quan {#so-sánh}

## 📊 Bảng So Sánh

| Đặc Điểm | Model 1 (Non-Forwarding) | Model 2 (Forwarding) |
|----------|-------------------------|---------------------|
| **Forwarding** | ❌ Không có | ✅ Có (MEM > WB priority) |
| **Data Hazard** | 🛑 Stall pipeline | ✅ Forward dữ liệu |
| **Load-Use Hazard** | 🛑 Stall 1 cycle | 🛑 Stall 1 cycle (bắt buộc) |
| **Độ phức tạp** | ✅ Đơn giản | ❌ Phức tạp hơn |
| **Performance** | ❌ Thấp (IPC ~0.7) | ✅ Cao (IPC ~0.85) |
| **Stall Cycles** | ❌ Nhiều (~30-40/100 lệnh) | ✅ Ít (~10-15/100 lệnh) |

## 🎬 Ví Dụ Trực Quan

### Scenario: 3 Lệnh Liên Tiếp

```
Lệnh 1: ADD x1, x2, x3    (x1 = x2 + x3)
Lệnh 2: ADD x4, x1, x5    (x4 = x1 + x5) ← Cần x1
Lệnh 3: ADD x6, x4, x7    (x6 = x4 + x7) ← Cần x4
```

### Model 1 Timeline:

```
Cycle 1: L1-IF
Cycle 2: L1-ID, L2-IF
Cycle 3: L1-EX, L2-ID (cần x1) → 🛑 STALL!
Cycle 4: L1-MEM, L2-ID (vẫn cần x1) → 🛑 STALL!
Cycle 5: L1-WB (x1 có), L2-ID
Cycle 6: L2-EX, L3-IF
Cycle 7: L2-MEM, L3-ID (cần x4) → 🛑 STALL!
Cycle 8: L2-WB (x4 có), L3-ID
Cycle 9: L3-EX
Cycle 10: L3-MEM
Cycle 11: L3-WB

Tổng: 11 cycles
```

### Model 2 Timeline:

```
Cycle 1: L1-IF
Cycle 2: L1-ID, L2-IF
Cycle 3: L1-EX, L2-ID
Cycle 4: L1-MEM, L2-EX → ✅ FORWARD x1 từ MEM!
Cycle 5: L1-WB, L2-MEM, L3-IF
Cycle 6: L2-WB, L3-ID
Cycle 7: L3-EX → ✅ FORWARD x4 từ WB!
Cycle 8: L3-MEM
Cycle 9: L3-WB

Tổng: 9 cycles
```

**Kết quả**: Model 2 nhanh hơn **2 cycles** (18% nhanh hơn)!

## 🎯 Khi Nào Dùng Model Nào?

### Dùng Model 1 khi:
- ✅ Cần đơn giản, dễ hiểu
- ✅ Cần dễ debug
- ✅ Performance không quan trọng
- ✅ Học tập, nghiên cứu

### Dùng Model 2 khi:
- ✅ Cần performance cao
- ✅ Ứng dụng thực tế
- ✅ Chấp nhận độ phức tạp
- ✅ Có đủ tài nguyên hardware

## 📝 Tóm Tắt

### Model 1:
- **Cách hoạt động**: Đợi dữ liệu có trong thanh ghi mới dùng
- **Khi gặp data hazard**: **STALL** và đợi
- **Performance**: Thấp, nhiều stall
- **Code**: Đơn giản, forwarding unit luôn trả về `00`

### Model 2:
- **Cách hoạt động**: Lấy dữ liệu trực tiếp từ MEM/WB stage
- **Khi gặp data hazard**: **FORWARD** dữ liệu (trừ load-use)
- **Performance**: Cao, ít stall
- **Code**: Phức tạp, forwarding unit kiểm tra và forward

### Điểm Chung:
- ✅ Cả hai đều có branch prediction
- ✅ Cả hai đều có load-use hazard detection
- ✅ Cả hai đều phải stall cho load-use hazard
- ✅ Cả hai đều đảm bảo tính chính xác

---

## 🎓 Kết Luận

**Model 1** giống như một người **cẩn thận**, luôn đợi đầy đủ thông tin mới làm việc.

**Model 2** giống như một người **thông minh**, biết cách "mượn" thông tin từ nơi khác để làm việc nhanh hơn.

Cả hai đều đúng, nhưng Model 2 nhanh hơn nhờ "thông minh" hơn! 🚀


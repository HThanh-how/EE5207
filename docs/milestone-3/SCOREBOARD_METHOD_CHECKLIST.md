# Scoreboard Method Testing Checklist

## So sánh Code Gốc vs Code Hiện Tại

### Code Gốc Milestone 3 (`milestone_3_code/scoreboard.sv`):
```systemverilog
// Print PASS messages
always @(negedge i_clk) begin : debug
    if (o_insn_vld && (o_pc_debug == 32'h18)) begin
        $write("%s", o_io_ledr[7:0]);
    end
end

// Print results
always @(negedge i_clk) begin : result
    if (o_insn_vld && ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20))) begin
        // Print statistics...
        $finish;
    end
end
```

### Code Milestone 2 (`milestone_2/Pipeline/scoreboard.sv`):
```systemverilog
// Print PASS messages
always @(negedge i_clk) begin
    if (o_pc_debug == 32'h18) begin
        $write("%s", o_io_ledr[7:0]);
    end
end

// Print results
always @(negedge i_clk) begin
    if (o_pc_debug == 32'h1c) begin
        $display("\nEND of ISA tests\n");
        $finish;
    end
end
```

## Điểm Khác Biệt Quan Trọng:

1. **Milestone 3**: Check `o_insn_vld && (o_pc_debug == 32'h18)`
2. **Milestone 2**: Chỉ check `o_pc_debug == 32'h18` (không có `o_insn_vld`)

## Các Phương Pháp Cần Test:

### ✅ METHOD 1: Original Milestone 3 (Đang dùng)
- **Logic**: `o_insn_vld && (o_pc_debug == 32'h18)`
- **Lý do**: Đảm bảo instruction đã hoàn thành (không bị flush)
- **Status**: ✅ Đang test

### ⏳ METHOD 2: Milestone 2 Style
- **Logic**: `o_pc_debug == 32'h18` (không có `o_insn_vld`)
- **Lý do**: Đơn giản hơn, giống milestone 2
- **Status**: ⏳ Chưa test (uncomment để test)

### ⏳ METHOD 3: LEDR Change at PC 0x18
- **Logic**: `o_pc_debug == 32'h18 && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0`
- **Lý do**: Bắt LEDR change tại PC 0x18
- **Status**: ⏳ Chưa test (uncomment để test)

### ⏳ METHOD 4: LEDR Change with o_insn_vld
- **Logic**: `o_insn_vld && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0`
- **Lý do**: Bắt LEDR change khi instruction valid
- **Status**: ⏳ Chưa test (uncomment để test)

### ⏳ METHOD 5: LEDR Change Only
- **Logic**: `o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0`
- **Lý do**: Bắt mọi LEDR change (không check PC)
- **Status**: ⏳ Chưa test (uncomment để test)

## Checklist Test:

- [ ] **METHOD 1**: Test với `o_insn_vld && (o_pc_debug == 32'h18)`
  - [ ] PASS messages có in ra không?
  - [ ] Branch instructions > 0 không?
  - [ ] Test program chạy đủ không?

- [ ] **METHOD 2**: Test với `o_pc_debug == 32'h18` (không có `o_insn_vld`)
  - [ ] PASS messages có in ra không?
  - [ ] Branch instructions > 0 không?

- [ ] **METHOD 3**: Test với LEDR change at PC 0x18
  - [ ] PASS messages có in ra không?

- [ ] **METHOD 4**: Test với LEDR change + o_insn_vld
  - [ ] PASS messages có in ra không?

- [ ] **METHOD 5**: Test với LEDR change only
  - [ ] PASS messages có in ra không?

## Kết Luận:

**Phương pháp đúng sẽ:**
1. ✅ In PASS messages
2. ✅ Branch instructions > 0 (ít nhất 8-10+)
3. ✅ Test program chạy đủ (không chỉ 24 instructions)

**Hiện tại đang dùng METHOD 1 (Original Milestone 3)**


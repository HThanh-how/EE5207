# CHECKLIST ĐẠT 10 ĐIỂM - MILESTONE 2

## ✅ KIỂM TRA CẤU TRÚC
- [x] Folder structure đúng: 00_src, 01_bench, 02_test, 03_sim
- [x] Tất cả file source code trong 00_src/
- [x] Testbench files trong 01_bench/
- [x] Hex test files trong 02_test/
- [x] Makefile trong 03_sim/

## ✅ KIỂM TRA MODULE IMPLEMENTATION
- [x] **single_cycle.sv**: Top-level module đầy đủ
- [x] **register_file.sv**: 32 registers, x0 luôn = 0
- [x] **alu.sv**: Đầy đủ operations (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
- [x] **imem.sv**: 8KB, load từ hex file đúng format
- [x] **dmem.sv**: 2KB (0x0000_0000 - 0x0000_07FF), hỗ trợ byte/halfword/word
- [x] **control_unit.sv**: Decode đầy đủ tất cả instruction types

## ✅ KIỂM TRA INSTRUCTIONS
- [x] R-type: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
- [x] I-type: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU, LW, LH, LHU, LB, LBU, JALR
- [x] S-type: SW, SH, SB
- [x] B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
- [x] U-type: LUI, AUIPC
- [x] J-type: JAL

## ✅ KIỂM TRA IMMEDIATE GENERATION
- [x] I-type immediate: sign-extended từ bits [31:20]
- [x] S-type immediate: sign-extended từ bits [31:25, 11:7]
- [x] B-type immediate: sign-extended từ bits [31, 7, 30:25, 11:8], LSB = 0
- [x] U-type immediate: bits [31:12] << 12
- [x] J-type immediate: sign-extended từ bits [31, 19:12, 20, 30:21], LSB = 0
- [x] Shift immediate: bits [24:20] (cho SLLI, SRLI, SRAI)

## ✅ KIỂM TRA MEMORY MAPPING
- [x] DMEM: 0x0000_0000 - 0x0000_07FF (2KB)
- [x] I/O Switch: 0x0000_1000 (read)
- [x] I/O LEDR: 0x0000_1010 (write)
- [x] I/O LEDG: 0x0000_1014 (write)
- [x] I/O LCD: 0x0000_1018 (write)
- [x] Byte ordering: Little-endian (đúng RISC-V)

## ✅ KIỂM TRA CONTROL SIGNALS
- [x] reg_write: Đúng cho tất cả instructions cần write register
- [x] mem_write/mem_read: Đúng cho load/store instructions
- [x] mem_to_reg: 00=ALU, 01=Memory, 10=PC+4
- [x] alu_src_a/b: Đúng cho từng instruction type
- [x] alu_op: Đúng operation cho từng instruction
- [x] branch/jump: Đúng cho branch và jump instructions
- [x] mem_size: Đúng cho LB/LH/LW/SB/SH/SW

## ✅ KIỂM TRA DATAPATH
- [x] PC update: Sequential, branch, jump đều đúng
- [x] Instruction fetch: Đọc từ IMEM đúng địa chỉ
- [x] Register read: Read rs1, rs2 đúng
- [x] ALU: Tính toán đúng với operands
- [x] Memory access: Read/write đúng với address và size
- [x] Register write: Write vào register file đúng (trừ x0)

## ✅ KIỂM TRA RESET VÀ CONTROL
- [x] Reset logic: Active LOW, PC = 0 khi reset
- [x] PC update: Update vào cuối clock cycle
- [x] Instruction valid: o_insn_vld = ~i_reset
- [x] PC debug: o_pc_debug = pc

## ✅ KIỂM TRA I/O
- [x] LEDR: Update khi write vào 0x0000_1010
- [x] LEDG: Update khi write vào 0x0000_1014
- [x] LCD: Update khi write vào 0x0000_1018
- [x] Switch: Read từ 0x0000_1000 trả về i_io_sw
- [x] HEX displays: Set về 0 (không dùng)

## ✅ KIỂM TRA SYNTAX
- [x] Không có lỗi syntax
- [x] Tất cả signals được khai báo
- [x] Module connections đúng
- [x] Clock và reset handling đúng

## ✅ KIỂM TRA TESTBENCH COMPATIBILITY
- [x] Interface khớp với testbench
- [x] Output signals khớp với scoreboard
- [x] PC debug output đúng
- [x] Instruction valid signal đúng

## 🎯 CÁC ĐIỂM QUAN TRỌNG ĐỂ ĐẠT 10 ĐIỂM
1. ✅ Tất cả instructions được implement đúng
2. ✅ Memory mapping đúng với yêu cầu
3. ✅ Byte ordering: Little-endian (RISC-V standard)
4. ✅ Register x0 luôn bằng 0
5. ✅ PC reset và update đúng
6. ✅ Branch và Jump logic đúng
7. ✅ I/O mapping đúng
8. ✅ Memory access (byte/halfword/word) đúng
9. ✅ Control signals đúng cho từng instruction
10. ✅ Không có lỗi syntax hoặc logic


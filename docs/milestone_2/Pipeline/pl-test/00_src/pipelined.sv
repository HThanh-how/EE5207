// Pipelined RISC-V Processor - Milestone 3
// Top-level module with 5 stages: IF, ID, EX, MEM, WB
module pipelined (
    input  logic         i_clk     ,
    input  logic         i_reset   ,
    input  logic [31:0]  i_io_sw   ,
    output logic [31:0]  o_io_ledr ,
    output logic [31:0]  o_io_ledg ,
    output logic [31:0]  o_io_lcd  ,
    output logic [ 6:0]  o_io_hex0 ,
    output logic [ 6:0]  o_io_hex1 ,
    output logic [ 6:0]  o_io_hex2 ,
    output logic [ 6:0]  o_io_hex3 ,
    output logic [ 6:0]  o_io_hex4 ,
    output logic [ 6:0]  o_io_hex5 ,
    output logic [ 6:0]  o_io_hex6 ,
    output logic [ 6:0]  o_io_hex7 ,
    output logic [31:0]  o_pc_debug,
    output logic         o_insn_vld,
    output logic         o_ctrl    ,  // Control transfer instruction (branch/jump)
    output logic         o_mispred     // Misprediction signal
);

    // ============================================
    // Pipeline Stage Signals
    // ============================================
    
    // IF Stage
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;
    logic [31:0] if_instruction;
    logic        if_enable;
    logic        if_flush;
    
    // IF/ID Pipeline Register
    logic [31:0] id_pc;
    logic [31:0] id_pc_plus4;
    logic [31:0] id_instruction;
    logic        id_enable;
    logic        id_flush;
    
    // ID Stage
    logic [31:0] id_imm;
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [ 4:0] id_rs1_addr;
    logic [ 4:0] id_rs2_addr;
    logic [ 4:0] id_rd_addr;
    
    // Control signals from ID stage
    logic        id_reg_write;
    logic        id_mem_write;
    logic        id_mem_read;
    logic [1:0]  id_mem_to_reg;
    logic [1:0]  id_alu_src_a;
    logic [1:0]  id_alu_src_b;
    logic [3:0]  id_alu_op;
    logic        id_branch;
    logic        id_jump;
    logic [2:0]  id_mem_size;
    logic        id_pc_src;
    logic        id_is_load;
    
    // ID/EX Pipeline Register
    logic [31:0] ex_pc;
    logic [31:0] ex_pc_plus4;
    logic [31:0] ex_rs1_data;
    logic [31:0] ex_rs2_data;
    logic [31:0] ex_imm;
    logic [ 4:0] ex_rs1_addr;
    logic [ 4:0] ex_rs2_addr;
    logic [ 4:0] ex_rd_addr;
    logic [ 2:0] ex_funct3;  // For branch comparison
    logic        ex_reg_write;
    logic        ex_mem_write;
    logic        ex_mem_read;
    logic [1:0]  ex_mem_to_reg;
    logic [1:0]  ex_alu_src_a;
    logic [1:0]  ex_alu_src_b;
    logic [3:0]  ex_alu_op;
    logic        ex_branch;
    logic        ex_jump;
    logic [2:0]  ex_mem_size;
    logic        ex_pc_src;
    logic        ex_is_load;
    logic        ex_enable;
    logic        ex_flush;
    
    // EX Stage
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_result;
    logic        ex_alu_zero;
    logic [31:0] ex_branch_target;
    logic [31:0] ex_jump_target;
    logic        ex_branch_taken;
    logic        ex_is_ctrl;  // Control transfer instruction
    
    // Forwarding signals
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;
    logic [31:0] forward_rs1_data;
    logic [31:0] forward_rs2_data;
    
    // EX/MEM Pipeline Register
    logic [31:0] mem_pc;
    logic [31:0] mem_pc_plus4;
    logic [31:0] mem_alu_result;
    logic [31:0] mem_rs2_data;
    logic [ 4:0] mem_rd_addr;
    logic        mem_reg_write;
    logic        mem_mem_write;
    logic        mem_mem_read;
    logic [1:0]  mem_mem_to_reg;
    logic [2:0]  mem_mem_size;
    logic        mem_is_ctrl;
    logic        mem_branch_taken;
    logic        mem_predicted_taken;  // For misprediction detection
    logic        mem_enable;
    logic        mem_flush;
    
    // MEM Stage
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic [31:0] mem_io_data;
    
    // MEM/WB Pipeline Register
    logic [31:0] wb_pc;
    logic [31:0] wb_pc_plus4;
    logic [31:0] wb_alu_result;
    logic [31:0] wb_mem_rdata;
    logic [31:0] wb_io_data;
    logic [ 4:0] wb_rd_addr;
    logic        wb_reg_write;
    logic [1:0]  wb_mem_to_reg;
    logic        wb_is_ctrl;
    logic        wb_enable;
    logic        wb_flush;
    
    // WB Stage
    logic [31:0] wb_reg_wdata;
    
    // Hazard Detection
    logic        stall_if;
    logic        stall_id;
    logic        stall_ex;
    logic        flush_if;
    logic        flush_id;
    logic        flush_ex;
    
    // ============================================
    // IF Stage: Instruction Fetch
    // ============================================
    assign if_enable = ~stall_if;
    assign if_flush = flush_if;
    assign pc_plus4 = pc + 32'h4;
    
    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            pc <= 32'h0000_0000;
        end else if (if_enable) begin
            pc <= pc_next;
        end
        // If stalled, PC doesn't update (keeps current value)
    end
    
    imem_sync u_imem (
        .clk     (i_clk),
        .enable  (if_enable),
        .addr    (pc),
        .rdata   (if_instruction)
    );
    
    // IF/ID Pipeline Register
    always_ff @(posedge i_clk) begin
        if (~i_reset || if_flush) begin
            id_pc <= 32'b0;
            id_pc_plus4 <= 32'b0;
            id_instruction <= 32'b0;
            id_enable <= 1'b0;
        end else if (if_enable && ~stall_id) begin
            id_pc <= pc;
            id_pc_plus4 <= pc_plus4;
            id_instruction <= if_instruction;
            id_enable <= 1'b1;
        end
        // If stall_id, keep previous values (no update)
    end
    
    // ============================================
    // ID Stage: Instruction Decode
    // ============================================
    assign id_rs1_addr = id_instruction[19:15];
    assign id_rs2_addr = id_instruction[24:20];
    assign id_rd_addr = id_instruction[11:7];
    
    control_unit u_control (
        .opcode     (id_instruction[6:0]),
        .funct3     (id_instruction[14:12]),
        .funct7     (id_instruction[31:25]),
        .reg_write  (id_reg_write),
        .mem_write  (id_mem_write),
        .mem_read   (id_mem_read),
        .mem_to_reg (id_mem_to_reg),
        .alu_src_a  (id_alu_src_a),
        .alu_src_b  (id_alu_src_b),
        .alu_op     (id_alu_op),
        .branch     (id_branch),
        .jump       (id_jump),
        .mem_size   (id_mem_size),
        .pc_src     (id_pc_src)
    );
    
    assign id_is_load = (id_instruction[6:0] == 7'b0000011);
    
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
    
    // Immediate generation
    always_comb begin
        case (id_instruction[6:0])
            7'b0110111: id_imm = {id_instruction[31:12], 12'b0};  // LUI
            7'b0010111: id_imm = {id_instruction[31:12], 12'b0};  // AUIPC
            7'b1101111: id_imm = {{12{id_instruction[31]}}, id_instruction[31], id_instruction[19:12], id_instruction[20], id_instruction[30:21], 1'b0};  // JAL
            7'b1100011: id_imm = {{20{id_instruction[31]}}, id_instruction[31], id_instruction[7], id_instruction[30:25], id_instruction[11:8], 1'b0};  // Branch
            7'b0100011: id_imm = {{20{id_instruction[31]}}, id_instruction[31:25], id_instruction[11:7]};  // Store
            7'b0010011: begin
                if (id_instruction[14:12] == 3'b001 || id_instruction[14:12] == 3'b101) begin
                    id_imm = {27'b0, id_instruction[24:20]};  // SLLI, SRLI, SRAI
                end else begin
                    id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};  // Other I-type
                end
            end
            7'b0000011: id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};  // Load
            7'b1100111: id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};  // JALR
            default: id_imm = 32'b0;
        endcase
    end
    
    // ID/EX Pipeline Register
    always_ff @(posedge i_clk) begin
        if (~i_reset || flush_id) begin
            ex_pc <= 32'b0;
            ex_pc_plus4 <= 32'b0;
            ex_rs1_data <= 32'b0;
            ex_rs2_data <= 32'b0;
            ex_imm <= 32'b0;
            ex_rs1_addr <= 5'b0;
            ex_rs2_addr <= 5'b0;
            ex_rd_addr <= 5'b0;
            ex_funct3 <= 3'b0;
            ex_reg_write <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_to_reg <= 2'b0;
            ex_alu_src_a <= 2'b0;
            ex_alu_src_b <= 2'b0;
            ex_alu_op <= 4'b0;
            ex_branch <= 1'b0;
            ex_jump <= 1'b0;
            ex_mem_size <= 3'b0;
            ex_pc_src <= 1'b0;
            ex_is_load <= 1'b0;
            ex_enable <= 1'b0;
        end else if (~stall_ex && id_enable) begin
            ex_pc <= id_pc;
            ex_pc_plus4 <= id_pc_plus4;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_imm <= id_imm;
            ex_rs1_addr <= id_rs1_addr;
            ex_rs2_addr <= id_rs2_addr;
            ex_rd_addr <= id_rd_addr;
            ex_funct3 <= id_instruction[14:12];  // Store funct3 for branch comparison
            ex_reg_write <= id_reg_write;
            ex_mem_write <= id_mem_write;
            ex_mem_read <= id_mem_read;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_alu_src_a <= id_alu_src_a;
            ex_alu_src_b <= id_alu_src_b;
            ex_alu_op <= id_alu_op;
            ex_branch <= id_branch;
            ex_jump <= id_jump;
            ex_mem_size <= id_mem_size;
            ex_pc_src <= id_pc_src;
            ex_is_load <= id_is_load;
            ex_enable <= id_enable;
        end
    end
    
    // ============================================
    // EX Stage: Execute
    // ============================================
    // Forwarding MUX for ALU inputs
    always_comb begin
        case (forward_a)
            2'b00: forward_rs1_data = ex_rs1_data;
            2'b01: forward_rs1_data = wb_reg_wdata;  // Forward from WB
            2'b10: forward_rs1_data = mem_alu_result;  // Forward from MEM
            default: forward_rs1_data = ex_rs1_data;
        endcase
        
        case (forward_b)
            2'b00: forward_rs2_data = ex_rs2_data;
            2'b01: forward_rs2_data = wb_reg_wdata;  // Forward from WB
            2'b10: forward_rs2_data = mem_alu_result;  // Forward from MEM
            default: forward_rs2_data = ex_rs2_data;
        endcase
    end
    
    // ALU input selection
    always_comb begin
        case (ex_alu_src_a)
            2'b00: ex_alu_a = forward_rs1_data;
            2'b01: ex_alu_a = ex_pc;
            2'b10: ex_alu_a = ex_pc;
            2'b11: ex_alu_a = {ex_imm[31:12], 12'b0};
            default: ex_alu_a = forward_rs1_data;
        endcase
        
        case (ex_alu_src_b)
            2'b00: ex_alu_b = forward_rs2_data;
            2'b01: ex_alu_b = ex_imm;
            2'b10: ex_alu_b = 32'h4;
            2'b11: ex_alu_b = 32'b0;
            default: ex_alu_b = forward_rs2_data;
        endcase
    end
    
    alu u_alu (
        .op_a       (ex_alu_a),
        .op_b       (ex_alu_b),
        .alu_op     (ex_alu_op),
        .alu_out    (ex_alu_result),
        .alu_zero   (ex_alu_zero)
    );
    
    // Branch comparison
    always_comb begin
        if (ex_branch) begin
            case (ex_funct3)  // funct3 from instruction
                3'b000: ex_branch_taken = (forward_rs1_data == forward_rs2_data);  // BEQ
                3'b001: ex_branch_taken = (forward_rs1_data != forward_rs2_data);  // BNE
                3'b100: ex_branch_taken = ($signed(forward_rs1_data) < $signed(forward_rs2_data));  // BLT
                3'b101: ex_branch_taken = ($signed(forward_rs1_data) >= $signed(forward_rs2_data));  // BGE
                3'b110: ex_branch_taken = (forward_rs1_data < forward_rs2_data);  // BLTU
                3'b111: ex_branch_taken = (forward_rs1_data >= forward_rs2_data);  // BGEU
                default: ex_branch_taken = 1'b0;
            endcase
        end else begin
            ex_branch_taken = 1'b0;
        end
    end
    
    assign ex_branch_target = ex_pc + ex_imm;
    assign ex_jump_target = ex_jump ? (ex_pc + ex_imm) : (forward_rs1_data + ex_imm);
    assign ex_is_ctrl = ex_branch || ex_jump;
    
    // PC next selection
    always_comb begin
        if (ex_jump) begin
            pc_next = ex_jump_target;
        end else if (ex_branch && ex_branch_taken) begin
            pc_next = ex_branch_target;
        end else begin
            pc_next = pc_plus4;
        end
    end
    
    // EX/MEM Pipeline Register
    always_ff @(posedge i_clk) begin
        if (~i_reset || flush_ex) begin
            mem_pc <= 32'b0;
            mem_pc_plus4 <= 32'b0;
            mem_alu_result <= 32'b0;
            mem_rs2_data <= 32'b0;
            mem_rd_addr <= 5'b0;
            mem_reg_write <= 1'b0;
            mem_mem_write <= 1'b0;
            mem_mem_read <= 1'b0;
            mem_mem_to_reg <= 2'b0;
            mem_mem_size <= 3'b0;
            mem_is_ctrl <= 1'b0;
            mem_branch_taken <= 1'b0;
            mem_predicted_taken <= 1'b0;  // Default: predict not-taken
            mem_enable <= 1'b0;
        end else if (ex_enable) begin
            mem_pc <= ex_pc;
            mem_pc_plus4 <= ex_pc_plus4;
            mem_alu_result <= ex_alu_result;
            mem_rs2_data <= forward_rs2_data;
            mem_rd_addr <= ex_rd_addr;
            mem_reg_write <= ex_reg_write;
            mem_mem_write <= ex_mem_write;
            mem_mem_read <= ex_mem_read;
            mem_mem_to_reg <= ex_mem_to_reg;
            mem_mem_size <= ex_mem_size;
            mem_is_ctrl <= ex_is_ctrl;
            mem_branch_taken <= ex_branch_taken;
            mem_predicted_taken <= 1'b0;  // Default prediction: not-taken (will be enhanced with branch prediction)
            mem_enable <= ex_enable;
        end
    end
    
    // ============================================
    // MEM Stage: Memory Access
    // ============================================
    assign mem_addr = mem_alu_result;
    assign mem_wdata = mem_rs2_data;
    
    dmem_sync u_dmem (
        .clk        (i_clk),
        .enable     (mem_enable),
        .we         (mem_mem_write && (mem_addr < 32'h0001_0000)),  // Only write to memory region (not I/O)
        .addr       (mem_addr),
        .wdata      (mem_wdata),
        .mem_size   (mem_mem_size),
        .rdata      (mem_rdata)
    );
    
    // I/O memory mapping
    always_comb begin
        if (mem_mem_read) begin
            if (mem_addr >= 32'h1000_4000 && mem_addr < 32'h1000_5000) begin
                mem_io_data = o_io_lcd;
            end else if (mem_addr >= 32'h1000_3000 && mem_addr < 32'h1000_4000) begin
                mem_io_data = {1'b0, o_io_hex7, 1'b0, o_io_hex6, 1'b0, o_io_hex5, 1'b0, o_io_hex4};
            end else if (mem_addr >= 32'h1000_2000 && mem_addr < 32'h1000_3000) begin
                mem_io_data = {1'b0, o_io_hex3, 1'b0, o_io_hex2, 1'b0, o_io_hex1, 1'b0, o_io_hex0};
            end else if (mem_addr >= 32'h1000_1000 && mem_addr < 32'h1000_2000) begin
                mem_io_data = o_io_ledg;
            end else if (mem_addr >= 32'h1000_0000 && mem_addr < 32'h1000_1000) begin
                mem_io_data = o_io_ledr;
            end else if (mem_addr >= 32'h1001_0000 && mem_addr < 32'h1001_1000) begin
                mem_io_data = i_io_sw;
            end else begin
                mem_io_data = mem_rdata;
            end
        end else begin
            mem_io_data = mem_rdata;
        end
    end
    
    // MEM/WB Pipeline Register
    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            wb_pc <= 32'b0;
            wb_pc_plus4 <= 32'b0;
            wb_alu_result <= 32'b0;
            wb_mem_rdata <= 32'b0;
            wb_io_data <= 32'b0;
            wb_rd_addr <= 5'b0;
            wb_reg_write <= 1'b0;
            wb_mem_to_reg <= 2'b0;
            wb_is_ctrl <= 1'b0;
            wb_enable <= 1'b0;
            wb_flush <= 1'b0;
        end else if (mem_enable) begin
            wb_pc <= mem_pc;
            wb_pc_plus4 <= mem_pc_plus4;
            wb_alu_result <= mem_alu_result;
            wb_mem_rdata <= mem_rdata;
            wb_io_data <= mem_io_data;
            wb_rd_addr <= mem_rd_addr;
            wb_reg_write <= mem_reg_write;
            wb_mem_to_reg <= mem_mem_to_reg;
            wb_is_ctrl <= mem_is_ctrl;
            wb_enable <= mem_enable;
            wb_flush <= 1'b0;  // WB stage should not be flushed (instruction completes)
        end
    end
    
    // ============================================
    // WB Stage: Write Back
    // ============================================
    always_comb begin
        case (wb_mem_to_reg)
            2'b00: wb_reg_wdata = wb_alu_result;
            2'b01: wb_reg_wdata = wb_io_data;
            2'b10: wb_reg_wdata = wb_pc_plus4;
            default: wb_reg_wdata = wb_alu_result;
        endcase
    end
    
    // ============================================
    // Hazard Detection Unit (Non-forwarding model)
    // ============================================
    // For now, implement basic hazard detection
    // This will be enhanced for forwarding model
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
        
        // Control hazard: flush if branch/jump taken
        if (ex_is_ctrl && ex_enable) begin
            if (ex_branch && ex_branch_taken) begin
                flush_if = 1'b1;
                flush_id = 1'b1;
            end else if (ex_jump) begin
                flush_if = 1'b1;
                flush_id = 1'b1;
            end
        end
    end
    
    // ============================================
    // Forwarding Unit (Basic - will be enhanced)
    // ============================================
    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;
        
        // Forward from MEM stage
        if (mem_reg_write && mem_enable && mem_rd_addr != 5'b0) begin
            if (mem_rd_addr == ex_rs1_addr) begin
                forward_a = 2'b10;  // Forward from MEM
            end
            if (mem_rd_addr == ex_rs2_addr) begin
                forward_b = 2'b10;  // Forward from MEM
            end
        end
        
        // Forward from WB stage (if not forwarding from MEM)
        if (wb_reg_write && wb_enable && wb_rd_addr != 5'b0) begin
            if (forward_a == 2'b00 && wb_rd_addr == ex_rs1_addr) begin
                forward_a = 2'b01;  // Forward from WB
            end
            if (forward_b == 2'b00 && wb_rd_addr == ex_rs2_addr) begin
                forward_b = 2'b01;  // Forward from WB
            end
        end
    end
    
    // ============================================
    // Outputs
    // ============================================
    assign o_pc_debug = pc;
    
    // o_insn_vld: Instruction valid in WB stage (not flushed)
    // Only count instructions that complete successfully (not flushed in previous stages)
    // An instruction is valid if it reaches WB stage without being flushed
    assign o_insn_vld = wb_enable;
    
    // o_ctrl: Control transfer instruction (branch/jump) in WB stage
    // Assert when branch/jump instruction is in WB stage
    assign o_ctrl = wb_is_ctrl && wb_enable;
    
    // o_mispred: Misprediction signal - asserted when flush happens due to mispredicted branch/jump
    // This should be propagated to WB stage
    // According to spec: "o_mispred signal is added to record mispredictions, when the HazardDetection
    // asserts a flush due to a control transfer instruction being mispredicted."
    // For default "always not-taken" prediction: misprediction = branch actually taken (causes flush)
    logic wb_mispred;
    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            wb_mispred <= 1'b0;
        end else if (mem_enable) begin
            // Default prediction: not-taken (always predict PC+4)
            // Misprediction = branch actually taken (causes flush in IF/ID stages)
            // Only count branch instructions (jump always taken, no misprediction for default)
            wb_mispred <= (mem_is_ctrl && mem_branch_taken);
        end else begin
            wb_mispred <= 1'b0;
        end
    end
    assign o_mispred = wb_mispred && wb_enable;
    
    // I/O outputs (same as single-cycle)
    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            o_io_ledr <= 32'b0;
            o_io_ledg <= 32'b0;
            o_io_lcd  <= 32'b0;
            o_io_hex0 <= 7'b0;
            o_io_hex1 <= 7'b0;
            o_io_hex2 <= 7'b0;
            o_io_hex3 <= 7'b0;
            o_io_hex4 <= 7'b0;
            o_io_hex5 <= 7'b0;
            o_io_hex6 <= 7'b0;
            o_io_hex7 <= 7'b0;
        end else if (mem_mem_write && mem_enable) begin
            // LEDR window @ 0x1000_0000 - 0x1000_0FFF
            if (mem_addr >= 32'h1000_0000 && mem_addr < 32'h1000_1000) begin
                o_io_ledr <= mem_wdata;
            // LEDG window @ 0x1000_1000 - 0x1000_1FFF
            end else if (mem_addr >= 32'h1000_1000 && mem_addr < 32'h1000_2000) begin
                o_io_ledg <= mem_wdata;
            // HEX0..3 window @ 0x1000_2000 - 0x1000_2FFF
            end else if (mem_addr >= 32'h1000_2000 && mem_addr < 32'h1000_3000) begin
                case (mem_mem_size)
                    3'b000: begin
                        case (mem_addr[1:0])
                            2'b00: o_io_hex0 <= mem_wdata[6:0];
                            2'b01: o_io_hex1 <= mem_wdata[6:0];
                            2'b10: o_io_hex2 <= mem_wdata[6:0];
                            2'b11: o_io_hex3 <= mem_wdata[6:0];
                        endcase
                    end
                    3'b001: begin
                        if (mem_addr[1] == 1'b0) begin
                            o_io_hex0 <= mem_wdata[6:0];
                            o_io_hex1 <= mem_wdata[14:8];
                        end else begin
                            o_io_hex2 <= mem_wdata[6:0];
                            o_io_hex3 <= mem_wdata[14:8];
                        end
                    end
                    3'b010: begin
                        o_io_hex0 <= mem_wdata[6:0];
                        o_io_hex1 <= mem_wdata[14:8];
                        o_io_hex2 <= mem_wdata[22:16];
                        o_io_hex3 <= mem_wdata[30:24];
                    end
                    default: begin
                        o_io_hex0 <= mem_wdata[6:0];
                        o_io_hex1 <= mem_wdata[14:8];
                        o_io_hex2 <= mem_wdata[22:16];
                        o_io_hex3 <= mem_wdata[30:24];
                    end
                endcase
            // HEX4..7 window @ 0x1000_3000 - 0x1000_3FFF
            end else if (mem_addr >= 32'h1000_3000 && mem_addr < 32'h1000_4000) begin
                case (mem_mem_size)
                    3'b000: begin
                        case (mem_addr[1:0])
                            2'b00: o_io_hex4 <= mem_wdata[6:0];
                            2'b01: o_io_hex5 <= mem_wdata[6:0];
                            2'b10: o_io_hex6 <= mem_wdata[6:0];
                            2'b11: o_io_hex7 <= mem_wdata[6:0];
                        endcase
                    end
                    3'b001: begin
                        if (mem_addr[1] == 1'b0) begin
                            o_io_hex4 <= mem_wdata[6:0];
                            o_io_hex5 <= mem_wdata[14:8];
                        end else begin
                            o_io_hex6 <= mem_wdata[6:0];
                            o_io_hex7 <= mem_wdata[14:8];
                        end
                    end
                    3'b010: begin
                        o_io_hex4 <= mem_wdata[6:0];
                        o_io_hex5 <= mem_wdata[14:8];
                        o_io_hex6 <= mem_wdata[22:16];
                        o_io_hex7 <= mem_wdata[30:24];
                    end
                    default: begin
                        o_io_hex4 <= mem_wdata[6:0];
                        o_io_hex5 <= mem_wdata[14:8];
                        o_io_hex6 <= mem_wdata[22:16];
                        o_io_hex7 <= mem_wdata[30:24];
                    end
                endcase
            // LCD window @ 0x1000_4000 - 0x1000_4FFF
            end else if (mem_addr >= 32'h1000_4000 && mem_addr < 32'h1000_5000) begin
                o_io_lcd <= mem_wdata;
            end
        end
    end

endmodule : pipelined


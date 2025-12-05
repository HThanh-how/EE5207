// Pipelined RISC-V Processor - Milestone 3
// Model 2: Forwarding with Two-bit Branch Prediction
// Features:
// - Forwarding Unit for data hazards
// - Hazard Detection for load-use hazards
// - Two-bit Dynamic Branch Predictor with BTB
// - BRAM memory support
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
    output logic         o_ctrl    ,
    output logic         o_mispred
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
    
    // Branch Prediction signals
    logic [31:0] predicted_pc;
    logic        btb_hit;
    logic        predict_taken;
    
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
    logic [ 2:0] ex_funct3;
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
    logic        ex_predicted_taken;  // Predicted direction from IF stage
    
    // EX Stage
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_result;
    logic        ex_alu_zero;
    logic [31:0] ex_branch_target;
    logic [31:0] ex_jump_target;
    logic        ex_branch_taken;
    logic        ex_is_ctrl;
    
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
    logic        mem_predicted_taken;
    logic        mem_is_branch;  // Distinguish branch from jump
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
    logic        wb_mispred;
    
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
    // Two-bit Branch Predictor with BTB
    // ============================================
    parameter BTB_SIZE = 256;  // 256 entries
    parameter BTB_INDEX_WIDTH = $clog2(BTB_SIZE);
    
    // BTB entry: {tag, predicted_pc, two_bit_state}
    logic [31-BTB_INDEX_WIDTH-2:0] btb_tag [0:BTB_SIZE-1];
    logic [31:0] btb_target [0:BTB_SIZE-1];
    logic [1:0]  btb_state [0:BTB_SIZE-1];  // Two-bit predictor state
    
    // BTB index from PC
    logic [BTB_INDEX_WIDTH-1:0] btb_index_if;
    logic [BTB_INDEX_WIDTH-1:0] btb_index_ex;
    logic [31-BTB_INDEX_WIDTH-2:0] btb_tag_if;
    logic [31-BTB_INDEX_WIDTH-2:0] btb_tag_ex;
    
    // Initialize BTB
    integer i;
    initial begin
        for (i = 0; i < BTB_SIZE; i = i + 1) begin
            btb_tag[i] = '0;
            btb_target[i] = '0;
            btb_state[i] = 2'b01;  // Start with "weakly not-taken"
        end
    end
    
    // BTB lookup in IF stage
    assign btb_index_if = pc[BTB_INDEX_WIDTH+1:2];
    assign btb_tag_if = pc[31:BTB_INDEX_WIDTH+2];
    
    always_comb begin
        btb_hit = 1'b0;
        predicted_pc = pc_plus4;
        predict_taken = 1'b0;
        
        if (btb_tag[btb_index_if] == btb_tag_if && btb_state[btb_index_if] >= 2'b10) begin
            // Hit and predictor says "taken" (strongly or weakly)
            btb_hit = 1'b1;
            predicted_pc = btb_target[btb_index_if];
            predict_taken = 1'b1;
        end
    end
    
    // BTB update in EX stage (when branch/jump resolved)
    assign btb_index_ex = ex_pc[BTB_INDEX_WIDTH+1:2];
    assign btb_tag_ex = ex_pc[31:BTB_INDEX_WIDTH+2];
    
    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            // Reset handled in initial block
        end else if (ex_enable && ex_is_ctrl) begin
            // Update BTB entry
            btb_tag[btb_index_ex] <= btb_tag_ex;
            if (ex_branch) begin
                btb_target[btb_index_ex] <= ex_branch_target;
            end else if (ex_jump) begin
                btb_target[btb_index_ex] <= ex_jump_target;
            end
            
            // Update two-bit predictor state machine
            if (ex_branch) begin
                case (btb_state[btb_index_ex])
                    2'b00: begin  // Strongly not-taken
                        if (ex_branch_taken) begin
                            btb_state[btb_index_ex] <= 2'b01;  // Move to weakly not-taken
                        end
                    end
                    2'b01: begin  // Weakly not-taken
                        if (ex_branch_taken) begin
                            btb_state[btb_index_ex] <= 2'b11;  // Move to weakly taken
                        end else begin
                            btb_state[btb_index_ex] <= 2'b00;  // Move to strongly not-taken
                        end
                    end
                    2'b10: begin  // Weakly taken
                        if (ex_branch_taken) begin
                            btb_state[btb_index_ex] <= 2'b11;  // Move to strongly taken
                        end else begin
                            btb_state[btb_index_ex] <= 2'b01;  // Move to weakly not-taken
                        end
                    end
                    2'b11: begin  // Strongly taken
                        if (~ex_branch_taken) begin
                            btb_state[btb_index_ex] <= 2'b10;  // Move to weakly taken
                        end
                    end
                endcase
            end else if (ex_jump) begin
                // Jumps are always taken, set to strongly taken
                btb_state[btb_index_ex] <= 2'b11;
            end
        end
    end
    
    // ============================================
    // IF Stage: Instruction Fetch
    // ============================================
    assign if_enable = ~stall_if;
    assign if_flush = flush_if;
    assign pc_plus4 = pc + 32'h4;
    
    // PC selection: use predicted PC if available, or correct PC if misprediction
    logic [31:0] corrected_pc;
    logic        use_corrected_pc;
    
    always_comb begin
        use_corrected_pc = 1'b0;
        corrected_pc = 32'b0;
        
        // Check for misprediction in EX stage
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
            
            if (ex_predicted_taken != actual_taken) begin
                use_corrected_pc = 1'b1;
                corrected_pc = actual_target;
            end
        end
        
        // PC next selection
        if (use_corrected_pc) begin
            pc_next = corrected_pc;
        end else if (btb_hit && predict_taken) begin
            pc_next = predicted_pc;
        end else begin
            pc_next = pc_plus4;
        end
    end
    
    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            pc <= 32'h0000_0000;
        end else if (if_enable) begin
            pc <= pc_next;
        end
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
            7'b0110111: id_imm = {id_instruction[31:12], 12'b0};
            7'b0010111: id_imm = {id_instruction[31:12], 12'b0};
            7'b1101111: id_imm = {{12{id_instruction[31]}}, id_instruction[31], id_instruction[19:12], id_instruction[20], id_instruction[30:21], 1'b0};
            7'b1100011: id_imm = {{20{id_instruction[31]}}, id_instruction[31], id_instruction[7], id_instruction[30:25], id_instruction[11:8], 1'b0};
            7'b0100011: id_imm = {{20{id_instruction[31]}}, id_instruction[31:25], id_instruction[11:7]};
            7'b0010011: begin
                if (id_instruction[14:12] == 3'b001 || id_instruction[14:12] == 3'b101) begin
                    id_imm = {27'b0, id_instruction[24:20]};
                end else begin
                    id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};
                end
            end
            7'b0000011: id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};
            7'b1100111: id_imm = {{20{id_instruction[31]}}, id_instruction[31:20]};
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
            ex_predicted_taken <= 1'b0;
        end else if (~stall_ex && id_enable) begin
            ex_pc <= id_pc;
            ex_pc_plus4 <= id_pc_plus4;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_imm <= id_imm;
            ex_rs1_addr <= id_rs1_addr;
            ex_rs2_addr <= id_rs2_addr;
            ex_rd_addr <= id_rd_addr;
            ex_funct3 <= id_instruction[14:12];
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
            // Capture prediction from IF stage
            ex_predicted_taken <= (id_branch || id_jump) ? predict_taken : 1'b0;
        end
    end
    
    // ============================================
    // EX Stage: Execute
    // ============================================
    // Forwarding MUX for ALU inputs
    always_comb begin
        case (forward_a)
            2'b00: forward_rs1_data = ex_rs1_data;
            2'b01: forward_rs1_data = wb_reg_wdata;
            2'b10: forward_rs1_data = mem_alu_result;
            default: forward_rs1_data = ex_rs1_data;
        endcase
        
        case (forward_b)
            2'b00: forward_rs2_data = ex_rs2_data;
            2'b01: forward_rs2_data = wb_reg_wdata;
            2'b10: forward_rs2_data = mem_alu_result;
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
            case (ex_funct3)
                3'b000: ex_branch_taken = (forward_rs1_data == forward_rs2_data);
                3'b001: ex_branch_taken = (forward_rs1_data != forward_rs2_data);
                3'b100: ex_branch_taken = ($signed(forward_rs1_data) < $signed(forward_rs2_data));
                3'b101: ex_branch_taken = ($signed(forward_rs1_data) >= $signed(forward_rs2_data));
                3'b110: ex_branch_taken = (forward_rs1_data < forward_rs2_data);
                3'b111: ex_branch_taken = (forward_rs1_data >= forward_rs2_data);
                default: ex_branch_taken = 1'b0;
            endcase
        end else begin
            ex_branch_taken = 1'b0;
        end
    end
    
    assign ex_branch_target = ex_pc + ex_imm;
    assign ex_jump_target = ex_jump ? (ex_pc + ex_imm) : (forward_rs1_data + ex_imm);
    assign ex_is_ctrl = ex_branch || ex_jump;
    
    // Correct PC next (for misprediction detection)
    logic [31:0] correct_pc_next;
    always_comb begin
        if (ex_jump) begin
            correct_pc_next = ex_jump_target;
        end else if (ex_branch && ex_branch_taken) begin
            correct_pc_next = ex_branch_target;
        end else begin
            correct_pc_next = ex_pc_plus4;
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
            mem_predicted_taken <= 1'b0;
            mem_is_branch <= 1'b0;
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
            mem_predicted_taken <= ex_predicted_taken;
            mem_is_branch <= ex_branch;
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
        .we         (mem_mem_write && (mem_addr < 32'h0001_0000)),
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
            wb_mispred <= 1'b0;
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
            // Misprediction: predicted != actual
            // For branches: mispred if (predicted_taken != branch_taken)
            // For jumps: mispred if predicted not-taken (jumps always taken)
            if (mem_is_branch) begin
                wb_mispred <= (mem_predicted_taken != mem_branch_taken);
            end else if (mem_is_ctrl) begin
                // Jump: mispred if predicted not-taken (jumps always taken)
                wb_mispred <= ~mem_predicted_taken;
            end else begin
                wb_mispred <= 1'b0;
            end
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
    // Forwarding Unit
    // ============================================
    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;
        
        // Forward from MEM stage (priority: MEM > WB)
        if (mem_reg_write && mem_enable && mem_rd_addr != 5'b0) begin
            if (mem_rd_addr == ex_rs1_addr) begin
                forward_a = 2'b10;
            end
            if (mem_rd_addr == ex_rs2_addr) begin
                forward_b = 2'b10;
            end
        end
        
        // Forward from WB stage (if not forwarding from MEM)
        if (wb_reg_write && wb_enable && wb_rd_addr != 5'b0) begin
            if (forward_a == 2'b00 && wb_rd_addr == ex_rs1_addr) begin
                forward_a = 2'b01;
            end
            if (forward_b == 2'b00 && wb_rd_addr == ex_rs2_addr) begin
                forward_b = 2'b01;
            end
        end
    end
    
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
        // Misprediction detected in EX stage
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
                flush_if = 1'b1;
                flush_id = 1'b1;
                flush_ex = 1'b1;
                // Correct PC will be set in next cycle
            end
        end
    end
    
    
    // ============================================
    // Outputs
    // ============================================
    assign o_pc_debug = pc;
    assign o_insn_vld = wb_enable;
    assign o_ctrl = wb_is_ctrl && wb_enable;
    assign o_mispred = wb_mispred && wb_enable;
    
    // I/O outputs
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
            if (mem_addr >= 32'h1000_0000 && mem_addr < 32'h1000_1000) begin
                o_io_ledr <= mem_wdata;
            end else if (mem_addr >= 32'h1000_1000 && mem_addr < 32'h1000_2000) begin
                o_io_ledg <= mem_wdata;
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
            end else if (mem_addr >= 32'h1000_4000 && mem_addr < 32'h1000_5000) begin
                o_io_lcd <= mem_wdata;
            end
        end
    end

endmodule : pipelined


//----------------------------------------------------------------------//
//  Design Note
//----------------------------------------------------------------------//
//  1. Instruction Memory Depth (IMEM): At least 8  kiB to run the "isa_1b.hex" or "isa_4b.hex"
//  2. Data        Memory Depth (DMEM): At least 64 kiB (0x0000_0000 - 0x0000_FFFF)
//  3. IMEM and DMEM are separate memory blocks.
//  4. 5-Stage Pipeline: IF -> ID -> EX -> MEM -> WB
//  5. Supports both Non-forwarding and Forwarding modes via parameter

module pipelined #(
    parameter FORWARDING_EN = 1  // 1: Forwarding enabled, 0: Non-forwarding
)(
    input  logic         i_clk     ,
    input  logic         i_reset   ,
    // Input peripherals
    input  logic [31:0]  i_io_sw   ,
    // Output peripherals
    output logic [31:0]  o_io_lcd  ,
    output logic [31:0]  o_io_ledr ,
    output logic [31:0]  o_io_ledg ,
    output logic [ 6:0]  o_io_hex0 ,
    output logic [ 6:0]  o_io_hex1 ,
    output logic [ 6:0]  o_io_hex2 ,
    output logic [ 6:0]  o_io_hex3 ,
    output logic [ 6:0]  o_io_hex4 ,
    output logic [ 6:0]  o_io_hex5 ,
    output logic [ 6:0]  o_io_hex6 ,
    output logic [ 6:0]  o_io_hex7 ,
    // Debug
    output logic [31:0]  o_pc_debug,
    output logic         o_insn_vld,
    output logic         o_ctrl    ,
    output logic         o_mispred
);

    //==========================================================================
    // Signal Declarations
    //==========================================================================

    // IF Stage signals
    logic [31:0] pc_if;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4_if;
    logic [31:0] instr_if;

    // ID Stage signals
    logic [31:0] pc_id;
    logic [31:0] pc_plus4_id;
    logic [31:0] instr_id;
    logic        insn_vld_id;
    logic [31:0] rs1_data_id;
    logic [31:0] rs2_data_id;
    logic [31:0] imm_id;
    logic [ 4:0] rs1_addr_id;
    logic [ 4:0] rs2_addr_id;
    logic [ 4:0] rd_addr_id;

    // ID Stage control signals
    logic        reg_wr_en_id;
    logic [ 1:0] wb_sel_id;
    logic        mem_wr_en_id;
    logic [ 2:0] mem_op_id;
    logic [ 3:0] alu_op_id;
    logic        alu_src_id;
    logic        branch_id;
    logic        jal_id;
    logic        jalr_id;
    logic        lui_id;
    logic        auipc_id;

    // EX Stage signals
    logic [31:0] pc_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] rs1_data_ex;
    logic [31:0] rs2_data_ex;
    logic [31:0] imm_ex;
    logic [ 4:0] rs1_addr_ex;
    logic [ 4:0] rs2_addr_ex;
    logic [ 4:0] rd_addr_ex;
    logic        insn_vld_ex;
    logic        ctrl_ex;

    // EX Stage control signals
    logic        reg_wr_en_ex;
    logic [ 1:0] wb_sel_ex;
    logic        mem_wr_en_ex;
    logic [ 2:0] mem_op_ex;
    logic [ 3:0] alu_op_ex;
    logic        alu_src_ex;
    logic        branch_ex;
    logic        jal_ex;
    logic        jalr_ex;
    logic        lui_ex;
    logic        auipc_ex;

    // EX Stage computed signals
    logic [31:0] alu_result_ex;
    logic [31:0] alu_op1;
    logic [31:0] alu_op2;
    logic        br_taken;
    logic [31:0] br_target;

    // MEM Stage signals
    logic [31:0] pc_mem;
    logic [31:0] pc_plus4_mem;
    logic [31:0] alu_result_mem;
    logic [31:0] rs2_data_mem;
    logic [ 4:0] rd_addr_mem;
    logic        insn_vld_mem;
    logic        ctrl_mem;
    logic        mispred_mem;

    // MEM Stage control signals
    logic        reg_wr_en_mem;
    logic [ 1:0] wb_sel_mem;
    logic        mem_wr_en_mem;
    logic [ 2:0] mem_op_mem;

    // MEM Stage computed signals
    logic [31:0] mem_rdata_mem;
    logic [31:0] lsu_rdata;

    // WB Stage signals
    logic [31:0] pc_wb;
    logic [31:0] pc_plus4_wb;
    logic [31:0] alu_result_wb;
    logic [31:0] mem_rdata_wb;
    logic [ 4:0] rd_addr_wb;
    logic        insn_vld_wb;
    logic        ctrl_wb;
    logic        mispred_wb;

    // WB Stage control signals
    logic        reg_wr_en_wb;
    logic [ 1:0] wb_sel_wb;

    // WB Stage computed signals
    logic [31:0] wb_data;

    // Hazard control signals
    logic        stall_if;
    logic        stall_id;
    logic        flush_id;
    logic        flush_ex;
    logic        flush_mem;

    // Forwarding signals
    logic [ 1:0] forward_a;
    logic [ 1:0] forward_b;
    logic [31:0] rs1_fwd_data;
    logic [31:0] rs2_fwd_data;

    // Branch/Jump control
    logic        pc_sel;
    logic        is_load_ex;

    //==========================================================================
    // IF Stage - Instruction Fetch
    //==========================================================================

    // PC + 4
    assign pc_plus4_if = pc_if + 32'd4;

    // PC selection: branch target or PC+4
    assign pc_sel = br_taken;
    assign pc_next = pc_sel ? br_target : pc_plus4_if;

    // PC Register - This is the PC being fetched from memory
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            pc_if <= 32'h0000_0000;
        end else if (!stall_if) begin
            pc_if <= pc_next;
        end
    end

    // Instruction Memory (synchronous read)
    // Address: current PC (output available on same cycle for simulation)
    instr_mem #(
        .MEM_DEPTH(16384)  // 64KB / 4 = 16K words
    ) u_imem (
        .i_clk  (i_clk),
        .i_addr (pc_if[15:2]),
        .o_instr(instr_if)
    );

    //==========================================================================
    // IF/ID Pipeline Register
    //==========================================================================

    // Track if this is the first valid instruction after reset
    logic if_valid;
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            if_valid <= 1'b0;
        end else begin
            if_valid <= 1'b1;  // Valid after first cycle
        end
    end

    // IF/ID register - captures instruction and its PC
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            pc_id       <= 32'h0;
            pc_plus4_id <= 32'h0;
            instr_id    <= 32'h0000_0013;  // NOP (addi x0, x0, 0)
            insn_vld_id <= 1'b0;
        end else if (flush_id) begin
            pc_id       <= 32'h0;
            pc_plus4_id <= 32'h0;
            instr_id    <= 32'h0000_0013;  // NOP
            insn_vld_id <= 1'b0;
        end else if (!stall_id) begin
            pc_id       <= pc_if;
            pc_plus4_id <= pc_plus4_if;
            instr_id    <= instr_if;
            insn_vld_id <= if_valid;  // Not valid on first cycle after reset
        end
    end

    //==========================================================================
    // ID Stage - Instruction Decode
    //==========================================================================

    // Extract register addresses from instruction
    assign rs1_addr_id = instr_id[19:15];
    assign rs2_addr_id = instr_id[24:20];
    assign rd_addr_id  = instr_id[11:7];

    // Register File
    reg_file u_regfile (
        .i_clk     (i_clk),
        .i_reset   (i_reset),
        .i_rs1_addr(rs1_addr_id),
        .i_rs2_addr(rs2_addr_id),
        .i_rd_addr (rd_addr_wb),
        .i_rd_data (wb_data),
        .i_wr_en   (reg_wr_en_wb),
        .o_rs1_data(rs1_data_id),
        .o_rs2_data(rs2_data_id)
    );

    // Immediate Generator
    imm_gen u_immgen (
        .i_instr(instr_id),
        .o_imm  (imm_id)
    );

    // Control Unit (Decoder)
    control_unit u_ctrl (
        .i_opcode   (instr_id[6:0]),
        .i_funct3   (instr_id[14:12]),
        .i_funct7   (instr_id[31:25]),
        .o_reg_wr_en(reg_wr_en_id),
        .o_wb_sel   (wb_sel_id),
        .o_mem_wr_en(mem_wr_en_id),
        .o_mem_op   (mem_op_id),
        .o_alu_op   (alu_op_id),
        .o_alu_src  (alu_src_id),
        .o_branch   (branch_id),
        .o_jal      (jal_id),
        .o_jalr     (jalr_id),
        .o_lui      (lui_id),
        .o_auipc    (auipc_id)
    );

    //==========================================================================
    // ID/EX Pipeline Register
    //==========================================================================

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            pc_ex        <= 32'h0;
            pc_plus4_ex  <= 32'h0;
            rs1_data_ex  <= 32'h0;
            rs2_data_ex  <= 32'h0;
            imm_ex       <= 32'h0;
            rs1_addr_ex  <= 5'h0;
            rs2_addr_ex  <= 5'h0;
            rd_addr_ex   <= 5'h0;
            insn_vld_ex  <= 1'b0;
            ctrl_ex      <= 1'b0;
            // Control signals
            reg_wr_en_ex <= 1'b0;
            wb_sel_ex    <= 2'b0;
            mem_wr_en_ex <= 1'b0;
            mem_op_ex    <= 3'b0;
            alu_op_ex    <= 4'b0;
            alu_src_ex   <= 1'b0;
            branch_ex    <= 1'b0;
            jal_ex       <= 1'b0;
            jalr_ex      <= 1'b0;
            lui_ex       <= 1'b0;
            auipc_ex     <= 1'b0;
        end else if (flush_ex) begin
            pc_ex        <= 32'h0;
            pc_plus4_ex  <= 32'h0;
            rs1_data_ex  <= 32'h0;
            rs2_data_ex  <= 32'h0;
            imm_ex       <= 32'h0;
            rs1_addr_ex  <= 5'h0;
            rs2_addr_ex  <= 5'h0;
            rd_addr_ex   <= 5'h0;
            insn_vld_ex  <= 1'b0;
            ctrl_ex      <= 1'b0;
            // Control signals
            reg_wr_en_ex <= 1'b0;
            wb_sel_ex    <= 2'b0;
            mem_wr_en_ex <= 1'b0;
            mem_op_ex    <= 3'b0;
            alu_op_ex    <= 4'b0;
            alu_src_ex   <= 1'b0;
            branch_ex    <= 1'b0;
            jal_ex       <= 1'b0;
            jalr_ex      <= 1'b0;
            lui_ex       <= 1'b0;
            auipc_ex     <= 1'b0;
        end else begin
            pc_ex        <= pc_id;
            pc_plus4_ex  <= pc_plus4_id;
            rs1_data_ex  <= rs1_data_id;
            rs2_data_ex  <= rs2_data_id;
            imm_ex       <= imm_id;
            rs1_addr_ex  <= rs1_addr_id;
            rs2_addr_ex  <= rs2_addr_id;
            rd_addr_ex   <= rd_addr_id;
            insn_vld_ex  <= insn_vld_id;
            ctrl_ex      <= branch_id | jal_id | jalr_id;
            // Control signals
            reg_wr_en_ex <= reg_wr_en_id;
            wb_sel_ex    <= wb_sel_id;
            mem_wr_en_ex <= mem_wr_en_id;
            mem_op_ex    <= mem_op_id;
            alu_op_ex    <= alu_op_id;
            alu_src_ex   <= alu_src_id;
            branch_ex    <= branch_id;
            jal_ex       <= jal_id;
            jalr_ex      <= jalr_id;
            lui_ex       <= lui_id;
            auipc_ex     <= auipc_id;
        end
    end

    //==========================================================================
    // EX Stage - Execute
    //==========================================================================

    // Forwarding logic (only active when FORWARDING_EN = 1)
    generate
        if (FORWARDING_EN) begin : gen_forwarding
            // Forwarding Unit
            forwarding_unit u_fwd (
                .i_rs1_addr_ex  (rs1_addr_ex),
                .i_rs2_addr_ex  (rs2_addr_ex),
                .i_rd_addr_mem  (rd_addr_mem),
                .i_rd_addr_wb   (rd_addr_wb),
                .i_reg_wr_en_mem(reg_wr_en_mem),
                .i_reg_wr_en_wb (reg_wr_en_wb),
                .o_forward_a    (forward_a),
                .o_forward_b    (forward_b)
            );

            // Forwarding MUX for rs1
            always_comb begin
                case (forward_a)
                    2'b00: rs1_fwd_data = rs1_data_ex;
                    2'b01: rs1_fwd_data = wb_data;
                    2'b10: rs1_fwd_data = alu_result_mem;
                    default: rs1_fwd_data = rs1_data_ex;
                endcase
            end

            // Forwarding MUX for rs2
            always_comb begin
                case (forward_b)
                    2'b00: rs2_fwd_data = rs2_data_ex;
                    2'b01: rs2_fwd_data = wb_data;
                    2'b10: rs2_fwd_data = alu_result_mem;
                    default: rs2_fwd_data = rs2_data_ex;
                endcase
            end
        end else begin : gen_no_forwarding
            assign forward_a = 2'b00;
            assign forward_b = 2'b00;
            assign rs1_fwd_data = rs1_data_ex;
            assign rs2_fwd_data = rs2_data_ex;
        end
    endgenerate

    // ALU operand selection
    assign alu_op1 = lui_ex ? 32'h0 : (auipc_ex ? pc_ex : rs1_fwd_data);
    assign alu_op2 = alu_src_ex ? imm_ex : rs2_fwd_data;

    // ALU
    alu u_alu (
        .i_op1   (alu_op1),
        .i_op2   (alu_op2),
        .i_alu_op(alu_op_ex),
        .o_result(alu_result_ex)
    );

    // Branch Comparator
    branch_comp u_brc (
        .i_rs1    (rs1_fwd_data),
        .i_rs2    (rs2_fwd_data),
        .i_funct3 (mem_op_ex),  // Using mem_op to carry funct3 for branches
        .i_branch (branch_ex),
        .i_jal    (jal_ex),
        .i_jalr   (jalr_ex),
        .o_br_taken(br_taken)
    );

    // Branch target calculation
    assign br_target = jalr_ex ? (rs1_fwd_data + imm_ex) & ~32'h1 : (pc_ex + imm_ex);

    // Load instruction detection for hazard
    assign is_load_ex = (wb_sel_ex == 2'b01);  // Load instructions

    //==========================================================================
    // EX/MEM Pipeline Register
    //==========================================================================

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            pc_mem         <= 32'h0;
            pc_plus4_mem   <= 32'h0;
            alu_result_mem <= 32'h0;
            rs2_data_mem   <= 32'h0;
            rd_addr_mem    <= 5'h0;
            insn_vld_mem   <= 1'b0;
            ctrl_mem       <= 1'b0;
            mispred_mem    <= 1'b0;
            // Control signals
            reg_wr_en_mem  <= 1'b0;
            wb_sel_mem     <= 2'b0;
            mem_wr_en_mem  <= 1'b0;
            mem_op_mem     <= 3'b0;
        end else if (flush_mem) begin
            pc_mem         <= 32'h0;
            pc_plus4_mem   <= 32'h0;
            alu_result_mem <= 32'h0;
            rs2_data_mem   <= 32'h0;
            rd_addr_mem    <= 5'h0;
            insn_vld_mem   <= 1'b0;
            ctrl_mem       <= 1'b0;
            mispred_mem    <= 1'b0;
            // Control signals
            reg_wr_en_mem  <= 1'b0;
            wb_sel_mem     <= 2'b0;
            mem_wr_en_mem  <= 1'b0;
            mem_op_mem     <= 3'b0;
        end else begin
            pc_mem         <= pc_ex;
            pc_plus4_mem   <= pc_plus4_ex;
            alu_result_mem <= alu_result_ex;
            rs2_data_mem   <= rs2_fwd_data;
            rd_addr_mem    <= rd_addr_ex;
            insn_vld_mem   <= insn_vld_ex;
            ctrl_mem       <= ctrl_ex;
            mispred_mem    <= br_taken;  // Misprediction when branch is taken (always-not-taken predictor)
            // Control signals
            reg_wr_en_mem  <= reg_wr_en_ex;
            wb_sel_mem     <= wb_sel_ex;
            mem_wr_en_mem  <= mem_wr_en_ex;
            mem_op_mem     <= mem_op_ex;
        end
    end

    //==========================================================================
    // MEM Stage - Memory Access
    //==========================================================================

    // Load-Store Unit (includes data memory and peripheral mapping)
    lsu u_lsu (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_addr     (alu_result_mem),
        .i_wdata    (rs2_data_mem),
        .i_wr_en    (mem_wr_en_mem),
        .i_mem_op   (mem_op_mem),
        .o_rdata    (lsu_rdata),
        // Peripheral interfaces
        .i_io_sw    (i_io_sw),
        .o_io_ledr  (o_io_ledr),
        .o_io_ledg  (o_io_ledg),
        .o_io_hex0  (o_io_hex0),
        .o_io_hex1  (o_io_hex1),
        .o_io_hex2  (o_io_hex2),
        .o_io_hex3  (o_io_hex3),
        .o_io_hex4  (o_io_hex4),
        .o_io_hex5  (o_io_hex5),
        .o_io_hex6  (o_io_hex6),
        .o_io_hex7  (o_io_hex7),
        .o_io_lcd   (o_io_lcd)
    );

    assign mem_rdata_mem = lsu_rdata;

    //==========================================================================
    // MEM/WB Pipeline Register
    //==========================================================================

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            pc_wb         <= 32'h0;
            pc_plus4_wb   <= 32'h0;
            alu_result_wb <= 32'h0;
            mem_rdata_wb  <= 32'h0;
            rd_addr_wb    <= 5'h0;
            insn_vld_wb   <= 1'b0;
            ctrl_wb       <= 1'b0;
            mispred_wb    <= 1'b0;
            // Control signals
            reg_wr_en_wb  <= 1'b0;
            wb_sel_wb     <= 2'b0;
        end else begin
            pc_wb         <= pc_mem;
            pc_plus4_wb   <= pc_plus4_mem;
            alu_result_wb <= alu_result_mem;
            mem_rdata_wb  <= mem_rdata_mem;
            rd_addr_wb    <= rd_addr_mem;
            insn_vld_wb   <= insn_vld_mem;
            ctrl_wb       <= ctrl_mem;
            mispred_wb    <= mispred_mem;
            // Control signals
            reg_wr_en_wb  <= reg_wr_en_mem;
            wb_sel_wb     <= wb_sel_mem;
        end
    end

    //==========================================================================
    // WB Stage - Write Back
    //==========================================================================

    // Write-back data selection
    always_comb begin
        case (wb_sel_wb)
            2'b00: wb_data = alu_result_wb;  // ALU result
            2'b01: wb_data = mem_rdata_wb;   // Memory data
            2'b10: wb_data = pc_plus4_wb;    // PC + 4 (for JAL/JALR)
            default: wb_data = alu_result_wb;
        endcase
    end

    //==========================================================================
    // Hazard Detection Unit
    //==========================================================================

    hazard_unit #(
        .FORWARDING_EN(FORWARDING_EN)
    ) u_hazard (
        .i_rs1_addr_id  (rs1_addr_id),
        .i_rs2_addr_id  (rs2_addr_id),
        .i_rd_addr_ex   (rd_addr_ex),
        .i_rd_addr_mem  (rd_addr_mem),
        .i_rd_addr_wb   (rd_addr_wb),
        .i_reg_wr_en_ex (reg_wr_en_ex),
        .i_reg_wr_en_mem(reg_wr_en_mem),
        .i_reg_wr_en_wb (reg_wr_en_wb),
        .i_is_load_ex   (is_load_ex),
        .i_br_taken     (br_taken),
        .o_stall_if     (stall_if),
        .o_stall_id     (stall_id),
        .o_flush_id     (flush_id),
        .o_flush_ex     (flush_ex),
        .o_flush_mem    (flush_mem)
    );

    //==========================================================================
    // Debug Outputs
    //==========================================================================

    assign o_pc_debug = pc_wb;
    assign o_insn_vld = insn_vld_wb;
    assign o_ctrl     = ctrl_wb;
    assign o_mispred  = mispred_wb & ctrl_wb;

endmodule : pipelined

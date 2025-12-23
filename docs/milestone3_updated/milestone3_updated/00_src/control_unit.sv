//----------------------------------------------------------------------//
// Control Unit (Decoder) Module
// - Decodes RV32I instructions
// - Generates control signals for datapath
//----------------------------------------------------------------------//

module control_unit (
    input  logic [ 6:0] i_opcode,
    input  logic [ 2:0] i_funct3,
    input  logic [ 6:0] i_funct7,
    output logic        o_reg_wr_en,
    output logic [ 1:0] o_wb_sel,
    output logic        o_mem_wr_en,
    output logic [ 2:0] o_mem_op,
    output logic [ 3:0] o_alu_op,
    output logic        o_alu_src,
    output logic        o_branch,
    output logic        o_jal,
    output logic        o_jalr,
    output logic        o_lui,
    output logic        o_auipc
);

    // Opcode definitions
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_IMM    = 7'b0010011;
    localparam OP_REG    = 7'b0110011;

    // ALU operation codes
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    // Write-back selection
    localparam WB_ALU  = 2'b00;
    localparam WB_MEM  = 2'b01;
    localparam WB_PC4  = 2'b10;

    // Control signal generation
    always_comb begin
        // Default values
        o_reg_wr_en = 1'b0;
        o_wb_sel    = WB_ALU;
        o_mem_wr_en = 1'b0;
        o_mem_op    = i_funct3;
        o_alu_op    = ALU_ADD;
        o_alu_src   = 1'b0;
        o_branch    = 1'b0;
        o_jal       = 1'b0;
        o_jalr      = 1'b0;
        o_lui       = 1'b0;
        o_auipc     = 1'b0;

        case (i_opcode)
            OP_LUI: begin
                o_reg_wr_en = 1'b1;
                o_alu_src   = 1'b1;
                o_alu_op    = ALU_ADD;
                o_lui       = 1'b1;
            end

            OP_AUIPC: begin
                o_reg_wr_en = 1'b1;
                o_alu_src   = 1'b1;
                o_alu_op    = ALU_ADD;
                o_auipc     = 1'b1;
            end

            OP_JAL: begin
                o_reg_wr_en = 1'b1;
                o_wb_sel    = WB_PC4;
                o_jal       = 1'b1;
            end

            OP_JALR: begin
                o_reg_wr_en = 1'b1;
                o_wb_sel    = WB_PC4;
                o_alu_src   = 1'b1;
                o_jalr      = 1'b1;
            end

            OP_BRANCH: begin
                o_branch    = 1'b1;
            end

            OP_LOAD: begin
                o_reg_wr_en = 1'b1;
                o_wb_sel    = WB_MEM;
                o_alu_src   = 1'b1;
                o_alu_op    = ALU_ADD;
            end

            OP_STORE: begin
                o_mem_wr_en = 1'b1;
                o_alu_src   = 1'b1;
                o_alu_op    = ALU_ADD;
            end

            OP_IMM: begin
                o_reg_wr_en = 1'b1;
                o_alu_src   = 1'b1;
                case (i_funct3)
                    3'b000: o_alu_op = ALU_ADD;   // ADDI
                    3'b010: o_alu_op = ALU_SLT;   // SLTI
                    3'b011: o_alu_op = ALU_SLTU;  // SLTIU
                    3'b100: o_alu_op = ALU_XOR;   // XORI
                    3'b110: o_alu_op = ALU_OR;    // ORI
                    3'b111: o_alu_op = ALU_AND;   // ANDI
                    3'b001: o_alu_op = ALU_SLL;   // SLLI
                    3'b101: o_alu_op = i_funct7[5] ? ALU_SRA : ALU_SRL;  // SRAI/SRLI
                    default: o_alu_op = ALU_ADD;
                endcase
            end

            OP_REG: begin
                o_reg_wr_en = 1'b1;
                case (i_funct3)
                    3'b000: o_alu_op = i_funct7[5] ? ALU_SUB : ALU_ADD;  // SUB/ADD
                    3'b001: o_alu_op = ALU_SLL;   // SLL
                    3'b010: o_alu_op = ALU_SLT;   // SLT
                    3'b011: o_alu_op = ALU_SLTU;  // SLTU
                    3'b100: o_alu_op = ALU_XOR;   // XOR
                    3'b101: o_alu_op = i_funct7[5] ? ALU_SRA : ALU_SRL;  // SRA/SRL
                    3'b110: o_alu_op = ALU_OR;    // OR
                    3'b111: o_alu_op = ALU_AND;   // AND
                    default: o_alu_op = ALU_ADD;
                endcase
            end

            default: begin
                // NOP or invalid instruction
                o_reg_wr_en = 1'b0;
            end
        endcase
    end

endmodule : control_unit

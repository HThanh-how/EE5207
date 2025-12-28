//----------------------------------------------------------------------//
// Immediate Generator Module
// - Generates sign-extended immediates from RV32I instruction formats
// - Supports I, S, B, U, and J type immediates
//----------------------------------------------------------------------//

module imm_gen (
    input  logic [31:0] i_instr,
    output logic [31:0] o_imm
);

    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_IMM    = 7'b0010011;
    localparam OP_REG    = 7'b0110011;

    logic [6:0] opcode;
    assign opcode = i_instr[6:0];

    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;

    assign i_imm = {{20{i_instr[31]}}, i_instr[31:20]};
    assign s_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
    assign b_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
    assign u_imm = {i_instr[31:12], 12'b0};
    assign j_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
    always_comb begin
        case (opcode)
            OP_LUI,
            OP_AUIPC:  o_imm = u_imm;
            OP_JAL:    o_imm = j_imm;
            OP_JALR,
            OP_LOAD,
            OP_IMM:    o_imm = i_imm;
            OP_BRANCH: o_imm = b_imm;
            OP_STORE:  o_imm = s_imm;
            default:   o_imm = 32'h0;
        endcase
    end

endmodule : imm_gen


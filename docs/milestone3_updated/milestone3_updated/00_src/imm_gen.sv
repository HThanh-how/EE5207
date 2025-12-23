//----------------------------------------------------------------------//
// Immediate Generator Module
// - Generates sign-extended immediates from RV32I instruction formats
// - Supports I, S, B, U, and J type immediates
//----------------------------------------------------------------------//

module imm_gen (
    input  logic [31:0] i_instr,
    output logic [31:0] o_imm
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

    logic [6:0] opcode;
    assign opcode = i_instr[6:0];

    // Immediate extraction for different instruction types
    logic [31:0] i_imm;  // I-type
    logic [31:0] s_imm;  // S-type
    logic [31:0] b_imm;  // B-type
    logic [31:0] u_imm;  // U-type
    logic [31:0] j_imm;  // J-type

    // I-type: imm[11:0] = instr[31:20]
    assign i_imm = {{20{i_instr[31]}}, i_instr[31:20]};

    // S-type: imm[11:5|4:0] = instr[31:25|11:7]
    assign s_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};

    // B-type: imm[12|10:5|4:1|11] = instr[31|30:25|11:8|7]
    assign b_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};

    // U-type: imm[31:12] = instr[31:12], lower 12 bits are 0
    assign u_imm = {i_instr[31:12], 12'b0};

    // J-type: imm[20|10:1|11|19:12] = instr[31|30:21|20|19:12]
    assign j_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};

    // Select appropriate immediate based on opcode
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

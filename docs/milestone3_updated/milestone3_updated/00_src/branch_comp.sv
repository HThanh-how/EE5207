//----------------------------------------------------------------------//
// Branch Comparator Module
// - Compares two operands for branch conditions
// - Supports all RV32I branch types (BEQ, BNE, BLT, BGE, BLTU, BGEU)
// - Also handles JAL and JALR unconditional jumps
//----------------------------------------------------------------------//

module branch_comp (
    input  logic [31:0] i_rs1,
    input  logic [31:0] i_rs2,
    input  logic [ 2:0] i_funct3,
    input  logic        i_branch,
    input  logic        i_jal,
    input  logic        i_jalr,
    output logic        o_br_taken
);

    // Branch function codes
    localparam BEQ  = 3'b000;
    localparam BNE  = 3'b001;
    localparam BLT  = 3'b100;
    localparam BGE  = 3'b101;
    localparam BLTU = 3'b110;
    localparam BGEU = 3'b111;

    // Comparison results
    logic eq;
    logic lt_signed;
    logic lt_unsigned;

    assign eq          = (i_rs1 == i_rs2);
    assign lt_signed   = ($signed(i_rs1) < $signed(i_rs2));
    assign lt_unsigned = (i_rs1 < i_rs2);

    // Branch decision logic
    always_comb begin
        if (i_jal || i_jalr) begin
            // Unconditional jumps
            o_br_taken = 1'b1;
        end else if (i_branch) begin
            case (i_funct3)
                BEQ:  o_br_taken = eq;
                BNE:  o_br_taken = ~eq;
                BLT:  o_br_taken = lt_signed;
                BGE:  o_br_taken = ~lt_signed;
                BLTU: o_br_taken = lt_unsigned;
                BGEU: o_br_taken = ~lt_unsigned;
                default: o_br_taken = 1'b0;
            endcase
        end else begin
            o_br_taken = 1'b0;
        end
    end

endmodule : branch_comp

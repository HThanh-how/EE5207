//----------------------------------------------------------------------//
// ALU Module
// - Supports all RV32I arithmetic/logic operations
//----------------------------------------------------------------------//

module alu (
    input  logic [31:0] i_op1,
    input  logic [31:0] i_op2,
    input  logic [ 3:0] i_alu_op,
    output logic [31:0] o_result
);

    // ALU operation codes
    localparam ALU_ADD  = 4'b0000;  // ADD
    localparam ALU_SUB  = 4'b0001;  // SUB
    localparam ALU_SLL  = 4'b0010;  // Shift Left Logical
    localparam ALU_SLT  = 4'b0011;  // Set Less Than (signed)
    localparam ALU_SLTU = 4'b0100;  // Set Less Than Unsigned
    localparam ALU_XOR  = 4'b0101;  // XOR
    localparam ALU_SRL  = 4'b0110;  // Shift Right Logical
    localparam ALU_SRA  = 4'b0111;  // Shift Right Arithmetic
    localparam ALU_OR   = 4'b1000;  // OR
    localparam ALU_AND  = 4'b1001;  // AND

    // Shift amount
    logic [4:0] shamt;
    assign shamt = i_op2[4:0];

    // ALU operation
    always_comb begin
        case (i_alu_op)
            ALU_ADD:  o_result = i_op1 + i_op2;
            ALU_SUB:  o_result = i_op1 - i_op2;
            ALU_SLL:  o_result = i_op1 << shamt;
            ALU_SLT:  o_result = ($signed(i_op1) < $signed(i_op2)) ? 32'h1 : 32'h0;
            ALU_SLTU: o_result = (i_op1 < i_op2) ? 32'h1 : 32'h0;
            ALU_XOR:  o_result = i_op1 ^ i_op2;
            ALU_SRL:  o_result = i_op1 >> shamt;
            ALU_SRA:  o_result = $signed(i_op1) >>> shamt;
            ALU_OR:   o_result = i_op1 | i_op2;
            ALU_AND:  o_result = i_op1 & i_op2;
            default:  o_result = 32'h0;
        endcase
    end

endmodule : alu

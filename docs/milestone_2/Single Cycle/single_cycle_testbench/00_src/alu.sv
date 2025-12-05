module alu (
    input  logic [31:0]  op_a,
    input  logic [31:0]  op_b,
    input  logic [ 3:0]  alu_op,
    output logic [31:0] alu_out,
    output logic        alu_zero
);

    always_comb begin
        case (alu_op)
            4'b0000: alu_out = op_a + op_b;
            4'b0001: alu_out = op_a - op_b;
            4'b0010: alu_out = op_a & op_b;
            4'b0011: alu_out = op_a | op_b;
            4'b0100: alu_out = op_a ^ op_b;
            4'b0101: alu_out = op_a << op_b[4:0];
            4'b0110: alu_out = op_a >> op_b[4:0];
            4'b0111: alu_out = $signed(op_a) >>> op_b[4:0];
            4'b1000: alu_out = ($signed(op_a) < $signed(op_b)) ? 32'b1 : 32'b0;
            4'b1001: alu_out = (op_a < op_b) ? 32'b1 : 32'b0;
            default: alu_out = 32'b0;
        endcase
    end

    assign alu_zero = (alu_out == 32'b0);

endmodule


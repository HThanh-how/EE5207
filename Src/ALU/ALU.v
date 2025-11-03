module ALU(
	input[31:0]a,
	input[31:0]b,
	input[3:0]ALU_Sel,
	output[31:0] S
);
	wire [31:0] Add_result, Sub_result, And_result, Or_result, Xor_result;
	wire [31:0] Slt_result, Sltu_result, Sll_result, Srl_result, Sra_result;
	wire Dummy_Cout1, Dummy_Cout2;
	reg [31:0] S_reg;
	
	assign S = S_reg;
	
	ALU_Add add_inst(
		.a(a),
		.b(b),
		.Cin(1'b0),
		.S(Add_result),
		.Cout(Dummy_Cout1)
	);
	
	ALU_Sub sub_inst(
		.a(a),
		.b(b),
		.Cin(1'b1),
		.S(Sub_result),
		.Cout(Dummy_Cout2)
	);

	ALU_And and_inst(
		.a(a),
		.b(b),
		.S(And_result)
	);
	
	ALU_Or or_inst(
		.a(a),
		.b(b),
		.S(Or_result)
	);
	
	ALU_Xor xor_inst(
		.a(a),
		.b(b),
		.S(Xor_result)
	);
	
	ALU_Sll sll_inst(
		.a(a),
		.shamt(b[4:0]),
		.S(Sll_result)
	);
	
	ALU_Srl srl_inst(
		.a(a),
		.shamt(b[4:0]),
		.S(Srl_result)
	);
	
	ALU_Sra sra_inst(
		.a(a),
		.shamt(b[4:0]),
		.S(Sra_result)
	);
	
	ALU_Slt slt_inst(
		.a(a),
		.b(b),
		.S(Slt_result)
	);	

	ALU_Sltu sltu_inst(
		.a(a),
		.b(b),
		.S(Sltu_result)
	);	


    always @(*) begin
        case (ALU_Sel)
            4'b0000: S_reg = Add_result;
            4'b0001: S_reg = Sub_result;
            4'b0010: S_reg = And_result;
            4'b0011: S_reg = Or_result;
            4'b0100: S_reg = Xor_result;
            4'b0101: S_reg = Slt_result;
            4'b0110: S_reg = Sltu_result;
            4'b0111: S_reg = Sll_result;
            4'b1000: S_reg = Srl_result;
            4'b1001: S_reg = Sra_result;
            default: S_reg = 32'b0;
        endcase
    end
endmodule 
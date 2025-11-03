module ALU_Xor(
	input[31:0]a,
	input[31:0]b,
	output[31:0]S
);

	assign S = a ^ b;
endmodule
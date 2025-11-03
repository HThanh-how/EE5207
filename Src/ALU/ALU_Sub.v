module ALU_Sub(
	input [31:0]a, 
	input [31:0]b, 
	input Cin, //Value 1
	output [31:0]S,
	output Cout
);
	wire [31:0] b_n = ~b;
	
	ALU_Add uut (
        .a(a),
        .b(b_n),
        .Cin(Cin),
        .S(S),
		.Cout(Cout)
    );
endmodule
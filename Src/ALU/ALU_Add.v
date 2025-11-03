module ALU_Add(
	input [31:0]a, 
	input [31:0]b, 
	input Cin, 
	output [31:0]S,
	output Cout
);
	wire [30:0]Cout_internal;
	full_adder fa0  (.a(a[0]),  .b(b[0]),  .Cin(Cin),        .S(S[0]),  .Cout(Cout_internal[0]));
	full_adder fa1  (.a(a[1]),  .b(b[1]),  .Cin(Cout_internal[0]),    .S(S[1]),  .Cout(Cout_internal[1]));
	full_adder fa2  (.a(a[2]),  .b(b[2]),  .Cin(Cout_internal[1]),    .S(S[2]),  .Cout(Cout_internal[2]));
	full_adder fa3  (.a(a[3]),  .b(b[3]),  .Cin(Cout_internal[2]),    .S(S[3]),  .Cout(Cout_internal[3]));
	full_adder fa4  (.a(a[4]),  .b(b[4]),  .Cin(Cout_internal[3]),    .S(S[4]),  .Cout(Cout_internal[4]));
	full_adder fa5  (.a(a[5]),  .b(b[5]),  .Cin(Cout_internal[4]),    .S(S[5]),  .Cout(Cout_internal[5]));
	full_adder fa6  (.a(a[6]),  .b(b[6]),  .Cin(Cout_internal[5]),    .S(S[6]),  .Cout(Cout_internal[6]));
	full_adder fa7  (.a(a[7]),  .b(b[7]),  .Cin(Cout_internal[6]),    .S(S[7]),  .Cout(Cout_internal[7]));
	full_adder fa8  (.a(a[8]),  .b(b[8]),  .Cin(Cout_internal[7]),    .S(S[8]),  .Cout(Cout_internal[8]));
	full_adder fa9  (.a(a[9]),  .b(b[9]),  .Cin(Cout_internal[8]),    .S(S[9]),  .Cout(Cout_internal[9]));
	full_adder fa10 (.a(a[10]), .b(b[10]), .Cin(Cout_internal[9]),    .S(S[10]), .Cout(Cout_internal[10]));
	full_adder fa11 (.a(a[11]), .b(b[11]), .Cin(Cout_internal[10]),   .S(S[11]), .Cout(Cout_internal[11]));
	full_adder fa12 (.a(a[12]), .b(b[12]), .Cin(Cout_internal[11]),   .S(S[12]), .Cout(Cout_internal[12]));
	full_adder fa13 (.a(a[13]), .b(b[13]), .Cin(Cout_internal[12]),   .S(S[13]), .Cout(Cout_internal[13]));
	full_adder fa14 (.a(a[14]), .b(b[14]), .Cin(Cout_internal[13]),   .S(S[14]), .Cout(Cout_internal[14]));
	full_adder fa15 (.a(a[15]), .b(b[15]), .Cin(Cout_internal[14]),   .S(S[15]), .Cout(Cout_internal[15]));
	full_adder fa16 (.a(a[16]), .b(b[16]), .Cin(Cout_internal[15]),   .S(S[16]), .Cout(Cout_internal[16]));
	full_adder fa17 (.a(a[17]), .b(b[17]), .Cin(Cout_internal[16]),   .S(S[17]), .Cout(Cout_internal[17]));
	full_adder fa18 (.a(a[18]), .b(b[18]), .Cin(Cout_internal[17]),   .S(S[18]), .Cout(Cout_internal[18]));
	full_adder fa19 (.a(a[19]), .b(b[19]), .Cin(Cout_internal[18]),   .S(S[19]), .Cout(Cout_internal[19]));
	full_adder fa20 (.a(a[20]), .b(b[20]), .Cin(Cout_internal[19]),   .S(S[20]), .Cout(Cout_internal[20]));
	full_adder fa21 (.a(a[21]), .b(b[21]), .Cin(Cout_internal[20]),   .S(S[21]), .Cout(Cout_internal[21]));
	full_adder fa22 (.a(a[22]), .b(b[22]), .Cin(Cout_internal[21]),   .S(S[22]), .Cout(Cout_internal[22]));
	full_adder fa23 (.a(a[23]), .b(b[23]), .Cin(Cout_internal[22]),   .S(S[23]), .Cout(Cout_internal[23]));
	full_adder fa24 (.a(a[24]), .b(b[24]), .Cin(Cout_internal[23]),   .S(S[24]), .Cout(Cout_internal[24]));
	full_adder fa25 (.a(a[25]), .b(b[25]), .Cin(Cout_internal[24]),   .S(S[25]), .Cout(Cout_internal[25]));
	full_adder fa26 (.a(a[26]), .b(b[26]), .Cin(Cout_internal[25]),   .S(S[26]), .Cout(Cout_internal[26]));
	full_adder fa27 (.a(a[27]), .b(b[27]), .Cin(Cout_internal[26]),   .S(S[27]), .Cout(Cout_internal[27]));
	full_adder fa28 (.a(a[28]), .b(b[28]), .Cin(Cout_internal[27]),   .S(S[28]), .Cout(Cout_internal[28]));
	full_adder fa29 (.a(a[29]), .b(b[29]), .Cin(Cout_internal[28]),   .S(S[29]), .Cout(Cout_internal[29]));
	full_adder fa30 (.a(a[30]), .b(b[30]), .Cin(Cout_internal[29]),   .S(S[30]), .Cout(Cout_internal[30]));
	full_adder fa31 (.a(a[31]), .b(b[31]), .Cin(Cout_internal[30]),   .S(S[31]), .Cout(Cout));	
endmodule
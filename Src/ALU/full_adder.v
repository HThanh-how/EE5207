module full_adder(
	input a, 
	input b, 
	input Cin, 
	output S, 
	output Cout
);
  assign S = a ^ b ^ Cin;
  assign Cout = (a & b) | (b & Cin) | (a & Cin);
endmodule
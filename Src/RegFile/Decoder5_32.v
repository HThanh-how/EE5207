module Decoder5_32(
	input [4:0]in,
	input en,
	output [31:0]out
);
	wire [3:0]en_part;
	Decoder2_4 sel_part(.in(in[4:3]),.en(en),.out(en_part));
	Decoder3_8 part0(.in(in[2:0]),.en(en_part[0]),.out(out[7:0]));
	Decoder3_8 part1(.in(in[2:0]),.en(en_part[1]),.out(out[15:8]));
	Decoder3_8 part2(.in(in[2:0]),.en(en_part[2]),.out(out[23:16]));
	Decoder3_8 part3(.in(in[2:0]),.en(en_part[3]),.out(out[31:24]));
endmodule
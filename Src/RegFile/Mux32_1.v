module Mux32_1(
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire [31:0] in2,
    input  wire [31:0] in3,
    input  wire [31:0] in4,
    input  wire [31:0] in5,
    input  wire [31:0] in6,
    input  wire [31:0] in7,
    input  wire [31:0] in8,
    input  wire [31:0] in9,
    input  wire [31:0] in10,
    input  wire [31:0] in11,
    input  wire [31:0] in12,
    input  wire [31:0] in13,
    input  wire [31:0] in14,
    input  wire [31:0] in15,
    input  wire [31:0] in16,
    input  wire [31:0] in17,
    input  wire [31:0] in18,
    input  wire [31:0] in19,
    input  wire [31:0] in20,
    input  wire [31:0] in21,
    input  wire [31:0] in22,
    input  wire [31:0] in23,
    input  wire [31:0] in24,
    input  wire [31:0] in25,
    input  wire [31:0] in26,
    input  wire [31:0] in27,
    input  wire [31:0] in28,
    input  wire [31:0] in29,
    input  wire [31:0] in30,
    input  wire [31:0] in31,
    input  wire [4:0]  sel,   // 5-bit select
    output wire [31:0] out
);

	wire [31:0]out_part0, out_part1, out_part2, out_part3 ;
	wire [31:0]out_part0_1, out_part2_3;
	
	Mux8_1 part0 (
        .in0(in0), .in1(in1), .in2(in2), .in3(in3),
        .in4(in4), .in5(in5), .in6(in6), .in7(in7),
        .sel(sel[2:0]), .out(out_part0)
    );

	Mux8_1 part1 (
        .in0(in8), .in1(in9), .in2(in10), .in3(in11),
        .in4(in12), .in5(in13), .in6(in14), .in7(in15),
        .sel(sel[2:0]), .out(out_part1)
    );

	Mux8_1 part2 (
        .in0(in16), .in1(in17), .in2(in18), .in3(in19),
        .in4(in20), .in5(in21), .in6(in22), .in7(in23),
        .sel(sel[2:0]), .out(out_part2)
    );
		
	Mux8_1 part3 (
        .in0(in24), .in1(in25), .in2(in26), .in3(in27),
        .in4(in28), .in5(in29), .in6(in30), .in7(in31),
        .sel(sel[2:0]), .out(out_part3)
    );

	Mux2_1 part0_1 (.a(out_part0), .b(out_part1), .sel(sel[3]), .y(out_part0_1));
	Mux2_1 part2_3 (.a(out_part2), .b(out_part3), .sel(sel[3]), .y(out_part2_3));
	Mux2_1 part_out (.a(out_part0_1), .b(out_part2_3), .sel(sel[4]), .y(out));

endmodule
module Mux8_1 (
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire [31:0] in2,
    input  wire [31:0] in3,
    input  wire [31:0] in4,
    input  wire [31:0] in5,
    input  wire [31:0] in6,
    input  wire [31:0] in7,
    input  wire [2:0]  sel,   // 3-bit select
    output wire [31:0] out
);
    wire [31:0] w [3:0];  // stage 1 results
    wire [31:0] x [1:0];  // stage 2 results

    // Stage 1: select between pairs using sel[0]
    Mux2_1 m0 (.a(in0), .b(in1), .sel(sel[0]), .y(w[0]));
    Mux2_1 m1 (.a(in2), .b(in3), .sel(sel[0]), .y(w[1]));
    Mux2_1 m2 (.a(in4), .b(in5), .sel(sel[0]), .y(w[2]));
    Mux2_1 m3 (.a(in6), .b(in7), .sel(sel[0]), .y(w[3]));

    // Stage 2: select between groups using sel[1]
    Mux2_1 m4 (.a(w[0]), .b(w[1]), .sel(sel[1]), .y(x[0]));
    Mux2_1 m5 (.a(w[2]), .b(w[3]), .sel(sel[1]), .y(x[1]));

    // Stage 3: final selection using sel[2]
    Mux2_1 m6 (.a(x[0]), .b(x[1]), .sel(sel[2]), .y(out));
endmodule
module Decoder2_4(
    input [1:0] in,     // Input 2-bit
    input en,		// Enable
    output [3:0] out    // Output 4-bit
);
    assign out[0] = en & ~in[1] & ~in[0]; // 00
    assign out[1] = en & ~in[1] &  in[0]; // 01
    assign out[2] = en &  in[1] & ~in[0]; // 10
    assign out[3] = en &  in[1] &  in[0]; // 11
endmodule
module Decoder3_8(
    input [2:0] in,     // Ngõ vào 3 bit
    input en,           // Tín hi?u kích ho?t
    output [7:0] out    // Ngõ ra 8 bit
);

    assign out[0] = en & ~in[2] & ~in[1] & ~in[0];
    assign out[1] = en & ~in[2] & ~in[1] &  in[0];
    assign out[2] = en & ~in[2] &  in[1] & ~in[0];
    assign out[3] = en & ~in[2] &  in[1] &  in[0];
    assign out[4] = en &  in[2] & ~in[1] & ~in[0];
    assign out[5] = en &  in[2] & ~in[1] &  in[0];
    assign out[6] = en &  in[2] &  in[1] & ~in[0];
    assign out[7] = en &  in[2] &  in[1] &  in[0];

endmodule

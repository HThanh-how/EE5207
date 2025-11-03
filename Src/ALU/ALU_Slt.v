module ALU_Slt (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] S
);
    wire [31:0] diff;
    wire sign_a, sign_b, sign_diff, overflow;
    wire Cout; // carry out from ALU_Sub

    // Use ALU_Sub to compute a - b
    ALU_Sub sub_inst (
        .a(a),
        .b(b),
        .Cin(1'b1),   // Cin=1 to perform a - b
        .S(diff),
        .Cout(Cout)   // new output from ALU_Sub
    );

    assign sign_a    = a[31];
    assign sign_b    = b[31];
    assign sign_diff = diff[31];

    // Overflow occurs when a and b have different signs,
    // and the result sign differs from sign_a
    assign overflow = (sign_a & ~sign_b & ~sign_diff) |
                      (~sign_a & sign_b & sign_diff);

    // SLT result: if (overflow ^ sign_diff) = 1 then a < b
    assign S = (overflow ^ sign_diff) ? 32'd1 : 32'd0;

endmodule
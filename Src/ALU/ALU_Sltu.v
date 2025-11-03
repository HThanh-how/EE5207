module ALU_Sltu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] S
);
    wire [31:0] diff;
    wire        Cout;

    // Use ALU_Sub to compute a - b
    ALU_Sub sub_inst (
        .a(a),
        .b(b),
        .Cin(1'b1),   // Cin=1 to perform a - b
        .S(diff),
        .Cout(Cout)
    );

    // For unsigned comparison:
    // If carry_out = 0 → a < b
    assign S = (Cout == 1'b0) ? 32'd1 : 32'd0;

endmodule
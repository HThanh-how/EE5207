module ALU_Sra (
    input  [31:0] a,
    input  [4:0]  shamt,
    output [31:0] S
);
    wire [31:0] s1, s2, s3, s4;

    // Stage 0: shift right by 1 bit of a[31] if shamt[0] = 1
    assign s1 = shamt[0] ? {a[31], a[31:1]} : a;

    // Stage 1: shift right by 2 bits of a[31] if shamt[1] = 1
    assign s2 = shamt[1] ? {{2{s1[31]}}, s1[31:2]} : s1;

    // Stage 2: shift right by 4 bits of a[31] if shamt[2] = 1
    assign s3 = shamt[2] ? {{4{s2[31]}}, s2[31:4]} : s2;

    // Stage 3: shift right by 8 bits of a[31] if shamt[3] = 1
    assign s4 = shamt[3] ? {{8{s3[31]}}, s3[31:8]} : s3;

    // Stage 4: shift right by 16 bits of a[31] if shamt[4] = 1
    assign S  = shamt[4] ? {{16{s4[31]}}, s4[31:16]} : s4;

endmodule
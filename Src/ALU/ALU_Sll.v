module ALU_Sll (
    input  [31:0] a,
    input  [4:0]  shamt,
    output [31:0] S
);
    wire [31:0] s1, s2, s3, s4;

    // Stage 0: shift left by 1 bit if shamt[0] = 1
    assign s1 = shamt[0] ? {a[30:0], 1'b0} : a;

    // Stage 1: shift left by 2 bits if shamt[1] = 1
    assign s2 = shamt[1] ? {s1[29:0], 2'b00} : s1;

    // Stage 2: shift left by 4 bits if shamt[2] = 1
    assign s3 = shamt[2] ? {s2[27:0], 4'b0000} : s2;

    // Stage 3: shift left by 8 bits if shamt[3] = 1
    assign s4 = shamt[3] ? {s3[23:0], 8'h00} : s3;

    // Stage 4: shift left by 16 bits if shamt[4] = 1
    assign S  = shamt[4] ? {s4[15:0], 16'h0000} : s4;

endmodule
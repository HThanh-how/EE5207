module Mux2_1 (
    input  wire [31:0] a,    // Input1 (32-bit)
    input  wire [31:0] b,    // Input2 (32-bit)
    input  wire        sel,  // Select input
    output wire [31:0] y     // Output (32-bit)
);
    assign y = (sel) ? b : a;
endmodule

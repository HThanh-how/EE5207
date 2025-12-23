//----------------------------------------------------------------------//
// Data Memory Module
// - Synchronous write, asynchronous read for simulation
// - Supports byte, halfword, and word access
// - Pre-loaded with memory file
//----------------------------------------------------------------------//

module data_mem #(
    parameter MEM_DEPTH = 16384,  // Number of 32-bit words (64KB = 16K words)
    parameter MEM_FILE  = "../02_test/isa_4b.hex"
)(
    input  logic        i_clk,
    input  logic [13:0] i_addr,     // Word address (14 bits for 16K words)
    input  logic [31:0] i_wdata,    // Write data
    input  logic [ 3:0] i_we,       // Byte write enables
    output logic [31:0] o_rdata     // Read data
);

    // Memory array
    logic [31:0] mem [0:MEM_DEPTH-1];

    // Initialize memory - first zero everything, then load hex file
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h0;
        end
        $readmemh(MEM_FILE, mem);
    end

    // Synchronous write with byte enables
    always_ff @(posedge i_clk) begin
        if (i_we[0]) mem[i_addr][7:0]   <= i_wdata[7:0];
        if (i_we[1]) mem[i_addr][15:8]  <= i_wdata[15:8];
        if (i_we[2]) mem[i_addr][23:16] <= i_wdata[23:16];
        if (i_we[3]) mem[i_addr][31:24] <= i_wdata[31:24];
    end

    // Asynchronous read (combinational) for simulation
    assign o_rdata = mem[i_addr];

endmodule : data_mem

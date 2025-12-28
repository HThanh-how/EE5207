//----------------------------------------------------------------------//
// Instruction Memory Module
// - Asynchronous read for simulation (combinational)
// - For synthesis, use BRAM with registered output
// - Pre-loaded with memory file
//----------------------------------------------------------------------//

module instr_mem #(
    parameter MEM_DEPTH = 16384,  // Number of 32-bit words (64KB = 16K words)
    parameter MEM_FILE  = "../02_test/isa_4b.hex"
)(
    input  logic        i_clk,
    input  logic [13:0] i_addr,   // Word address (14 bits for 16K words)
    output logic [31:0] o_instr
);

    // Memory array
    logic [31:0] mem [0:MEM_DEPTH-1];

    integer imem_idx;
    initial begin
        for (imem_idx = 0; imem_idx < MEM_DEPTH; imem_idx = imem_idx + 1) begin
            mem[imem_idx] = 32'h00000013;  // NOP
        end
        $readmemh(MEM_FILE, mem);
    end

    assign o_instr = mem[i_addr];

endmodule : instr_mem


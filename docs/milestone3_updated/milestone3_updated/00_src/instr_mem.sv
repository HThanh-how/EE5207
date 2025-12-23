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

    // Initialize memory - first zero everything (NOP), then load hex file
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013;  // NOP (addi x0, x0, 0)
        end
        $readmemh(MEM_FILE, mem);
    end

    // Asynchronous read (combinational) - suitable for simulation
    // The pipeline register in IF/ID stage provides the necessary registration
    assign o_instr = mem[i_addr];

endmodule : instr_mem

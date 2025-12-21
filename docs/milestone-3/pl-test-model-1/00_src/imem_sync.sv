// Synchronous Instruction Memory for Pipelined Processor
// 64 KiB memory as required by Milestone 3
// Uses BRAM for synthesis (altsyncram in Quartus)
module imem_sync (
    input  logic         clk,
    input  logic         enable,
    input  logic [31:0]  addr,
    output logic [31:0]  rdata
);

    parameter MEM_SIZE = 65536;  // 64 KiB
    parameter ADDR_WIDTH = $clog2(MEM_SIZE);

    logic [7:0] mem [0:MEM_SIZE-1];
    logic [ADDR_WIDTH-1:0] byte_addr;

    initial begin
`ifdef DEMO_MEM
        // Demo mode: load small test program
        $readmemh("../02_test/demo.mem", mem);
`else
        // Load isa_1b.hex (byte-per-line format, little-endian)
        $display("[IMEM_SYNC] Loading ../02_test/isa_1b.hex");
        $readmemh("../02_test/isa_1b.hex", mem);
`endif
    end

    assign byte_addr = addr[ADDR_WIDTH-1:0];

    // Synchronous read (BRAM compatible)
    always_ff @(posedge clk) begin
        if (enable) begin
            if (byte_addr+3 < MEM_SIZE) begin
                rdata <= {mem[byte_addr+3], mem[byte_addr+2], mem[byte_addr+1], mem[byte_addr]};
            end else begin
                rdata <= 32'b0;
            end
        end
    end

endmodule

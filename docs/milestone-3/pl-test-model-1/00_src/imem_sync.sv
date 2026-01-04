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
    parameter WORD_DEPTH = MEM_SIZE / 4;  // Number of 32-bit words

    logic [7:0] mem [0:MEM_SIZE-1];
    logic [ADDR_WIDTH-1:0] byte_addr;
    logic [31:0] word_mem [0:WORD_DEPTH-1];  // Temporary word array for loading isa_4b.hex

    integer i;
    initial begin
`ifdef DEMO_MEM
        // Demo mode: load small test program
        $readmemh("../02_test/demo.mem", mem);
`else
        // Try to load isa.mem first (server format)
        begin
            integer file_handle;
            file_handle = $fopen("../02_test/isa.mem", "r");
            if (file_handle != 0) begin
                $fclose(file_handle);
                $display("[IMEM_SYNC] Loading ../02_test/isa.mem");
                $readmemh("../02_test/isa.mem", mem);
            end
            // Fallback to isa_4b.hex (word-per-line format)
            else begin
            $display("[IMEM_SYNC] ../02_test/isa.mem not found. Loading ../02_test/isa_4b.hex with manual word-to-byte unpacking");
            // Initialize word memory
            for (i = 0; i < WORD_DEPTH; i = i + 1) begin
                word_mem[i] = 32'h00000013;  // NOP
            end
            // Load isa_4b.hex (word-per-line format)
            $readmemh("../02_test/isa_4b.hex", word_mem);
            // Convert word array to byte array (little-endian)
            for (i = 0; i < WORD_DEPTH; i = i + 1) begin
                mem[i*4 + 0] = word_mem[i][7:0];
                mem[i*4 + 1] = word_mem[i][15:8];
                mem[i*4 + 2] = word_mem[i][23:16];
                mem[i*4 + 3] = word_mem[i][31:24];
            end
            $display("[IMEM_SYNC] Loaded %0d words from isa_4b.hex", WORD_DEPTH);
            end
        end
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



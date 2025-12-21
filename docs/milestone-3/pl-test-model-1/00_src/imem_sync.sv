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
        integer fd;
        integer code;
        // integer word_int; // Removed
        logic [31:0] word;
        integer addr_idx;
        string  line_buf;  // buffer for skipping malformed lines
`ifdef DEMO_MEM
        // Demo mode: load small test program
        $readmemh("../02_test/demo.mem", mem);
`else
        // 1) Try server-preferred isa.mem (byte-per-line)
        fd = $fopen("../02_test/isa.mem", "r");
        if (fd) begin
            $display("[IMEM_SYNC] Loading ../02_test/isa.mem");
            $fclose(fd);
            $readmemh("../02_test/isa.mem", mem);
        end else begin
            // 2) Try word-wide isa_4b.hex (32-bit/line) - preferred format
            fd = $fopen("../02_test/isa_4b.hex", "r");
            if (fd) begin
                $display("[IMEM_SYNC] ../02_test/isa.mem not found. Loading ../02_test/isa_4b.hex with manual word-to-byte unpacking");
                addr_idx = 0;
                while (!$feof(fd) && (addr_idx + 3) < MEM_SIZE) begin
                    code = $fscanf(fd, "%h", word);
                    if (code == 1) begin
                        // Word is already logic [31:0]
                        mem[addr_idx+0] = word[7:0];
                        mem[addr_idx+1] = word[15:8];
                        mem[addr_idx+2] = word[23:16];
                        mem[addr_idx+3] = word[31:24];
                        addr_idx = addr_idx + 4;
                    end else begin
                        // Skip malformed line
                        void'($fgets(line_buf, fd));
                    end
                end
                $fclose(fd);
                $display("[IMEM_SYNC] Loaded %0d words from isa_4b.hex", addr_idx/4);
            end else begin
                // 3) Last resort: byte-wide isa_1b.hex (Milestone 2/3 common format)
                fd = $fopen("../02_test/isa_1b.hex", "r");
                if (fd) begin
                    $display("[IMEM_SYNC] Loading ../02_test/isa_1b.hex");
                    $fclose(fd);
                    $readmemh("../02_test/isa_1b.hex", mem);
                end else begin
                    $display("[IMEM_SYNC] ERROR: No isa.mem / isa_4b.hex / isa_1b.hex found");
                end
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


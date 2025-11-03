module imem (
    input  logic [31:0]  addr,
    output logic [31:0]  rdata
);

    parameter MEM_SIZE = 16384;
    parameter ADDR_WIDTH = $clog2(MEM_SIZE);

    logic [7:0] mem [0:MEM_SIZE-1];
    logic [ADDR_WIDTH-1:0] byte_addr;

    initial begin
        integer fd;
`ifdef DEMO_MEM
        $readmemh("../02_test/demo.mem", mem);
`else
        // Prefer server-required file isa.mem; if missing (local), fallback to isa_1b.hex
        fd = $fopen("../02_test/isa.mem", "r");
        if (fd) begin
            $fclose(fd);
            $readmemh("../02_test/isa.mem", mem);
        end else begin
            $display("[IMEM] ../02_test/isa.mem not found. Falling back to ../02_test/isa_1b.hex");
            $readmemh("../02_test/isa_1b.hex", mem);
        end
`endif
    end

    assign byte_addr = addr[ADDR_WIDTH-1:0];

    assign rdata = {mem[byte_addr+3], mem[byte_addr+2], mem[byte_addr+1], mem[byte_addr]};

endmodule


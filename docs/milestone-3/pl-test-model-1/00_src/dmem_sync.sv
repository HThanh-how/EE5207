// Synchronous Data Memory for Pipelined Processor
// 64 KiB memory as required by Milestone 3
module dmem_sync (
    input  logic         clk,
    input  logic         enable,
    input  logic         we,
    input  logic [31:0]  addr,
    input  logic [31:0]  wdata,
    input  logic [ 2:0]  mem_size,
    output logic [31:0]  rdata
);

    parameter MEM_SIZE = 65536;  // 64 KiB
    parameter ADDR_WIDTH = $clog2(MEM_SIZE);

    logic [7:0] mem [0:MEM_SIZE-1];
    logic [ADDR_WIDTH-1:0] byte_addr;

    assign byte_addr = addr[ADDR_WIDTH-1:0];

    // Synchronous write
    always_ff @(posedge clk) begin
        if (enable) begin
            if (we && byte_addr < MEM_SIZE) begin
                case (mem_size)
                    // SB
                    3'b000: begin
                        mem[byte_addr] <= wdata[7:0];
                    end
                    // SH (little-endian)
                    3'b001: begin
                        if (byte_addr+1 < MEM_SIZE) begin
                            mem[byte_addr]     <= wdata[7:0];
                            mem[byte_addr+1]   <= wdata[15:8];
                        end
                    end
                    // SW (little-endian)
                    3'b010: begin
                        if (byte_addr+3 < MEM_SIZE) begin
                            mem[byte_addr]     <= wdata[7:0];
                            mem[byte_addr+1]   <= wdata[15:8];
                            mem[byte_addr+2]   <= wdata[23:16];
                            mem[byte_addr+3]   <= wdata[31:24];
                        end
                    end
                    default: begin
                        if (byte_addr+3 < MEM_SIZE) begin
                            mem[byte_addr]     <= wdata[7:0];
                            mem[byte_addr+1]   <= wdata[15:8];
                            mem[byte_addr+2]   <= wdata[23:16];
                            mem[byte_addr+3]   <= wdata[31:24];
                        end
                    end
                endcase
            end
        end
    end

    // Synchronous read
    always_ff @(posedge clk) begin
        if (enable) begin
            if (byte_addr >= MEM_SIZE) begin
                rdata <= 32'b0;
            end else begin
                case (mem_size)
                    // LB: sign-extend byte at byte_addr
                    3'b000: rdata <= {{24{mem[byte_addr][7]}}, mem[byte_addr]};
                    // LH: sign-extend halfword starting at byte_addr (little-endian)
                    3'b001: rdata <= (byte_addr+1 < MEM_SIZE)
                                       ? {{16{mem[byte_addr+1][7]}}, mem[byte_addr+1], mem[byte_addr]}
                                       : {{16{mem[byte_addr][7]}}, mem[byte_addr], 16'b0};
                    // LW: word starting at byte_addr (little-endian)
                    3'b010: rdata <= (byte_addr+3 < MEM_SIZE)
                                       ? {mem[byte_addr+3], mem[byte_addr+2], mem[byte_addr+1], mem[byte_addr]}
                                       : 32'b0;
                    // LBU: zero-extend byte
                    3'b100: rdata <= {24'b0, mem[byte_addr]};
                    // LHU: zero-extend halfword
                    3'b101: rdata <= (byte_addr+1 < MEM_SIZE)
                                       ? {16'b0, mem[byte_addr+1], mem[byte_addr]}
                                       : {16'b0, mem[byte_addr], 16'b0};
                    default: rdata <= (byte_addr+3 < MEM_SIZE)
                                       ? {mem[byte_addr+3], mem[byte_addr+2], mem[byte_addr+1], mem[byte_addr]}
                                       : 32'b0;
                endcase
            end
        end
    end

endmodule




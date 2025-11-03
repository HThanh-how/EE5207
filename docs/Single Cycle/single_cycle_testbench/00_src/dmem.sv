module dmem (
    input  logic         clk,
    input  logic         we,
    input  logic [31:0]  addr,
    input  logic [31:0]  wdata,
    input  logic [ 2:0]  mem_size,
    output logic [31:0]  rdata
);

    parameter MEM_SIZE = 2048;
    parameter ADDR_WIDTH = $clog2(MEM_SIZE);

    logic [7:0] mem [0:MEM_SIZE-1];
    logic [ADDR_WIDTH-1:0] byte_addr;
    logic [31:0] word_addr;

    assign byte_addr = addr[ADDR_WIDTH-1:0];
    assign word_addr = {addr[ADDR_WIDTH-1:2], 2'b00};

    always_ff @(posedge clk) begin
        if (we && word_addr < MEM_SIZE) begin
            case (mem_size)
                3'b000: mem[word_addr] <= wdata[7:0];
                3'b001: begin
                    if (word_addr+1 < MEM_SIZE) begin
                        mem[word_addr]   <= wdata[7:0];
                        mem[word_addr+1] <= wdata[15:8];
                    end
                end
                3'b010: begin
                    if (word_addr+3 < MEM_SIZE) begin
                        mem[word_addr]   <= wdata[7:0];
                        mem[word_addr+1] <= wdata[15:8];
                        mem[word_addr+2] <= wdata[23:16];
                        mem[word_addr+3] <= wdata[31:24];
                    end
                end
                default: begin
                    if (word_addr+3 < MEM_SIZE) begin
                        mem[word_addr]   <= wdata[7:0];
                        mem[word_addr+1] <= wdata[15:8];
                        mem[word_addr+2] <= wdata[23:16];
                        mem[word_addr+3] <= wdata[31:24];
                    end
                end
            endcase
        end
    end

    always_comb begin
        if (word_addr >= MEM_SIZE) begin
            rdata = 32'b0;
        end else begin
            case (mem_size)
                3'b000: rdata = {{24{mem[word_addr][7]}}, mem[word_addr]};
                3'b001: rdata = (word_addr+1 < MEM_SIZE) ? {{16{mem[word_addr+1][7]}}, mem[word_addr+1], mem[word_addr]} : {{16{mem[word_addr][7]}}, mem[word_addr], 16'b0};
                3'b010: rdata = (word_addr+3 < MEM_SIZE) ? {mem[word_addr+3], mem[word_addr+2], mem[word_addr+1], mem[word_addr]} : 32'b0;
                3'b100: rdata = {24'b0, mem[word_addr]};
                3'b101: rdata = (word_addr+1 < MEM_SIZE) ? {16'b0, mem[word_addr+1], mem[word_addr]} : {16'b0, mem[word_addr], 16'b0};
                default: rdata = (word_addr+3 < MEM_SIZE) ? {mem[word_addr+3], mem[word_addr+2], mem[word_addr+1], mem[word_addr]} : 32'b0;
            endcase
        end
    end

endmodule


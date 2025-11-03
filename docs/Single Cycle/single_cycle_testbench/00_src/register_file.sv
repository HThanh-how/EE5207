module register_file (
    input  logic         clk,
    input  logic         we,
    input  logic [ 4:0]  addr_rs1,
    input  logic [ 4:0]  addr_rs2,
    input  logic [ 4:0]  addr_rd,
    input  logic [31:0]  wdata,
    output logic [31:0]  rdata_rs1,
    output logic [31:0]  rdata_rs2
);

    logic [31:0] registers [0:31];

    always_ff @(posedge clk) begin
        if (we && addr_rd != 0) begin
            registers[addr_rd] <= wdata;
        end
    end

    assign rdata_rs1 = (addr_rs1 == 0) ? 32'b0 : registers[addr_rs1];
    assign rdata_rs2 = (addr_rs2 == 0) ? 32'b0 : registers[addr_rs2];

endmodule


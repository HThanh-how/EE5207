//----------------------------------------------------------------------//
// Register File Module
// - 32 x 32-bit registers
// - x0 is hardwired to zero
// - 2 read ports, 1 write port
// - Write-through: read returns new value if writing same register
//----------------------------------------------------------------------//

module reg_file (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic [ 4:0] i_rs1_addr,
    input  logic [ 4:0] i_rs2_addr,
    input  logic [ 4:0] i_rd_addr,
    input  logic [31:0] i_rd_data,
    input  logic        i_wr_en,
    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data
);

    // Register array
    logic [31:0] regs [0:31];

    // Initialize registers
    integer reg_idx;
    initial begin
        for (reg_idx = 0; reg_idx < 32; reg_idx = reg_idx + 1) begin
            regs[reg_idx] = 32'h0;
        end
    end

    // Write port (synchronous)
    always_ff @(posedge i_clk) begin
        if (i_wr_en && (i_rd_addr != 5'h0)) begin
            regs[i_rd_addr] <= i_rd_data;
        end
    end

    // Read ports with write-through
    always_comb begin
        if (i_rs1_addr == 5'h0) begin
            o_rs1_data = 32'h0;
        end else if (i_wr_en && (i_rs1_addr == i_rd_addr)) begin
            o_rs1_data = i_rd_data;
        end else begin
            o_rs1_data = regs[i_rs1_addr];
        end
    end

    always_comb begin
        if (i_rs2_addr == 5'h0) begin
            o_rs2_data = 32'h0;
        end else if (i_wr_en && (i_rs2_addr == i_rd_addr)) begin
            o_rs2_data = i_rd_data;
        end else begin
            o_rs2_data = regs[i_rs2_addr];
        end
    end

endmodule : reg_file


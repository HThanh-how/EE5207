//----------------------------------------------------------------------//
// Forwarding Unit
// - Detects when forwarding is needed
// - Outputs forwarding control signals for ALU operands
//----------------------------------------------------------------------//

module forwarding_unit (
    // Source register addresses in EX stage
    input  logic [ 4:0] i_rs1_addr_ex,
    input  logic [ 4:0] i_rs2_addr_ex,
    // Destination registers in later stages
    input  logic [ 4:0] i_rd_addr_mem,
    input  logic [ 4:0] i_rd_addr_wb,
    // Register write enables
    input  logic        i_reg_wr_en_mem,
    input  logic        i_reg_wr_en_wb,
    // Forwarding control signals
    output logic [ 1:0] o_forward_a,
    output logic [ 1:0] o_forward_b
);

    // Forwarding selection codes:
    // 2'b00 - No forwarding (use register file output)
    // 2'b01 - Forward from WB stage
    // 2'b10 - Forward from MEM stage

    // Forwarding for operand A (rs1)
    always_comb begin
        if (i_reg_wr_en_mem && (i_rd_addr_mem != 5'h0) && (i_rd_addr_mem == i_rs1_addr_ex)) begin
            // Forward from MEM stage (higher priority - more recent instruction)
            o_forward_a = 2'b10;
        end else if (i_reg_wr_en_wb && (i_rd_addr_wb != 5'h0) && (i_rd_addr_wb == i_rs1_addr_ex)) begin
            // Forward from WB stage
            o_forward_a = 2'b01;
        end else begin
            // No forwarding needed
            o_forward_a = 2'b00;
        end
    end

    // Forwarding for operand B (rs2)
    always_comb begin
        if (i_reg_wr_en_mem && (i_rd_addr_mem != 5'h0) && (i_rd_addr_mem == i_rs2_addr_ex)) begin
            // Forward from MEM stage (higher priority - more recent instruction)
            o_forward_b = 2'b10;
        end else if (i_reg_wr_en_wb && (i_rd_addr_wb != 5'h0) && (i_rd_addr_wb == i_rs2_addr_ex)) begin
            // Forward from WB stage
            o_forward_b = 2'b01;
        end else begin
            // No forwarding needed
            o_forward_b = 2'b00;
        end
    end

endmodule : forwarding_unit

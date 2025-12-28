//----------------------------------------------------------------------//
// Forwarding Unit
// - Detects when forwarding is needed
// - Outputs forwarding control signals for ALU operands
//----------------------------------------------------------------------//

module forwarding_unit (
    input  logic [ 4:0] i_rs1_addr_ex,
    input  logic [ 4:0] i_rs2_addr_ex,
    input  logic [ 4:0] i_rd_addr_mem,
    input  logic [ 4:0] i_rd_addr_wb,
    input  logic        i_reg_wr_en_mem,
    input  logic        i_reg_wr_en_wb,
    output logic [ 1:0] o_forward_a,
    output logic [ 1:0] o_forward_b
);

    always_comb begin
        if (i_reg_wr_en_mem && (i_rd_addr_mem != 5'h0) && (i_rd_addr_mem == i_rs1_addr_ex)) begin
            o_forward_a = 2'b10;
        end else if (i_reg_wr_en_wb && (i_rd_addr_wb != 5'h0) && (i_rd_addr_wb == i_rs1_addr_ex)) begin
            o_forward_a = 2'b01;
        end else begin
            o_forward_a = 2'b00;
        end
    end

    always_comb begin
        if (i_reg_wr_en_mem && (i_rd_addr_mem != 5'h0) && (i_rd_addr_mem == i_rs2_addr_ex)) begin
            o_forward_b = 2'b10;
        end else if (i_reg_wr_en_wb && (i_rd_addr_wb != 5'h0) && (i_rd_addr_wb == i_rs2_addr_ex)) begin
            o_forward_b = 2'b01;
        end else begin
            o_forward_b = 2'b00;
        end
    end

endmodule : forwarding_unit


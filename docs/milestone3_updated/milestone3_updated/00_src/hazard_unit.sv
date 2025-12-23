//----------------------------------------------------------------------//
// Hazard Detection Unit
// - Detects data hazards and control hazards
// - Generates stall and flush signals
// - Supports both forwarding and non-forwarding modes
//----------------------------------------------------------------------//

module hazard_unit #(
    parameter FORWARDING_EN = 1  // 1: Forwarding enabled, 0: Non-forwarding
)(
    // Source registers in ID stage
    input  logic [ 4:0] i_rs1_addr_id,
    input  logic [ 4:0] i_rs2_addr_id,
    // Destination registers in pipeline stages
    input  logic [ 4:0] i_rd_addr_ex,
    input  logic [ 4:0] i_rd_addr_mem,
    input  logic [ 4:0] i_rd_addr_wb,
    // Register write enables
    input  logic        i_reg_wr_en_ex,
    input  logic        i_reg_wr_en_mem,
    input  logic        i_reg_wr_en_wb,
    // Load instruction detection
    input  logic        i_is_load_ex,
    // Branch taken signal
    input  logic        i_br_taken,
    // Stall signals
    output logic        o_stall_if,
    output logic        o_stall_id,
    // Flush signals
    output logic        o_flush_id,
    output logic        o_flush_ex,
    output logic        o_flush_mem
);

    // Internal signals
    logic load_use_hazard;
    logic data_hazard_ex;
    logic data_hazard_mem;
    logic data_hazard_wb;

    generate
        if (FORWARDING_EN) begin : gen_forwarding_hazards
            //------------------------------------------------------------------
            // Forwarding Mode: Only stall for load-use hazards
            //------------------------------------------------------------------

            // Load-use hazard: Load in EX stage followed by dependent instruction
            assign load_use_hazard = i_is_load_ex && i_reg_wr_en_ex && (i_rd_addr_ex != 5'h0) &&
                                    ((i_rd_addr_ex == i_rs1_addr_id) || (i_rd_addr_ex == i_rs2_addr_id));

            // Stall IF and ID for load-use hazard
            assign o_stall_if = load_use_hazard;
            assign o_stall_id = load_use_hazard;

            // Flush ID stage on branch taken
            assign o_flush_id = i_br_taken;

            // Flush EX stage on branch taken or load-use hazard (insert bubble)
            assign o_flush_ex = i_br_taken | load_use_hazard;

            // No need to flush MEM stage normally
            assign o_flush_mem = 1'b0;

        end else begin : gen_no_forwarding_hazards
            //------------------------------------------------------------------
            // Non-forwarding Mode: Stall for all RAW hazards
            //------------------------------------------------------------------

            // Check for data hazards with EX stage
            assign data_hazard_ex = i_reg_wr_en_ex && (i_rd_addr_ex != 5'h0) &&
                                   ((i_rd_addr_ex == i_rs1_addr_id) || (i_rd_addr_ex == i_rs2_addr_id));

            // Check for data hazards with MEM stage
            assign data_hazard_mem = i_reg_wr_en_mem && (i_rd_addr_mem != 5'h0) &&
                                    ((i_rd_addr_mem == i_rs1_addr_id) || (i_rd_addr_mem == i_rs2_addr_id));

            // Check for data hazards with WB stage
            assign data_hazard_wb = i_reg_wr_en_wb && (i_rd_addr_wb != 5'h0) &&
                                   ((i_rd_addr_wb == i_rs1_addr_id) || (i_rd_addr_wb == i_rs2_addr_id));

            // Combined data hazard
            logic data_hazard;
            assign data_hazard = data_hazard_ex | data_hazard_mem | data_hazard_wb;

            // Stall IF and ID for data hazards
            assign o_stall_if = data_hazard;
            assign o_stall_id = data_hazard;

            // Flush ID stage on branch taken
            assign o_flush_id = i_br_taken;

            // Flush EX stage on branch taken or data hazard (insert bubble)
            assign o_flush_ex = i_br_taken | data_hazard;

            // No need to flush MEM stage normally
            assign o_flush_mem = 1'b0;
        end
    endgenerate

endmodule : hazard_unit

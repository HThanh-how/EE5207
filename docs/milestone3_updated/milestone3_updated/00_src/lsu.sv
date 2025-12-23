//----------------------------------------------------------------------//
// Load-Store Unit (LSU)
// - Handles memory access and peripheral I/O mapping
// - Supports byte, halfword, and word access
// - Memory mapping according to milestone-3 specification:
//   0x0000_0000 - 0x0000_FFFF: Memory (64 KiB)
//   0x1000_0000 - 0x1000_0FFF: Red LEDs
//   0x1000_1000 - 0x1000_1FFF: Green LEDs
//   0x1000_2000 - 0x1000_2FFF: Seven-segment LEDs 3-0
//   0x1000_3000 - 0x1000_3FFF: Seven-segment LEDs 7-4
//   0x1000_4000 - 0x1000_4FFF: LCD Control Registers
//   0x1001_0000 - 0x1001_0FFF: Switches
//----------------------------------------------------------------------//

module lsu (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic [31:0] i_addr,
    input  logic [31:0] i_wdata,
    input  logic        i_wr_en,
    input  logic [ 2:0] i_mem_op,
    output logic [31:0] o_rdata,
    // Peripheral interfaces
    input  logic [31:0] i_io_sw,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [ 6:0] o_io_hex0,
    output logic [ 6:0] o_io_hex1,
    output logic [ 6:0] o_io_hex2,
    output logic [ 6:0] o_io_hex3,
    output logic [ 6:0] o_io_hex4,
    output logic [ 6:0] o_io_hex5,
    output logic [ 6:0] o_io_hex6,
    output logic [ 6:0] o_io_hex7,
    output logic [31:0] o_io_lcd
);

    // Memory operation codes (funct3)
    localparam MEM_LB  = 3'b000;  // Load Byte (signed)
    localparam MEM_LH  = 3'b001;  // Load Halfword (signed)
    localparam MEM_LW  = 3'b010;  // Load Word
    localparam MEM_LBU = 3'b100;  // Load Byte Unsigned
    localparam MEM_LHU = 3'b101;  // Load Halfword Unsigned
    localparam MEM_SB  = 3'b000;  // Store Byte
    localparam MEM_SH  = 3'b001;  // Store Halfword
    localparam MEM_SW  = 3'b010;  // Store Word

    // Address decoding
    logic addr_is_mem;
    logic addr_is_ledr;
    logic addr_is_ledg;
    logic addr_is_hex_lo;
    logic addr_is_hex_hi;
    logic addr_is_lcd;
    logic addr_is_sw;

    assign addr_is_mem    = (i_addr[31:16] == 16'h0000);
    assign addr_is_ledr   = (i_addr[31:12] == 20'h1000_0);
    assign addr_is_ledg   = (i_addr[31:12] == 20'h1000_1);
    assign addr_is_hex_lo = (i_addr[31:12] == 20'h1000_2);
    assign addr_is_hex_hi = (i_addr[31:12] == 20'h1000_3);
    assign addr_is_lcd    = (i_addr[31:12] == 20'h1000_4);
    assign addr_is_sw     = (i_addr[31:12] == 20'h1001_0);

    // Byte offset within word
    logic [1:0] byte_offset;
    assign byte_offset = i_addr[1:0];

    // Word address for data memory
    logic [13:0] mem_addr;
    assign mem_addr = i_addr[15:2];

    // Data memory write enable
    logic [3:0] mem_we;
    logic mem_wr_en;
    assign mem_wr_en = i_wr_en && addr_is_mem;

    // Calculate byte write enables based on store type and offset
    always_comb begin
        mem_we = 4'b0000;
        if (mem_wr_en) begin
            case (i_mem_op)
                MEM_SB: begin
                    case (byte_offset)
                        2'b00: mem_we = 4'b0001;
                        2'b01: mem_we = 4'b0010;
                        2'b10: mem_we = 4'b0100;
                        2'b11: mem_we = 4'b1000;
                    endcase
                end
                MEM_SH: begin
                    case (byte_offset[1])
                        1'b0: mem_we = 4'b0011;
                        1'b1: mem_we = 4'b1100;
                    endcase
                end
                MEM_SW: begin
                    mem_we = 4'b1111;
                end
                default: mem_we = 4'b0000;
            endcase
        end
    end

    // Write data alignment
    logic [31:0] aligned_wdata;
    always_comb begin
        case (i_mem_op)
            MEM_SB: begin
                case (byte_offset)
                    2'b00: aligned_wdata = {24'b0, i_wdata[7:0]};
                    2'b01: aligned_wdata = {16'b0, i_wdata[7:0], 8'b0};
                    2'b10: aligned_wdata = {8'b0, i_wdata[7:0], 16'b0};
                    2'b11: aligned_wdata = {i_wdata[7:0], 24'b0};
                endcase
            end
            MEM_SH: begin
                case (byte_offset[1])
                    1'b0: aligned_wdata = {16'b0, i_wdata[15:0]};
                    1'b1: aligned_wdata = {i_wdata[15:0], 16'b0};
                endcase
            end
            default: aligned_wdata = i_wdata;
        endcase
    end

    // Data Memory
    logic [31:0] mem_rdata;
    data_mem #(
        .MEM_DEPTH(16384),
        .MEM_FILE("../02_test/isa_4b.hex")
    ) u_dmem (
        .i_clk  (i_clk),
        .i_addr (mem_addr),
        .i_wdata(aligned_wdata),
        .i_we   (mem_we),
        .o_rdata(mem_rdata)
    );

    // Peripheral Registers
    logic [31:0] reg_ledr;
    logic [31:0] reg_ledg;
    logic [31:0] reg_hex_lo;  // HEX3-0
    logic [31:0] reg_hex_hi;  // HEX7-4
    logic [31:0] reg_lcd;

    // Peripheral write logic
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            reg_ledr   <= 32'h0;
            reg_ledg   <= 32'h0;
            reg_hex_lo <= 32'h0;
            reg_hex_hi <= 32'h0;
            reg_lcd    <= 32'h0;
        end else if (i_wr_en) begin
            if (addr_is_ledr) begin
                case (i_mem_op)
                    MEM_SW: reg_ledr <= i_wdata;
                    MEM_SH: begin
                        if (byte_offset[1])
                            reg_ledr[31:16] <= i_wdata[15:0];
                        else
                            reg_ledr[15:0] <= i_wdata[15:0];
                    end
                    MEM_SB: begin
                        case (byte_offset)
                            2'b00: reg_ledr[7:0]   <= i_wdata[7:0];
                            2'b01: reg_ledr[15:8]  <= i_wdata[7:0];
                            2'b10: reg_ledr[23:16] <= i_wdata[7:0];
                            2'b11: reg_ledr[31:24] <= i_wdata[7:0];
                        endcase
                    end
                    default: ;
                endcase
            end
            if (addr_is_ledg) begin
                case (i_mem_op)
                    MEM_SW: reg_ledg <= i_wdata;
                    MEM_SH: begin
                        if (byte_offset[1])
                            reg_ledg[31:16] <= i_wdata[15:0];
                        else
                            reg_ledg[15:0] <= i_wdata[15:0];
                    end
                    MEM_SB: begin
                        case (byte_offset)
                            2'b00: reg_ledg[7:0]   <= i_wdata[7:0];
                            2'b01: reg_ledg[15:8]  <= i_wdata[7:0];
                            2'b10: reg_ledg[23:16] <= i_wdata[7:0];
                            2'b11: reg_ledg[31:24] <= i_wdata[7:0];
                        endcase
                    end
                    default: ;
                endcase
            end
            if (addr_is_hex_lo) begin
                case (i_mem_op)
                    MEM_SW: reg_hex_lo <= i_wdata;
                    MEM_SH: begin
                        if (byte_offset[1])
                            reg_hex_lo[31:16] <= i_wdata[15:0];
                        else
                            reg_hex_lo[15:0] <= i_wdata[15:0];
                    end
                    MEM_SB: begin
                        case (byte_offset)
                            2'b00: reg_hex_lo[7:0]   <= i_wdata[7:0];
                            2'b01: reg_hex_lo[15:8]  <= i_wdata[7:0];
                            2'b10: reg_hex_lo[23:16] <= i_wdata[7:0];
                            2'b11: reg_hex_lo[31:24] <= i_wdata[7:0];
                        endcase
                    end
                    default: ;
                endcase
            end
            if (addr_is_hex_hi) begin
                case (i_mem_op)
                    MEM_SW: reg_hex_hi <= i_wdata;
                    MEM_SH: begin
                        if (byte_offset[1])
                            reg_hex_hi[31:16] <= i_wdata[15:0];
                        else
                            reg_hex_hi[15:0] <= i_wdata[15:0];
                    end
                    MEM_SB: begin
                        case (byte_offset)
                            2'b00: reg_hex_hi[7:0]   <= i_wdata[7:0];
                            2'b01: reg_hex_hi[15:8]  <= i_wdata[7:0];
                            2'b10: reg_hex_hi[23:16] <= i_wdata[7:0];
                            2'b11: reg_hex_hi[31:24] <= i_wdata[7:0];
                        endcase
                    end
                    default: ;
                endcase
            end
            if (addr_is_lcd) begin
                reg_lcd <= i_wdata;
            end
        end
    end

    // Peripheral outputs
    assign o_io_ledr = reg_ledr;
    assign o_io_ledg = reg_ledg;
    assign o_io_hex0 = reg_hex_lo[6:0];
    assign o_io_hex1 = reg_hex_lo[14:8];
    assign o_io_hex2 = reg_hex_lo[22:16];
    assign o_io_hex3 = reg_hex_lo[30:24];
    assign o_io_hex4 = reg_hex_hi[6:0];
    assign o_io_hex5 = reg_hex_hi[14:8];
    assign o_io_hex6 = reg_hex_hi[22:16];
    assign o_io_hex7 = reg_hex_hi[30:24];
    assign o_io_lcd  = reg_lcd;

    // Read data selection and alignment
    logic [31:0] raw_rdata;
    logic [31:0] periph_rdata;

    // Peripheral read data (combinational - asynchronous read)
    always_comb begin
        if (addr_is_ledr)
            periph_rdata = reg_ledr;
        else if (addr_is_ledg)
            periph_rdata = reg_ledg;
        else if (addr_is_hex_lo)
            periph_rdata = reg_hex_lo;
        else if (addr_is_hex_hi)
            periph_rdata = reg_hex_hi;
        else if (addr_is_lcd)
            periph_rdata = reg_lcd;
        else if (addr_is_sw)
            periph_rdata = i_io_sw;
        else
            periph_rdata = 32'h0;
    end

    // Select between memory and peripheral read data
    assign raw_rdata = addr_is_mem ? mem_rdata : periph_rdata;

    // Load data alignment and sign/zero extension
    always_comb begin
        case (i_mem_op)
            MEM_LB: begin
                case (byte_offset)
                    2'b00: o_rdata = {{24{raw_rdata[7]}},  raw_rdata[7:0]};
                    2'b01: o_rdata = {{24{raw_rdata[15]}}, raw_rdata[15:8]};
                    2'b10: o_rdata = {{24{raw_rdata[23]}}, raw_rdata[23:16]};
                    2'b11: o_rdata = {{24{raw_rdata[31]}}, raw_rdata[31:24]};
                endcase
            end
            MEM_LH: begin
                case (byte_offset[1])
                    1'b0: o_rdata = {{16{raw_rdata[15]}}, raw_rdata[15:0]};
                    1'b1: o_rdata = {{16{raw_rdata[31]}}, raw_rdata[31:16]};
                endcase
            end
            MEM_LW: begin
                o_rdata = raw_rdata;
            end
            MEM_LBU: begin
                case (byte_offset)
                    2'b00: o_rdata = {24'b0, raw_rdata[7:0]};
                    2'b01: o_rdata = {24'b0, raw_rdata[15:8]};
                    2'b10: o_rdata = {24'b0, raw_rdata[23:16]};
                    2'b11: o_rdata = {24'b0, raw_rdata[31:24]};
                endcase
            end
            MEM_LHU: begin
                case (byte_offset[1])
                    1'b0: o_rdata = {16'b0, raw_rdata[15:0]};
                    1'b1: o_rdata = {16'b0, raw_rdata[31:16]};
                endcase
            end
            default: o_rdata = raw_rdata;
        endcase
    end

endmodule : lsu

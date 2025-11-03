module single_cycle (
    input  logic         i_clk     ,
    input  logic         i_reset   ,
    input  logic [31:0]  i_io_sw   ,
    output logic [31:0]  o_io_ledr ,
    output logic [31:0]  o_io_ledg ,
    output logic [31:0]  o_io_lcd  ,
    output logic [ 6:0]  o_io_hex0 ,
    output logic [ 6:0]  o_io_hex1 ,
    output logic [ 6:0]  o_io_hex2 ,
    output logic [ 6:0]  o_io_hex3 ,
    output logic [ 6:0]  o_io_hex4 ,
    output logic [ 6:0]  o_io_hex5 ,
    output logic [ 6:0]  o_io_hex6 ,
    output logic [ 6:0]  o_io_hex7 ,
    output logic [31:0]  o_pc_debug,
    output logic         o_insn_vld
);

    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] instruction;
    logic [31:0] imm;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic        alu_zero;
    logic [31:0] mem_rdata;
    logic [31:0] reg_wdata;
    logic [31:0] branch_target;
    logic [31:0] jump_target;

    logic        reg_write;
    logic        mem_write;
    logic        mem_read;
    logic [1:0]  mem_to_reg;
    logic [1:0]  alu_src_a;
    logic [1:0]  alu_src_b;
    logic [3:0]  alu_op;
    logic        branch;
    logic        jump;
    logic [2:0]  mem_size;
    logic        pc_src;

    logic        branch_taken;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic        dmem_we;
    logic [31:0] io_data;

    assign o_pc_debug = pc;
    assign o_insn_vld = i_reset;

    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            pc <= 32'h0000_0000;
        end else begin
            pc <= pc_next;
        end
    end

    imem u_imem (
        .addr   (pc),
        .rdata  (instruction)
    );

    control_unit u_control (
        .opcode     (instruction[6:0]),
        .funct3     (instruction[14:12]),
        .funct7     (instruction[31:25]),
        .reg_write  (reg_write),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .mem_to_reg (mem_to_reg),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .alu_op     (alu_op),
        .branch     (branch),
        .jump       (jump),
        .mem_size   (mem_size),
        .pc_src     (pc_src)
    );

    register_file u_regfile (
        .clk        (i_clk),
        .we         (reg_write),
        .addr_rs1   (instruction[19:15]),
        .addr_rs2   (instruction[24:20]),
        .addr_rd    (instruction[11:7]),
        .wdata      (reg_wdata),
        .rdata_rs1  (rs1_data),
        .rdata_rs2  (rs2_data)
    );

    always_comb begin
        case (instruction[6:0])
            7'b0110111: imm = {instruction[31:12], 12'b0};
            7'b0010111: imm = {instruction[31:12], 12'b0};
            7'b1101111: imm = {{12{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            7'b1100011: imm = {{20{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b0100011: imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b0010011: begin
                if (instruction[14:12] == 3'b001 || instruction[14:12] == 3'b101) begin
                    imm = {27'b0, instruction[24:20]};
                end else begin
                    imm = {{20{instruction[31]}}, instruction[31:20]};
                end
            end
            7'b0000011: imm = {{20{instruction[31]}}, instruction[31:20]};
            7'b1100111: imm = {{20{instruction[31]}}, instruction[31:20]};
            default: imm = 32'b0;
        endcase
    end

    always_comb begin
        case (alu_src_a)
            2'b00: alu_a = rs1_data;
            2'b01: alu_a = pc;
            2'b10: alu_a = pc;
            2'b11: alu_a = {instruction[31:12], 12'b0};
            default: alu_a = rs1_data;
        endcase

        case (alu_src_b)
            2'b00: alu_b = rs2_data;
            2'b01: alu_b = imm;
            2'b10: alu_b = 32'h4;
            2'b11: alu_b = 32'b0;
            default: alu_b = rs2_data;
        endcase
    end

    alu u_alu (
        .op_a       (alu_a),
        .op_b       (alu_b),
        .alu_op     (alu_op),
        .alu_out    (alu_result),
        .alu_zero   (alu_zero)
    );

    always_comb begin
        if (instruction[6:0] == 7'b1100011) begin
            case (instruction[14:12])
                3'b000: branch_taken = (rs1_data == rs2_data);
                3'b001: branch_taken = (rs1_data != rs2_data);
                3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));
                3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
                3'b110: branch_taken = (rs1_data < rs2_data);
                3'b111: branch_taken = (rs1_data >= rs2_data);
                default: branch_taken = 1'b0;
            endcase
        end else begin
            branch_taken = 1'b0;
        end
    end

    assign branch_target = pc + imm;
    assign jump_target = (instruction[6:0] == 7'b1101111) ? (pc + imm) : (rs1_data + imm);

    always_comb begin
        if (jump) begin
            pc_next = jump_target;
        end else if (branch && branch_taken) begin
            pc_next = branch_target;
        end else begin
            pc_next = pc + 32'h4;
        end
    end

    assign dmem_addr = alu_result;
    assign dmem_wdata = rs2_data;
    assign dmem_we = mem_write;

    always_comb begin
        // I/O map (the test/README dùng 0x0000_1xxx)
        if (dmem_addr >= 32'h0000_1000) begin
            if (dmem_addr >= 32'h0000_1018 && dmem_addr < 32'h0000_101C && mem_read) begin
                io_data = {o_io_lcd};
            end else if (dmem_addr >= 32'h0000_1014 && dmem_addr < 32'h0000_1018 && mem_read) begin
                io_data = {1'b0, o_io_hex7, 1'b0, o_io_hex6, 1'b0, o_io_hex5, 1'b0, o_io_hex4};
            end else if (dmem_addr >= 32'h0000_1010 && dmem_addr < 32'h0000_1014 && mem_read) begin
                io_data = {1'b0, o_io_hex3, 1'b0, o_io_hex2, 1'b0, o_io_hex1, 1'b0, o_io_hex0};
            end else if (dmem_addr >= 32'h0000_100C && dmem_addr < 32'h0000_1010 && mem_read) begin
                io_data = o_io_ledg;
            end else if (dmem_addr >= 32'h0000_1000 && dmem_addr < 32'h0000_1004 && mem_read) begin
                io_data = o_io_ledr;
            end else if (dmem_addr >= 32'h0000_1008 && dmem_addr < 32'h0000_100C && mem_read) begin
                io_data = i_io_sw;
            end else begin
                io_data = 32'b0;
            end
        end else begin
            io_data = dmem_rdata;
        end
    end

    dmem u_dmem (
        .clk        (i_clk),
        .we         (dmem_we && (dmem_addr < 32'h0000_0800)),
        .addr       (dmem_addr),
        .wdata      (dmem_wdata),
        .mem_size   (mem_size),
        .rdata      (dmem_rdata)
    );

    always_comb begin
        case (mem_to_reg)
            2'b00: reg_wdata = alu_result;
            2'b01: reg_wdata = io_data;
            2'b10: reg_wdata = pc + 32'h4;
            default: reg_wdata = alu_result;
        endcase
    end

    always_ff @(posedge i_clk) begin
        if (~i_reset) begin
            o_io_ledr <= 32'b0;
            o_io_ledg <= 32'b0;
            o_io_lcd  <= 32'b0;
            o_io_hex0 <= 7'b0;
            o_io_hex1 <= 7'b0;
            o_io_hex2 <= 7'b0;
            o_io_hex3 <= 7'b0;
            o_io_hex4 <= 7'b0;
            o_io_hex5 <= 7'b0;
            o_io_hex6 <= 7'b0;
            o_io_hex7 <= 7'b0;
        end else if (mem_write && dmem_addr >= 32'h0000_1000) begin
            // LEDR @ 0x0000_1000
            if (dmem_addr >= 32'h0000_1000 && dmem_addr < 32'h0000_1004) begin
                o_io_ledr <= dmem_wdata;
            // LEDG @ 0x0000_100C
            end else if (dmem_addr >= 32'h0000_100C && dmem_addr < 32'h0000_1010) begin
                o_io_ledg <= dmem_wdata;
            // HEX0..3 @ 0x0000_1010
            end else if (dmem_addr >= 32'h0000_1010 && dmem_addr < 32'h0000_1014) begin
                case (mem_size)
                    3'b000: begin
                        case (dmem_addr[1:0])
                            2'b00: o_io_hex0 <= dmem_wdata[6:0];
                            2'b01: o_io_hex1 <= dmem_wdata[6:0];
                            2'b10: o_io_hex2 <= dmem_wdata[6:0];
                            2'b11: o_io_hex3 <= dmem_wdata[6:0];
                        endcase
                    end
                    3'b001: begin
                        if (dmem_addr[1] == 1'b0) begin
                            o_io_hex0 <= dmem_wdata[6:0];
                            o_io_hex1 <= dmem_wdata[14:8];
                        end else begin
                            o_io_hex2 <= dmem_wdata[6:0];
                            o_io_hex3 <= dmem_wdata[14:8];
                        end
                    end
                    3'b010: begin
                        o_io_hex0 <= dmem_wdata[6:0];
                        o_io_hex1 <= dmem_wdata[14:8];
                        o_io_hex2 <= dmem_wdata[22:16];
                        o_io_hex3 <= dmem_wdata[30:24];
                    end
                    default: begin
                        o_io_hex0 <= dmem_wdata[6:0];
                        o_io_hex1 <= dmem_wdata[14:8];
                        o_io_hex2 <= dmem_wdata[22:16];
                        o_io_hex3 <= dmem_wdata[30:24];
                    end
                endcase
            // HEX4..7 @ 0x0000_1014
            end else if (dmem_addr >= 32'h0000_1014 && dmem_addr < 32'h0000_1018) begin
                case (mem_size)
                    3'b000: begin
                        case (dmem_addr[1:0])
                            2'b00: o_io_hex4 <= dmem_wdata[6:0];
                            2'b01: o_io_hex5 <= dmem_wdata[6:0];
                            2'b10: o_io_hex6 <= dmem_wdata[6:0];
                            2'b11: o_io_hex7 <= dmem_wdata[6:0];
                        endcase
                    end
                    3'b001: begin
                        if (dmem_addr[1] == 1'b0) begin
                            o_io_hex4 <= dmem_wdata[6:0];
                            o_io_hex5 <= dmem_wdata[14:8];
                        end else begin
                            o_io_hex6 <= dmem_wdata[6:0];
                            o_io_hex7 <= dmem_wdata[14:8];
                        end
                    end
                    3'b010: begin
                        o_io_hex4 <= dmem_wdata[6:0];
                        o_io_hex5 <= dmem_wdata[14:8];
                        o_io_hex6 <= dmem_wdata[22:16];
                        o_io_hex7 <= dmem_wdata[30:24];
                    end
                    default: begin
                        o_io_hex4 <= dmem_wdata[6:0];
                        o_io_hex5 <= dmem_wdata[14:8];
                        o_io_hex6 <= dmem_wdata[22:16];
                        o_io_hex7 <= dmem_wdata[30:24];
                    end
                endcase
            // LCD @ 0x0000_1018
            end else if (dmem_addr >= 32'h0000_1018 && dmem_addr < 32'h0000_101C) begin
                o_io_lcd <= dmem_wdata;
            end
        end
    end

endmodule : single_cycle

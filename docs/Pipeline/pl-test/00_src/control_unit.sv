module control_unit (
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    output logic        reg_write,
    output logic        mem_write,
    output logic        mem_read,
    output logic [1:0]  mem_to_reg,
    output logic [1:0]  alu_src_a,
    output logic [1:0]  alu_src_b,
    output logic [3:0]  alu_op,
    output logic        branch,
    output logic        jump,
    output logic [2:0]  mem_size,
    output logic        pc_src
);

    always_comb begin
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        mem_to_reg = 2'b00;
        alu_src_a  = 2'b00;
        alu_src_b  = 2'b00;
        alu_op     = 4'b0000;
        branch     = 1'b0;
        jump       = 1'b0;
        mem_size   = 3'b010;
        pc_src     = 1'b0;

        case (opcode)
            7'b0110011: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b00;
                alu_src_a = 2'b00;
                alu_src_b = 2'b00;
                case (funct3)
                    3'b000: alu_op = (funct7[5] == 1'b1) ? 4'b0001 : 4'b0000;
                    3'b001: alu_op = 4'b0101;
                    3'b010: alu_op = 4'b1000;
                    3'b011: alu_op = 4'b1001;
                    3'b100: alu_op = 4'b0100;
                    3'b101: alu_op = (funct7[5] == 1'b1) ? 4'b0111 : 4'b0110;
                    3'b110: alu_op = 4'b0011;
                    3'b111: alu_op = 4'b0010;
                endcase
            end

            7'b0010011: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b00;
                alu_src_a = 2'b00;
                alu_src_b = 2'b01;
                case (funct3)
                    3'b000: alu_op = 4'b0000;
                    3'b001: alu_op = 4'b0101;
                    3'b010: alu_op = 4'b1000;
                    3'b011: alu_op = 4'b1001;
                    3'b100: alu_op = 4'b0100;
                    3'b101: alu_op = (funct7[5] == 1'b1) ? 4'b0111 : 4'b0110;
                    3'b110: alu_op = 4'b0011;
                    3'b111: alu_op = 4'b0010;
                endcase
            end

            7'b0000011: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg = 2'b01;
                alu_src_a = 2'b00;
                alu_src_b = 2'b01;
                alu_op    = 4'b0000;
                case (funct3)
                    3'b000: mem_size = 3'b000;
                    3'b001: mem_size = 3'b001;
                    3'b010: mem_size = 3'b010;
                    3'b100: mem_size = 3'b100;
                    3'b101: mem_size = 3'b101;
                    default: mem_size = 3'b010;
                endcase
            end

            7'b0100011: begin
                mem_write = 1'b1;
                alu_src_a = 2'b00;
                alu_src_b = 2'b01;
                alu_op    = 4'b0000;
                case (funct3)
                    3'b000: mem_size = 3'b000;
                    3'b001: mem_size = 3'b001;
                    3'b010: mem_size = 3'b010;
                    default: mem_size = 3'b010;
                endcase
            end

            7'b1100011: begin
                branch = 1'b1;
                alu_src_a = 2'b00;
                alu_src_b = 2'b00;
                case (funct3)
                    3'b000: alu_op = 4'b0001;
                    3'b001: alu_op = 4'b0001;
                    3'b100: alu_op = 4'b0001;
                    3'b101: alu_op = 4'b0001;
                    3'b110: alu_op = 4'b0001;
                    3'b111: alu_op = 4'b0001;
                    default: alu_op = 4'b0001;
                endcase
            end

            7'b1100111: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b10;
                jump = 1'b1;
                alu_src_a = 2'b10;
                alu_src_b = 2'b01;
                alu_op = 4'b0000;
            end

            7'b1101111: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b10;
                jump = 1'b1;
            end

            7'b0010111: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b00;
                alu_src_a = 2'b01;
                alu_src_b = 2'b01;
                alu_op = 4'b0000;
            end

            7'b0110111: begin
                reg_write = 1'b1;
                mem_to_reg = 2'b00;
                alu_src_a = 2'b11;
                alu_src_b = 2'b11;
                alu_op = 4'b0000;
            end

            default: begin
            end
        endcase
    end

endmodule


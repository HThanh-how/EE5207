module ALUControl (
    input  [6:0] opcode,   // inst[6:0]
    input  [2:0] funct3,   // inst[14:12]
    input  [6:0] funct7,   // inst[31:25]
    output reg [3:0] ALUSel
);

    // Define ALUSel codes
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLTU = 4'b0110;
    localparam ALU_SLL  = 4'b0111;
    localparam ALU_SRL  = 4'b1000;
    localparam ALU_SRA  = 4'b1001;

    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type
                case (funct3)
                    3'b000: ALUSel = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    3'b001: ALUSel = ALU_SLL; 
                    3'b010: ALUSel = ALU_SLT;
                    3'b011: ALUSel = ALU_SLTU;					
                    3'b100: ALUSel = ALU_XOR;
                    3'b101: ALUSel = (funct7[5]) ? ALU_SRA : ALU_SRL; 
					3'b110: ALUSel = ALU_OR;
					3'b111: ALUSel = ALU_AND;
                    default: ALUSel = ALU_ADD;
                endcase
            end

            7'b0010011: begin // I-type (ADDI, SLTI, ORI, ANDI, XORI, SLLI, SRLI, SRAI)
                case (funct3)
                    3'b000: ALUSel = ALU_ADD;   // ADDI
                    3'b010: ALUSel = ALU_SLT;   // SLTI
                    3'b011: ALUSel = ALU_SLTU;  // SLTIU
                    3'b100: ALUSel = ALU_XOR;   // XORI
                    3'b110: ALUSel = ALU_OR;    // ORI
                    3'b111: ALUSel = ALU_AND;   // ANDI
                    3'b001: ALUSel = ALU_SLL;   // SLLI
                    3'b101: ALUSel = (funct7[5]) ? ALU_SRA : ALU_SRL; // SRAI/SRLI
                    default: ALUSel = ALU_ADD;
                endcase
            end

            7'b0000011: ALUSel = ALU_ADD; // Load: address = rs1 + imm
            7'b0100011: ALUSel = ALU_ADD; // Store: address = rs1 + imm
            7'b1100011: ALUSel = ALU_SUB; // Branch: comparison = rs1 - rs2
            default:    ALUSel = ALU_ADD; // default
        endcase
    end

endmodule
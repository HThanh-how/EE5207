module RegFile (
    input  wire        clk,
    input  wire        rst_n,       // Reset đồng bộ
    input  wire        RegWEn,    // Cho phép ghi
    input  wire [4:0]  rsR1,      // Địa chỉ thanh ghi đọc 1
    input  wire [4:0]  rsR2,      // Địa chỉ thanh ghi đọc 2
    input  wire [4:0]  rsW,       // Địa chỉ thanh ghi ghi
    input  wire [31:0] dataW,     // Dữ liệu ghi
    output wire [31:0] dataR1,    // Dữ liệu đọc 1
    output wire [31:0] dataR2     // Dữ liệu đọc 2
);

	// Declare 32 registers with 32-bít
    reg [31:0] Regs [31:0];
	
	// Declare 32-bit enable signal
	wire [31:0] WEn;
	
	Decoder5_32 inst0 (.in(rsW),
	.en(RegWEn),
	.out(WEn)
	);
	
	Mux32_1 Data1(
	.in0(Regs[0]),
	.in1(Regs[1]),
	.in2(Regs[2]),
	.in3(Regs[3]),
	.in4(Regs[4]),
	.in5(Regs[5]),
	.in6(Regs[6]),
	.in7(Regs[7]),
	.in8(Regs[8]),
	.in9(Regs[9]),
	.in10(Regs[10]),
	.in11(Regs[11]),
	.in12(Regs[12]),
	.in13(Regs[13]),
	.in14(Regs[14]),
	.in15(Regs[15]),
	.in16(Regs[16]),
	.in17(Regs[17]),
	.in18(Regs[18]),
	.in19(Regs[19]),
	.in20(Regs[20]),
	.in21(Regs[21]),
	.in22(Regs[22]),
	.in23(Regs[23]),
	.in24(Regs[24]),
	.in25(Regs[25]),
	.in26(Regs[26]),
	.in27(Regs[27]),
	.in28(Regs[28]),
	.in29(Regs[29]),
	.in30(Regs[30]),
	.in31(Regs[31]),
	.sel(rsR1),
	.out(dataR1)
	);
	
	Mux32_1 Data2(
	.in0(Regs[0]),
	.in1(Regs[1]),
	.in2(Regs[2]),
	.in3(Regs[3]),
	.in4(Regs[4]),
	.in5(Regs[5]),
	.in6(Regs[6]),
	.in7(Regs[7]),
	.in8(Regs[8]),
	.in9(Regs[9]),
	.in10(Regs[10]),
	.in11(Regs[11]),
	.in12(Regs[12]),
	.in13(Regs[13]),
	.in14(Regs[14]),
	.in15(Regs[15]),
	.in16(Regs[16]),
	.in17(Regs[17]),
	.in18(Regs[18]),
	.in19(Regs[19]),
	.in20(Regs[20]),
	.in21(Regs[21]),
	.in22(Regs[22]),
	.in23(Regs[23]),
	.in24(Regs[24]),
	.in25(Regs[25]),
	.in26(Regs[26]),
	.in27(Regs[27]),
	.in28(Regs[28]),
	.in29(Regs[29]),
	.in30(Regs[30]),
	.in31(Regs[31]),
	.sel(rsR2),
	.out(dataR2)
	);

	
	always @(posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0) begin
				Regs[0] <= 32'b0;
				Regs[1] <= 32'b0;
				Regs[2] <= 32'b0;
				Regs[3] <= 32'b0;
				Regs[4] <= 32'b0;
				Regs[5] <= 32'b0;
				Regs[6] <= 32'b0;
				Regs[7] <= 32'b0;
				Regs[8] <= 32'b0;
				Regs[9] <= 32'b0;
				Regs[10] <= 32'b0;
				Regs[11] <= 32'b0;
				Regs[12] <= 32'b0;
				Regs[13] <= 32'b0;
				Regs[14] <= 32'b0;
				Regs[15] <= 32'b0;
				Regs[16] <= 32'b0;
				Regs[17] <= 32'b0;
				Regs[18] <= 32'b0;
				Regs[19] <= 32'b0;
				Regs[20] <= 32'b0;
				Regs[21] <= 32'b0;
				Regs[22] <= 32'b0;
				Regs[23] <= 32'b0;
				Regs[24] <= 32'b0;
				Regs[25] <= 32'b0;
				Regs[26] <= 32'b0;
				Regs[27] <= 32'b0;
				Regs[28] <= 32'b0;
				Regs[29] <= 32'b0;
				Regs[30] <= 32'b0;
				Regs[31] <= 32'b0;
		end
		else begin
				Regs[0] <= 32'b0;
				Regs[1]  <= WEn[1]  ? dataW : Regs[1];
				Regs[2]  <= WEn[2]  ? dataW : Regs[2];
				Regs[3]  <= WEn[3]  ? dataW : Regs[3];
				Regs[4]  <= WEn[4]  ? dataW : Regs[4];
				Regs[5]  <= WEn[5]  ? dataW : Regs[5];
				Regs[6]  <= WEn[6]  ? dataW : Regs[6];
				Regs[7]  <= WEn[7]  ? dataW : Regs[7];
				Regs[8]  <= WEn[8]  ? dataW : Regs[8];
				Regs[9]  <= WEn[9]  ? dataW : Regs[9];
				Regs[10] <= WEn[10] ? dataW : Regs[10];
				Regs[11] <= WEn[11] ? dataW : Regs[11];
				Regs[12] <= WEn[12] ? dataW : Regs[12];
				Regs[13] <= WEn[13] ? dataW : Regs[13];
				Regs[14] <= WEn[14] ? dataW : Regs[14];
				Regs[15] <= WEn[15] ? dataW : Regs[15];
				Regs[16] <= WEn[16] ? dataW : Regs[16];
				Regs[17] <= WEn[17] ? dataW : Regs[17];
				Regs[18] <= WEn[18] ? dataW : Regs[18];
				Regs[19] <= WEn[19] ? dataW : Regs[19];
				Regs[20] <= WEn[20] ? dataW : Regs[20];
				Regs[21] <= WEn[21] ? dataW : Regs[21];
				Regs[22] <= WEn[22] ? dataW : Regs[22];
				Regs[23] <= WEn[23] ? dataW : Regs[23];
				Regs[24] <= WEn[24] ? dataW : Regs[24];
				Regs[25] <= WEn[25] ? dataW : Regs[25];
				Regs[26] <= WEn[26] ? dataW : Regs[26];
				Regs[27] <= WEn[27] ? dataW : Regs[27];
				Regs[28] <= WEn[28] ? dataW : Regs[28];
				Regs[29] <= WEn[29] ? dataW : Regs[29];
				Regs[30] <= WEn[30] ? dataW : Regs[30];
				Regs[31] <= WEn[31] ? dataW : Regs[31];
		end
	end
endmodule
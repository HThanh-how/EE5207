module scoreboard(
  input  logic         i_clk     ,
  input  logic         i_reset   ,
  input  logic [31:0]  i_io_sw   ,
  input  logic [31:0]  o_io_ledr ,
  input  logic [31:0]  o_io_ledg ,
  input  logic [ 6:0]  o_io_hex0 ,
  input  logic [ 6:0]  o_io_hex1 ,
  input  logic [ 6:0]  o_io_hex2 ,
  input  logic [ 6:0]  o_io_hex3 ,
  input  logic [ 6:0]  o_io_hex4 ,
  input  logic [ 6:0]  o_io_hex5 ,
  input  logic [ 6:0]  o_io_hex6 ,
  input  logic [ 6:0]  o_io_hex7 ,
  input  logic [31:0]  o_io_lcd  ,
  input  logic [31:0]  o_pc_debug,
  input  logic         o_insn_vld
);

// Display test name
initial begin
  $display("\nSINGLE CYCLE - ISA test\n");
end


// Trạng thái theo dõi tiến trình bài test
bit started;
bit output_seen;
integer cycle_count;
logic [31:0] last_ledr;

initial begin
  started      = 1'b0;
  output_seen  = 1'b0;
  cycle_count  = 0;
  last_ledr    = 32'h0;
end

// In trạng thái khi reset được nhả (reset active low)
always @(negedge i_clk) begin
  // đếm chu kỳ để tiện debug
  cycle_count <= cycle_count + 1;

  if (!i_reset) begin
    // Reset đang giữ: clear trạng thái
    started      <= 1'b0;
    output_seen  <= 1'b0;
    cycle_count  <= 0;
  end else begin
    if (!started) begin
      started <= 1'b1;
      `ifdef VERBOSE_STATUS
        $display("[STATUS] START - reset deasserted, running...");
      `endif
    end

    // Giai đoạn output: in ký tự khi LEDR thay đổi (ổn định với nhiều biến thể test)
    if (o_io_ledr !== last_ledr) begin
      // đánh dấu đã thấy output lần đầu
      if (!output_seen) begin
        `ifdef VERBOSE_STATUS
          $display("\n[STATUS] OUTPUT PHASE (cycle=%0d)", cycle_count);
        `endif
        output_seen <= 1'b1;
      end
      last_ledr <= o_io_ledr;
      // in ký tự từ byte thấp nếu là ASCII hiển thị được
      if (o_io_ledr[7:0] != 8'h00) begin
        $write("%c", o_io_ledr[7:0]);
      end
    end

    // Kết thúc test: PC = 0x1C
    if (o_pc_debug == 32'h1c) begin
      `ifdef VERBOSE_STATUS
        if (output_seen) begin
          $display("\n[STATUS] TEST PASS @PC=0x1C (cycle=%0d)", cycle_count);
        end else begin
          $display("\n[STATUS] TEST FAIL: no output observed at PC=0x18 (cycle=%0d)", cycle_count);
        end
      `endif
      $display("\nEND of ISA test\n");
      $finish;
    end
  end
end



endmodule : scoreboard

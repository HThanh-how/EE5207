module scoreboard(
  input  logic         i_clk     ,
  input  logic         i_reset   ,
  // Input peripherals
  input  logic [31:0]  i_io_sw   ,
  // Output peripherals
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
  // Debug
  input  logic         o_ctrl    ,
  input  logic         o_mispred ,
  input  logic [31:0]  o_pc_debug,
  input  logic         o_insn_vld
);


  real num_cycle;      // Number of execution cycles
  real num_insn;       // Number of valid instructions
  real num_ctrl;       // Number of control transfer instructions
  real num_mispred;    // Number of Misprediction
  real ipc;            // Instructino Per Cycle
  real misprd_rate;    // Misprediction Rate

  // Track previous LEDR value to detect changes
  logic [7:0] prev_ledr;

  // Display test name
  initial begin
    $display("\nPIPELINE - ISA tests\n");
    prev_ledr = 8'b0;
  end


  always @(negedge i_clk) begin : counters
      if (!i_reset) begin
        num_cycle   <= '0;
        num_ctrl    <= '0;
        num_insn    <= '0;
        num_mispred <= '0;
        prev_ledr   <= 8'b0;
      end
      else begin
        num_cycle   <=              num_cycle   + 1;
        num_ctrl    <= o_ctrl     ? num_ctrl    + 1 : num_ctrl;
        num_insn    <= o_insn_vld ? num_insn    + 1 : num_insn;
        num_mispred <= o_mispred  ? num_mispred + 1 : num_mispred;
        // Update previous LEDR value for change detection
        prev_ledr   <= o_io_ledr[7:0];
      end
  end


  always @(negedge i_clk) begin : debug
      // In milestone-3, o_pc_debug = wb_pc (WB stage PC)
      // But I/O write happens in MEM stage, so timing might be off
      // Try both methods:
      // Method 1: Check PC = 0x18 (like milestone-2)
      if (o_pc_debug == 32'h18) begin
          $write("%s", o_io_ledr[7:0]);
      end
      // Method 2: Catch any LEDR change (backup - catches I/O writes at any PC)
      // Use prev_ledr from last cycle (updated in counters block)
      else if ((o_io_ledr[7:0] != prev_ledr) && (o_io_ledr[7:0] != 8'b0)) begin
          $write("%s", o_io_ledr[7:0]);
      end
  end


  always @(negedge i_clk) begin : result
      // MUST use o_insn_vld to ensure instruction actually retires (not just appears in pipeline)
      if (o_insn_vld && ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20))) begin
        $display("\nResult");
        $display("");
        if (num_cycle != 0) $display("IPC = %1.2f", num_insn/num_cycle);
        else                $display("IPC = N/A");
        
        if (num_ctrl != 0)  $display("Mispred Rate = %2.2f", num_mispred/num_ctrl * 100);
        else                $display("Mispred Rate = N/A");
        
        $display("");
        $display("END of ISA tests");
        $finish;
      end
  end



endmodule : scoreboard

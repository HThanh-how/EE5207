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
  logic [31:0] prev_ledr;

  // Display test name
  initial begin
    $display("\nPIPELINE - ISA tests\n");
  end


  always @(negedge i_clk) begin : counters
      if (!i_reset) begin
        num_cycle   <= '0;
        num_ctrl    <= '0;
        num_insn    <= '0;
        num_mispred <= '0;
        prev_ledr   <= 32'b0;
      end
      else begin
        num_cycle   <=              num_cycle   + 1;
        num_ctrl    <= o_ctrl     ? num_ctrl    + 1 : num_ctrl;
        num_insn    <= o_insn_vld ? num_insn    + 1 : num_insn;
        num_mispred <= o_mispred  ? num_mispred + 1 : num_mispred;
      end
  end


  // Monitor LEDR changes - print PASS/ERROR messages
  always @(posedge i_clk) begin
      if (i_reset) begin
          // DEBUG: Uncomment để xem LEDR có thay đổi không
          // if (o_io_ledr[7:0] != prev_ledr[7:0]) begin
          //     $display("LEDR change: prev=%h, curr=%h, PC=%h", prev_ledr[7:0], o_io_ledr[7:0], o_pc_debug);
          // end
          
          // Check if LEDR[7:0] changed and is non-zero
          // Use posedge to catch LEDR update right after it's written
          if (o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("%s", o_io_ledr[7:0]);
          end
          prev_ledr <= o_io_ledr;
      end else begin
          prev_ledr <= 32'b0;
      end
  end

  // Print results and finish at PC 0x1c or 0x20
  always @(negedge i_clk) begin
      if ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20)) begin
          $display("");  // Newline after PASS/ERROR messages
          
          // Print statistics
          $display("\n=================== Result ===================");
          if (num_cycle != 0) $display("Total Clock Cycles Executed = %1.0f", num_cycle);
          else                $display("Total Clock Cycles Executed = N/A");

          if (num_insn  != 0) $display("Total Instructions Executed = %1.0f", num_insn);
          else                $display("Total Instructions Executed = N/A");

          if (num_cycle != 0) $display("Total Branch Instructions   = %1.0f", num_ctrl);
          else                $display("Total Branch Instructions   = N/A");

          if (num_cycle != 0) $display("Total Branch Mispredictions = %1.0f", num_mispred);
          else                $display("Total Branch Mispredictions = N/A");

          $display("\n----------------------------------------------");
          if (num_cycle != 0) $display("Instruction Per Cycle (IPC) = %1.2f", num_insn/num_cycle);
          else                $display("Instruction Per Cycle (IPC) = N/A");

          if (num_ctrl != 0)  $display("Branch Misprediction Rate   = %2.2f %%", num_mispred/num_ctrl * 100);
          else                $display("Branch Misprediction Rate   = N/A");

          $display("\nEND of ISA tests\n");
          $finish;
      end
  end



endmodule : scoreboard



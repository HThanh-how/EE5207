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

  // Track previous LEDR value for method testing
  logic [31:0] prev_ledr;
  logic [31:0] prev_pc_debug;
  logic        prev_insn_vld;

  // Display test name
  initial begin
    $display("\nPIPELINE - ISA tests\n");
    $display("=== TESTING ALL METHODS SIMULTANEOUSLY ===\n");
    prev_ledr = 32'b0;
    prev_pc_debug = 32'b0;
    prev_insn_vld = 1'b0;
  end

  // Counters for statistics
  always @(negedge i_clk) begin : counters
      if (!i_reset) begin
        num_cycle   <= '0;
        num_ctrl    <= '0;
        num_insn    <= '0;
        num_mispred <= '0;
        prev_ledr   <= 32'b0;
        prev_pc_debug <= 32'b0;
        prev_insn_vld <= 1'b0;
      end
      else begin
        num_cycle   <=              num_cycle   + 1;
        num_ctrl    <= o_ctrl     ? num_ctrl    + 1 : num_ctrl;
        num_insn    <= o_insn_vld ? num_insn    + 1 : num_insn;
        num_mispred <= o_mispred  ? num_mispred + 1 : num_mispred;
        prev_ledr   <= o_io_ledr;
        prev_pc_debug <= o_pc_debug;
        prev_insn_vld <= o_insn_vld;
      end
  end

  // ============================================
  // NEGEDGE METHODS (Original)
  // ============================================
  always @(negedge i_clk) begin : debug_negedge
      if (i_reset) begin
          // METHOD 1: Original milestone 3 code - check o_insn_vld && PC 0x18
          if (o_insn_vld && (o_pc_debug == 32'h18)) begin
              $write("[M1]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 2: Milestone 2 style - check PC 0x18 only (no o_insn_vld)
          if (o_pc_debug == 32'h18) begin
              $write("[M2]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 3: Check LEDR change at PC 0x18
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M3]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 4: Check LEDR change with o_insn_vld
          if (o_insn_vld && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M4]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 5: Check LEDR change without PC check
          if (o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M5]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 6: Check PC change to 0x18 with o_insn_vld
          if (o_insn_vld && o_pc_debug == 32'h18 && prev_pc_debug != 32'h18) begin
              $write("[M6]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 7: Check o_insn_vld rising edge at PC 0x18
          if (o_insn_vld && !prev_insn_vld && o_pc_debug == 32'h18) begin
              $write("[M7]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 8: Check LEDR non-zero at PC 0x18
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != 8'b0) begin
              $write("[M8]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 9: Check o_insn_vld && LEDR non-zero at PC 0x18
          if (o_insn_vld && o_pc_debug == 32'h18 && o_io_ledr[7:0] != 8'b0) begin
              $write("[M9]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 10: Check PC 0x18 && LEDR change && o_insn_vld
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != prev_ledr[7:0] && o_insn_vld) begin
              $write("[M10]%s", o_io_ledr[7:0]);
          end
      end
  end

  // ============================================
  // POSEDGE METHODS
  // ============================================
  always @(posedge i_clk) begin : debug_posedge
      if (i_reset) begin
          // METHOD 11: Posedge - Original milestone 3 code
          if (o_insn_vld && (o_pc_debug == 32'h18)) begin
              $write("[M11]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 12: Posedge - PC 0x18 only
          if (o_pc_debug == 32'h18) begin
              $write("[M12]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 13: Posedge - LEDR change at PC 0x18
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M13]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 14: Posedge - LEDR change with o_insn_vld
          if (o_insn_vld && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M14]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 15: Posedge - LEDR change only
          if (o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M15]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 16: Posedge - PC change to 0x18 with o_insn_vld
          if (o_insn_vld && o_pc_debug == 32'h18 && prev_pc_debug != 32'h18) begin
              $write("[M16]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 17: Posedge - o_insn_vld rising edge at PC 0x18
          if (o_insn_vld && !prev_insn_vld && o_pc_debug == 32'h18) begin
              $write("[M17]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 18: Posedge - LEDR non-zero at PC 0x18
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != 8'b0) begin
              $write("[M18]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 19: Posedge - o_insn_vld && LEDR non-zero at PC 0x18
          if (o_insn_vld && o_pc_debug == 32'h18 && o_io_ledr[7:0] != 8'b0) begin
              $write("[M19]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 20: Posedge - PC 0x18 && LEDR change && o_insn_vld
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != prev_ledr[7:0] && o_insn_vld) begin
              $write("[M20]%s", o_io_ledr[7:0]);
          end
      end
  end

  // ============================================
  // COMBINATIONAL METHODS (Using always_comb or always @*)
  // ============================================
  always @(*) begin : debug_comb
      if (i_reset) begin
          // METHOD 21: Combinational - Original milestone 3 code
          if (o_insn_vld && (o_pc_debug == 32'h18)) begin
              $write("[M21]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 22: Combinational - PC 0x18 only
          if (o_pc_debug == 32'h18) begin
              $write("[M22]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 23: Combinational - LEDR non-zero at PC 0x18
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != 8'b0) begin
              $write("[M23]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 24: Combinational - o_insn_vld && LEDR non-zero at PC 0x18
          if (o_insn_vld && o_pc_debug == 32'h18 && o_io_ledr[7:0] != 8'b0) begin
              $write("[M24]%s", o_io_ledr[7:0]);
          end
      end
  end

  // ============================================
  // ALTERNATIVE PC VALUES
  // ============================================
  always @(negedge i_clk) begin : debug_alt_pc
      if (i_reset) begin
          // METHOD 25: Check PC 0x14 (before 0x18)
          if (o_insn_vld && (o_pc_debug == 32'h14)) begin
              $write("[M25]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 26: Check PC 0x1c (after 0x18, before result)
          if (o_insn_vld && (o_pc_debug == 32'h1c)) begin
              $write("[M26]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 27: Check PC range 0x14-0x20
          if (o_insn_vld && (o_pc_debug >= 32'h14 && o_pc_debug <= 32'h20)) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M27]%s", o_io_ledr[7:0]);
              end
          end
      end
  end

  // Print results and finish at PC 0x1c or 0x20
  // Try both with and without o_insn_vld
  always @(negedge i_clk) begin : result
      // Original milestone 3 code - check o_insn_vld
      if (o_insn_vld && ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20))) begin
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
      
      // Fallback: without o_insn_vld (in case o_insn_vld never triggers)
      if ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20)) begin
          $display("");  // Newline after PASS/ERROR messages
          
          // Print statistics
          $display("\n=================== Result (Fallback) ===================");
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

          $display("\nEND of ISA tests (Fallback)\n");
          $finish;
      end
  end

endmodule : scoreboard

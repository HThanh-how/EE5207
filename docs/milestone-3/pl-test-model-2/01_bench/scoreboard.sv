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
  // DEBUG: Print LEDR values to see what's happening
  // ============================================
  always @(negedge i_clk) begin : debug_ledr
      if (i_reset) begin
          // Debug: Print LEDR when it changes or PC is in interesting range
          if (o_io_ledr[7:0] != prev_ledr[7:0] || (o_pc_debug >= 32'h10 && o_pc_debug <= 32'h24)) begin
              $display("[DEBUG] PC=%h LEDR[7:0]=%h (%c) insn_vld=%b prev_LEDR=%h", 
                       o_pc_debug, o_io_ledr[7:0], o_io_ledr[7:0], o_insn_vld, prev_ledr[7:0]);
          end
      end
  end

  // ============================================
  // NEGEDGE METHODS - Check at different PC values (accounting for pipeline delay)
  // ============================================
  always @(negedge i_clk) begin : debug_negedge
      if (i_reset) begin
          // METHOD 1: Original milestone 3 code - check o_insn_vld && PC 0x18
          if (o_insn_vld && (o_pc_debug == 32'h18)) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M1]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M1-EMPTY]");
              end
          end
          
          // METHOD 2: Milestone 2 style - check PC 0x18 only (no o_insn_vld)
          if (o_pc_debug == 32'h18) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M2]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M2-EMPTY]");
              end
          end
          
          // METHOD 3: Check LEDR change at PC 0x18
          if (o_pc_debug == 32'h18 && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M3]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 4: Check LEDR change with o_insn_vld (any PC)
          if (o_insn_vld && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M4]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 5: Check LEDR change without PC check
          if (o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M5]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 28: Check PC 0x1c (after 0x18, accounting for pipeline delay)
          if (o_insn_vld && (o_pc_debug == 32'h1c)) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M28]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M28-EMPTY]");
              end
          end
          
          // METHOD 29: Check PC 0x20 (after 0x1c)
          if (o_insn_vld && (o_pc_debug == 32'h20)) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M29]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M29-EMPTY]");
              end
          end
          
          // METHOD 30: Check PC range 0x14-0x24 (wider range)
          if (o_insn_vld && (o_pc_debug >= 32'h14 && o_pc_debug <= 32'h24)) begin
              if (o_io_ledr[7:0] != 8'b0 && o_io_ledr[7:0] != prev_ledr[7:0]) begin
                  $write("[M30]PC=%h:%s", o_pc_debug, o_io_ledr[7:0]);
              end
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
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M11]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M11-EMPTY]");
              end
          end
          
          // METHOD 12: Posedge - PC 0x18 only
          if (o_pc_debug == 32'h18) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M12]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M12-EMPTY]");
              end
          end
          
          // METHOD 14: Posedge - LEDR change with o_insn_vld
          if (o_insn_vld && o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M14]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 15: Posedge - LEDR change only
          if (o_io_ledr[7:0] != prev_ledr[7:0] && o_io_ledr[7:0] != 8'b0) begin
              $write("[M15]%s", o_io_ledr[7:0]);
          end
          
          // METHOD 31: Posedge - PC 0x1c (after 0x18)
          if (o_insn_vld && (o_pc_debug == 32'h1c)) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M31]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M31-EMPTY]");
              end
          end
          
          // METHOD 32: Posedge - PC 0x20 (after 0x1c)
          if (o_insn_vld && (o_pc_debug == 32'h20)) begin
              if (o_io_ledr[7:0] != 8'b0) begin
                  $write("[M32]%s", o_io_ledr[7:0]);
              end else begin
                  $write("[M32-EMPTY]");
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

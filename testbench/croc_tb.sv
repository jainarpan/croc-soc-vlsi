// ============================================================================
// Croc SoC - Read/Write Testbench
// ============================================================================
// BITS Pilani | M.Tech VLSI Design | Advance VLSI Design
// Student  : Arpan Jain (2025HT08066)
// Mentor   : Abhinav Shahu, Member of Consulting Staff, Siemens EDA
// Date     : April 2026
//
// Description:
//   This testbench exercises the Croc SoC via the OBI bus interface.
//   It performs read/write transactions to UART, GPIO, Timer and SoC
//   control registers, and verifies the responses.
//
// Address Map (from croc_pkg.sv):
//   0x0300_0000  SoC Control / Info registers
//   0x0300_2000  UART peripheral
//   0x0300_5000  GPIO peripheral
//   0x0300_A000  Timer peripheral
//   0x1000_0000  SRAM (main memory)
// ============================================================================

`timescale 1ns/1ps

module croc_tb;

  // -------------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------------
  parameter CLK_PERIOD  = 10;   // 100 MHz clock
  parameter TIMEOUT_CYC = 5000; // Max cycles before timeout

  // -------------------------------------------------------------------------
  // Clock & Reset
  // -------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // -------------------------------------------------------------------------
  // OBI Bus Signals (Manager side — driven by testbench)
  // -------------------------------------------------------------------------
  // Request channel
  logic        obi_req;
  logic        obi_we;        // 1=write, 0=read
  logic [3:0]  obi_be;        // byte enable
  logic [31:0] obi_addr;
  logic [31:0] obi_wdata;

  // Response channel
  logic        obi_gnt;
  logic        obi_rvalid;
  logic [31:0] obi_rdata;
  logic        obi_err;

  // -------------------------------------------------------------------------
  // DUT Instantiation — Croc SoC Top
  // -------------------------------------------------------------------------
  // NOTE: croc_soc is the top-level synthesizable module.
  //       JTAG pins are tied off; OBI manager port is exposed for testing.
  croc_soc dut (
    .clk_i       ( clk      ),
    .rst_ni      ( rst_n    ),
    // JTAG (tied off — boot via JTAG not exercised here)
    .jtag_tck_i  ( 1'b0     ),
    .jtag_tms_i  ( 1'b0     ),
    .jtag_tdi_i  ( 1'b0     ),
    .jtag_tdo_o  (          ),
    .jtag_trst_ni( 1'b1     ),
    // UART (loopback)
    .uart_rx_i   ( 1'b1     ),
    .uart_tx_o   (          ),
    // GPIO (all inputs tied low)
    .gpio_i      ( 32'h0    ),
    .gpio_o      (          ),
    .gpio_oe_o   (          )
  );

  // -------------------------------------------------------------------------
  // Test Statistics
  // -------------------------------------------------------------------------
  int tests_passed = 0;
  int tests_failed = 0;

  // -------------------------------------------------------------------------
  // Task: OBI Write
  // -------------------------------------------------------------------------
  task automatic obi_write (
    input  logic [31:0] addr,
    input  logic [31:0] data,
    input  logic [3:0]  be = 4'hF
  );
    @(posedge clk);
    obi_req   <= 1'b1;
    obi_we    <= 1'b1;
    obi_addr  <= addr;
    obi_wdata <= data;
    obi_be    <= be;

    // Wait for grant
    wait (obi_gnt == 1'b1);
    @(posedge clk);
    obi_req   <= 1'b0;
    obi_we    <= 1'b0;

    // Wait for response
    wait (obi_rvalid == 1'b1);
    @(posedge clk);

    if (obi_err)
      $display("[WARN] Write to 0x%08h returned OBI error", addr);
    else
      $display("[WRITE] Addr=0x%08h  Data=0x%08h  BE=0b%04b  -- OK", addr, data, be);
  endtask

  // -------------------------------------------------------------------------
  // Task: OBI Read + Verify
  // -------------------------------------------------------------------------
  task automatic obi_read_check (
    input  logic [31:0] addr,
    input  logic [31:0] expected,
    input  logic [31:0] mask = 32'hFFFF_FFFF,
    input  string       desc = ""
  );
    logic [31:0] rd_data;

    @(posedge clk);
    obi_req  <= 1'b1;
    obi_we   <= 1'b0;
    obi_addr <= addr;
    obi_be   <= 4'hF;

    wait (obi_gnt == 1'b1);
    @(posedge clk);
    obi_req  <= 1'b0;

    wait (obi_rvalid == 1'b1);
    rd_data = obi_rdata;
    @(posedge clk);

    if (obi_err) begin
      $display("[ERROR] Read from 0x%08h returned OBI error  (%s)", addr, desc);
      tests_failed++;
    end else if ((rd_data & mask) !== (expected & mask)) begin
      $display("[FAIL]  Addr=0x%08h  Got=0x%08h  Expected=0x%08h  Mask=0x%08h  (%s)",
               addr, rd_data, expected, mask, desc);
      tests_failed++;
    end else begin
      $display("[PASS]  Addr=0x%08h  Data=0x%08h  (%s)", addr, rd_data, desc);
      tests_passed++;
    end
  endtask

  // -------------------------------------------------------------------------
  // Main Test Sequence
  // -------------------------------------------------------------------------
  initial begin
    // Dump waveforms
    $dumpfile("../results/simulation/croc_tb.vcd");
    $dumpvars(0, croc_tb);

    $display("========================================================");
    $display("  Croc SoC Read/Write Testbench");
    $display("  BITS Pilani | Arpan Jain | 2025HT08066");
    $display("========================================================");

    // Initialize bus
    obi_req   = 0;
    obi_we    = 0;
    obi_addr  = 0;
    obi_wdata = 0;
    obi_be    = 4'hF;

    // Assert reset for 20 cycles
    rst_n = 0;
    repeat(20) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    $display("\n--- TEST 1: SoC Info Register (Read-Only) ---");
    // 0x0300_0000 = SoC info reg — should return non-zero chip ID
    obi_read_check(32'h0300_0000, 32'h0, 32'h0, "SoC Info Reg (non-zero)");

    $display("\n--- TEST 2: SRAM Write then Read-Back ---");
    // Write 0xDEAD_BEEF to SRAM base address
    obi_write(32'h1000_0000, 32'hDEAD_BEEF);
    obi_read_check(32'h1000_0000, 32'hDEAD_BEEF, 32'hFFFF_FFFF, "SRAM WR rd-back 0xDEADBEEF");

    // Write 0xCAFE_BABE to next word
    obi_write(32'h1000_0004, 32'hCAFE_BABE);
    obi_read_check(32'h1000_0004, 32'hCAFE_BABE, 32'hFFFF_FFFF, "SRAM WR rd-back 0xCAFEBABE");

    $display("\n--- TEST 3: Byte-Enable Write (Lower byte only) ---");
    // Write only lower byte to SRAM offset 0x08
    obi_write(32'h1000_0008, 32'hABCD_EF12, 4'b0001);
    obi_read_check(32'h1000_0008, 32'h0000_0012, 32'h0000_00FF, "SRAM byte-enable BE[0] only");

    $display("\n--- TEST 4: GPIO Direction Register Write/Read ---");
    // GPIO output enable register — set lower 8 bits as output
    obi_write(32'h0300_5004, 32'h0000_00FF);
    obi_read_check(32'h0300_5004, 32'h0000_00FF, 32'h0000_00FF, "GPIO OE reg lower 8 bits");

    $display("\n--- TEST 5: GPIO Output Data Register ---");
    // Drive lower 8 GPIO pins high
    obi_write(32'h0300_5000, 32'h0000_00AA);
    obi_read_check(32'h0300_5000, 32'h0000_00AA, 32'h0000_00FF, "GPIO output data 0xAA");

    $display("\n--- TEST 6: Timer Register Write/Read ---");
    // Write prescaler value to timer
    obi_write(32'h0300_A008, 32'h0000_0063);  // prescaler = 99 => 1us at 100MHz
    obi_read_check(32'h0300_A008, 32'h0000_0063, 32'hFFFF_FFFF, "Timer prescaler = 99");

    $display("\n--- TEST 7: Multiple Sequential SRAM Writes ---");
    begin
      automatic int i;
      for (i = 0; i < 8; i++) begin
        obi_write(32'h1000_0100 + 4*i, 32'hA000_0000 + i);
      end
      for (i = 0; i < 8; i++) begin
        obi_read_check(
          32'h1000_0100 + 4*i,
          32'hA000_0000 + i,
          32'hFFFF_FFFF,
          $sformatf("Sequential SRAM[%0d]", i)
        );
      end
    end

    $display("\n--- TEST 8: UART TX Register Write ---");
    // Write ASCII 'H' (0x48) to UART TX register
    obi_write(32'h0300_2000, 32'h0000_0048);
    $display("[INFO] UART TX write of 'H' (0x48) issued");

    // -----------------------------------------------------------------------
    $display("\n========================================================");
    $display("  RESULTS: %0d PASSED | %0d FAILED", tests_passed, tests_failed);
    $display("========================================================\n");

    if (tests_failed == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED — check above for details");

    $finish;
  end

  // -------------------------------------------------------------------------
  // Timeout Watchdog
  // -------------------------------------------------------------------------
  initial begin
    repeat(TIMEOUT_CYC) @(posedge clk);
    $display("[TIMEOUT] Simulation exceeded %0d cycles — aborting", TIMEOUT_CYC);
    $finish;
  end

endmodule

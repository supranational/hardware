// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module multiplier_tb;
  logic                             clk;
  logic [msu_pkg::TotalWordBits:0]  nr_a;   // Non-redundant bits var a
  logic [msu_pkg::TotalWordBits:0]  nr_b;   // Non-redundant bits var b
  logic [msu_pkg::TotalWordBits:0]  r_a;    // Redundant bits var a
  logic [msu_pkg::TotalWordBits:0]  r_b;    // Redundant bits var b

  logic [msu_pkg::MulPartialBits:0] part_nr;
  logic [msu_pkg::MulPartialBits:0] part_r;

  logic [(msu_pkg::MulResultBits - 1):0]  mul_result;

  logic [(msu_pkg::TotalBits - 1):0]      rand_a;
  logic [(msu_pkg::TotalBits - 1):0]      rand_b;
  logic [(msu_pkg::TotalBits - 1):0]      value_a;
  logic [(msu_pkg::TotalBits - 1):0]      value_b;
  logic [(msu_pkg::MulResultBits - 1):0]  expected_a_times_b;

  multiplier i_multiplier (
    .clk_i(clk),
    .nr_a_i(nr_a),
    .nr_b_i(nr_b),
    .r_a_i(r_a),
    .r_b_i(r_b),
    .part_nr_o(part_nr),
    .part_r_o(part_r)
  );

  always #2 clk = ~clk;

  initial begin
    $write("\n");
    $display("** Design Parameters **");
    $display("WordBits:        %d", msu_pkg::WordBits);
    $display("WordElements:    %d", msu_pkg::WordElements);
    $display("TargetBits:      %d", msu_pkg::TargetBits);
    $display("NumElements:     %d", msu_pkg::NumElements);
    $display("FullWordBits:    %d", msu_pkg::FullWordBits);
    $display("TotalWordBits:   %d", msu_pkg::TotalWordBits);
    $display("TotalBits:       %d", msu_pkg::TotalBits);
    $display("MulGridRows:     %d", msu_pkg::MulGridRows);
    $display("MulGridCols:     %d", msu_pkg::MulGridCols);
    $display("TreeBitWidth:    %d", msu_pkg::TreeBitWidth);
    $display("SumBits:         %d", msu_pkg::SumBits);
    $display("MulPartialBits:  %d", msu_pkg::MulPartialBits);
    $display("MulResultBits:   %d", msu_pkg::MulResultBits);
    $write("\n");

    clk  = 0;

    std::randomize(rand_a);
    std::randomize(rand_b);

    rand_a = '1;
    rand_b = '1;
    nr_a   = '0;
    nr_b   = '0;
    r_a    = '0;
    r_b    = '0;

    for (int i = 0; i < msu_pkg::NumElements; i++) begin
      nr_a += ((rand_a >> (msu_pkg::FullWordBits * i)) & msu_pkg::WordMask)
              << (i * msu_pkg::WordBits);
      nr_b += ((rand_b >> (msu_pkg::FullWordBits * i)) & msu_pkg::WordMask)
              << (i * msu_pkg::WordBits);
      r_a  += ((rand_a >> ((msu_pkg::FullWordBits * i) + msu_pkg::WordBits)) 
              & 1'b1) << ((i + 1) * msu_pkg::WordBits);
      r_b  += ((rand_b >> ((msu_pkg::FullWordBits * i) + msu_pkg::WordBits))
              & 1'b1) << ((i + 1) * msu_pkg::WordBits);
    end

    expected_a_times_b = (nr_a + r_a) * (nr_b + r_b);

    value_a = (nr_a + r_a);
    value_b = (nr_b + r_b);

    $display("Multiplier random input variables");
    $display("rand_a   0x%x", rand_a);
    $display("rand_b   0x%x", rand_b);
    $display("nr_a     0x%x", nr_a);
    $display("nr_b     0x%x", nr_b);
    $display("r_a      0x%x", r_a);
    $display("r_b      0x%x", r_b);
    $display("value_a  0x%x", value_a);
    $display("value_b  0x%x", value_b);

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    mul_result = part_nr + part_r;

    $display("");
    $display("** Checking multiply output **");
    if (mul_result !== expected_a_times_b) begin
      $display("%c[1;31m",27);
      $display("***************");
      $display("**** ERROR **** - mismatch");
      $display("***************");
      $display("Final Mul:     0x%x", mul_result);
      $display("Expected:      0x%x", expected_a_times_b);
      $display("%c[0m",27);
    end
    else begin
      $display("%c[1;32m",27);
      $display("****************");
      $display("**** PASSED ****");
      $display("****************");
      $display("Result:    0x%x", expected_a_times_b);
      $display("%c[0m",27);
    end

    $finish();
  end
endmodule

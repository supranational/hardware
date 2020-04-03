// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Testbench for the modular squaring unit

module msu_tb;
  localparam int NumSquareIterations = 100;

  logic [(msu_pkg::TotalBits - 1):0]            rand_a;
  logic [((msu_pkg::TotalBits * 2) - 1):0]      expected_a_squared;
  logic [((msu_pkg::TotalBits * 2) - 1):0]      expected_a_mont_squared;
  logic [(msu_pkg::TotalBits - 1):0]            expected_a_squared_mod_n;
  logic [(msu_pkg::TotalBits - 1):0]            expected_a_mont_squared_mod_n;

  logic [(msu_pkg::TotalWordBits - 1):0]        value_a;
  logic [((msu_pkg::TotalWordBits * 2) - 1):0]  value_a_times_r;
  logic [(msu_pkg::TotalWordBits - 1):0]        value_a_mont;

  logic [(msu_pkg::TotalBits - 1):0]            msu_value;
  logic [((msu_pkg::TotalBits * 2) - 1):0]      msu_value_times_rinv;
  logic [(msu_pkg::TotalBits - 1):0]            msu_value_mod_n;

  logic                                         clk;
  logic                                         rst_n;
  logic                                         start;
  logic                                         stop;
  logic                                         sq_out_valid;
  logic [(msu_pkg::TotalWordBits - 1):0]        sq_in_nr;
  logic [(msu_pkg::TotalWordBits - 1):0]        sq_in_r;
  logic [(msu_pkg::TotalWordBits - 1):0]        sq_out_nr;
  logic [(msu_pkg::TotalWordBits - 1):0]        sq_out_r;

  msu i_msu (
    .clk_i(clk),
    .rst_ni(rst_n),
    .start_i(start),
    .stop_i(stop),
    .sq_nr_i(sq_in_nr),
    .sq_r_i(sq_in_r),
    .sq_nr_o(sq_out_nr),
    .sq_r_o(sq_out_r),
    .valid_o(sq_out_valid)
  );

  always #2 clk = ~clk;

  initial begin
    assert(msu_pkg::Modulus != '0) else $fatal("Need to set Modulus");

    $write("\n");
    $display("** Design Parameters **");
    $display("WordBits:        %d", msu_pkg::WordBits);
    $display("WordElements:    %d", msu_pkg::WordElements);
    $display("TargetBits:      %d", msu_pkg::TargetBits);
    $display("NumElements:     %d", msu_pkg::NumElements);
    $display("FullWordBits:    %d", msu_pkg::FullWordBits);
    $display("TotalWordBits:   %d", msu_pkg::TotalWordBits);
    $display("SqGridRows:      %d", msu_pkg::SqGridRows);
    $display("SqGridCols:      %d", msu_pkg::SqGridCols);
    $display("TreeBits:        %d", msu_pkg::TreeBits);
    $display("OuterTriTrees:   %d", msu_pkg::OuterTriTrees);
    $display("LowerTriBits:    %d", msu_pkg::LowerTriBits);
    $display("UpperTriBits:    %d", msu_pkg::UpperTriBits);
    $display("SqSumBits:       %d", msu_pkg::SqSumBits);
    $display("RedGridRows:     %d", msu_pkg::RedGridRows);
    $display("RedGridCols:     %d", msu_pkg::RedGridCols);
    $display("RedSumBits:      %d", msu_pkg::RedSumBits);
    $display("Modulus:         %h", msu_pkg::Modulus);
    $display("BtoTheN:         %h", msu_pkg::BtoTheN);
    $display("Mu:              %h", msu_pkg::Mu);
    $display("RInv:            %h", msu_pkg::RInv);
    $write("\n");
    $write("\n");

    clk   = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    stop  = 1'b0;

    // Generate random value that include redundant bits
    std::randomize(rand_a);
    //rand_a  = '1;

    value_a = '0;

    // Get the true value for each redundant variable
    for (int i = 0; i < msu_pkg::NumElements; i++) begin
      value_a += ((rand_a >> (msu_pkg::FullWordBits * i)) & 
                  msu_pkg::FullWordBitsMask)
                 << (i * msu_pkg::WordBits);
    end

    // Move value to Montgomery space
    // a_mont = (a * R) % m
    value_a_times_r = value_a * msu_pkg::BtoTheN;
    value_a_mont    = value_a_times_r % msu_pkg::Modulus;

    $display("MSU input variables (original and Montgomery form)");
    $display("A                          0x%x", value_a);
    $display("A Montgomery               0x%x", value_a_mont);
    $display("Num square iterations        %d", NumSquareIterations);

    // Goes through MSU
    // msu_output = MSU(a_mont, a_mont) = a_mont^2 * R^-1 % m
    // (a * R) * (a * R) * R^-1 % m 
    // a^2 * R^2 * R^-1 % m 
    // a^2 * R % m

    // To get true mod multiply of original random variables
    // a^2 % m = a^2 * R * R^-1 % m

    expected_a_squared_mod_n = value_a;
    expected_a_mont_squared_mod_n = value_a_mont;
    for (int i = 0; i < NumSquareIterations; i++) begin
      // Calculate expected value post processing
      // a * a
      expected_a_squared = expected_a_squared_mod_n * expected_a_squared_mod_n;

      // a * a % m
      expected_a_squared_mod_n = expected_a_squared % msu_pkg::Modulus;
    end

    // Set MSU inputs to Montgomery form of input variables
    // Only using non-redundant inputs since value is already < modulus
    sq_in_nr = value_a_mont;
    sq_in_r  = '0;

    @(negedge clk);

    rst_n = 1'b1;

    @(negedge clk);
    @(negedge clk);
    @(negedge clk);

    start = 1'b1;

    @(negedge clk);

    start = 1'b0;

    @(negedge clk);

    for (int i = 0; i < NumSquareIterations; i++) begin
      @(negedge clk);
      @(negedge clk);
    end

    stop  = 1'b1;

    @(negedge clk);

    stop  = 1'b0;

    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);

    // Get final reduced value out of MSU
    // Post process to bring out of Montgomery 

    // value = non-redundant + redundant vectors
    // msu_value = a^2 * R % m
    msu_value            = sq_out_nr + sq_out_r;

    // Take out of Montgomery form
    // a^2 = a^2 * R * R^-1
    msu_value_times_rinv = msu_value * msu_pkg::RInv;

    // Do final modular reduction 
    // a^2 % m
    msu_value_mod_n      = msu_value_times_rinv % msu_pkg::Modulus;

    $display("MSU output and post processing");
    $display("MSU Value:                 0x%x", msu_value);
    $display("msu_value_mod_n:           0x%x", msu_value_mod_n);
    $display("expected_a_squared_mod_n:  0x%x", expected_a_squared_mod_n);

    $display("");
    $display("** Checking post processed mod mul output **");
    if (msu_value_mod_n !== expected_a_squared_mod_n) begin
      $display("%c[1;31m",27);
      $display("***************");
      $display("**** ERROR **** - mismatch");
      $display("***************");
      $display("a * b mod m:               0x%x", msu_value_mod_n);
      $display("Expected:                  0x%x", expected_a_squared_mod_n);
      $display("%c[0m",27); 
      $finish();
    end
    else begin
      $display("%c[1;32m",27);
      $display("Modular multiply result is correct");
      $display("a * b mod m:               0x%x", msu_value_mod_n);
      $display("%c[0m",27); 
    end

    // If made it this far then all checks above passed
    $display("%c[1;32m",27);
    $display("****************");
    $display("**** PASSED ****");
    $display("****************");
    $display("%c[0m",27); 

    $finish();
  end
endmodule

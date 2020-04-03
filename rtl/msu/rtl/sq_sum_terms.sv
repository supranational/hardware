// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Input is an array of terms to sum together
// Output is the sum of all terms in the input array

module sq_sum_terms (
  input  logic                                clk_i,
  input  logic [(msu_pkg::TreeBits - 1):0]    terms_i[msu_pkg::SqGridRows],
  output logic [(msu_pkg::SqSumBits - 1):0]   sum_o
);

  localparam int FlopInputsAndOutputs = 0;

  if (FlopInputsAndOutputs == 1) begin : flop_io
    // Need to flop inputs and outputs
    logic [(msu_pkg::TreeBits - 1):0] terms_q[msu_pkg::SqGridRows];
    always_ff @(posedge clk_i) begin
      terms_q <= terms_i;
    end
  
    logic [(msu_pkg::SqSumBits - 1):0] sum_d;
    always_ff @(posedge clk_i) begin
      sum_o <= sum_d;
    end
  
    always_comb begin
      sum_d = '0;
      for (int i = 0; i < msu_pkg::SqGridRows; i++) begin
        sum_d += terms_q[i];
      end
    end
  end
  else begin 
    // If not flopping inputs and outputs
    always_comb begin
      sum_o = '0;
      for (int i = 0; i < msu_pkg::SqGridRows; i++) begin
        sum_o += terms_i[i];
      end
    end
  end
endmodule

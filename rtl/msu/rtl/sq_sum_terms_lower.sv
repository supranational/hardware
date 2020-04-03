// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Input is an array of terms to sum together
// Output is the sum of all terms in the input array

module sq_sum_terms_lower (
  input  logic                                clk_i,
  input  logic [(msu_pkg::TreeBits - 1):0]    terms_i[msu_pkg::SqGridRowsLower],
  output logic [(msu_pkg::SqSumBits - 1):0]   sum_o
);

   always_comb begin
     sum_o = '0;
     for (int i = 0; i < msu_pkg::SqGridRowsLower; i++) begin
       sum_o += terms_i[i];
     end
   end
endmodule

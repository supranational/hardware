// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
  Accumulator built using "+" that sums a set of input terms.
  Parameterized to take any number of inputs, each of a common size
*/

module sum_terms
  #(
    parameter int NUM_ELEMENTS      = 9,
    parameter int BIT_LEN           = 16
    )
  (
   input  logic [BIT_LEN-1:0] terms[NUM_ELEMENTS],
   output logic [BIT_LEN-1:0] S
   );
  
  // Compute the sum of the elements of terms.
  always_comb begin
    S = 0;
    for(int k = 0; k < NUM_ELEMENTS; k++) begin
      S += terms[k];
    end
  end
endmodule

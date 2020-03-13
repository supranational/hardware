// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
  Group the input terms into sets of three for input into a carry save adder
  Shift the CSA carry output by 1 for use in the next level
  The sum already has the correct weight, therefore we only pad for consistency
  Any leftover terms that did not fit into a set are returned padded
*/

module carry_save_adder_tree_level
  #(
    parameter int NUM_ELEMENTS = 3,
    parameter int BIT_LEN      = 19,
    
    parameter int NUM_RESULTS  = (integer'(NUM_ELEMENTS/3) * 2) + 
                                 (NUM_ELEMENTS%3)
    )
  (
   input  logic [BIT_LEN-1:0] terms[NUM_ELEMENTS],
   output logic [BIT_LEN-1:0] results[NUM_RESULTS]
   );
  
  genvar i;
  generate
    for (i=0; i<(NUM_ELEMENTS / 3); i++) begin : csa_insts
      // Add three consecutive terms 
      carry_save_adder #(.BIT_LEN(BIT_LEN))
      carry_save_adder (
                        .A(terms[i*3]),
                        .B(terms[(i*3)+1]),
                        .Cin(terms[(i*3)+2]),
                        .Cout({results[i*2][0],
                               results[i*2][BIT_LEN-1:1]}),
                        .S(results[(i*2)+1][BIT_LEN-1:0])
                        );
    end
    
    // Save any unused terms for the next level 
    for (i=0; i<(NUM_ELEMENTS % 3); i++) begin : csa_level_extras
      always_comb begin
        results[(NUM_RESULTS - 1) - i][BIT_LEN-1:0] = 
               terms[(NUM_ELEMENTS- 1) - i][BIT_LEN-1:0];
      end
    end
  endgenerate
endmodule

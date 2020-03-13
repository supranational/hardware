// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/* 
   Compressor takes entry array of terms and produces c and s

               ----                        ----
              | FF |      Compressor ---> | FF | ---> c
   terms ---> |    | --->    Tree         |    | 
              | /\ |                 ---> | /\ | ---> s
               ----                        ----
                ^                           ^
    clk  -------|---------------------------|
*/

module compressor_tree
  #(
    parameter int NUM_ELEMENTS    = 9,
    parameter int BIT_LEN         = 16,
    parameter int EXTRA_TREE_BITS = $clog2(NUM_ELEMENTS*2),
    parameter int OUT_BIT_LEN     = BIT_LEN + EXTRA_TREE_BITS
    )
  (
   input logic                    clk,
   input logic [BIT_LEN-1:0]      terms[NUM_ELEMENTS],
   input logic                    reset,                          
   output logic [OUT_BIT_LEN-1:0] c,
   output logic [OUT_BIT_LEN-1:0] s
   );
  
  localparam int TERMS_PAD = EXTRA_TREE_BITS;
  
  logic [OUT_BIT_LEN-1:0]  terms_d1[NUM_ELEMENTS];
  logic [OUT_BIT_LEN-1:0]  c_result;
  logic [OUT_BIT_LEN-1:0]  s_result;
  
  always_ff @(posedge clk) begin
    for (int i=0; i<NUM_ELEMENTS; i=i+1) begin 
      terms_d1[i] <= {{TERMS_PAD{1'b0}}, terms[i]};
    end
    
    c        <= c_result;
    s        <= s_result;
  end

  compressor_tree_3_to_2 #(.NUM_ELEMENTS(NUM_ELEMENTS),
                           .BIT_LEN(OUT_BIT_LEN)
                           )
  compressor_tree_3_to_2 (
                          .terms(terms_d1),
                          .C(c_result),
                          .S(s_result)
                          );
endmodule

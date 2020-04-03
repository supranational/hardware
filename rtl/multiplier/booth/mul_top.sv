// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module mul_top 
  #( parameter BITLEN = 17 )
  (
   input                           clk, 
   input                           reset, 
   input [BITLEN - 1:0]            A,
   input [BITLEN - 1:0]            B,
   output logic [2 * BITLEN - 1:0] C
   ); 
  
  logic [2 * BITLEN - 1:0] C_wire; 
  
  logic [BITLEN - 1:0]     A_1d; 
  logic [BITLEN - 1:0]     B_1d; 
  
  always_ff @(posedge clk) begin 
    if (reset) begin 
      A_1d <= {BITLEN{1'b0}}; 
      B_1d <= {BITLEN{1'b0}}; 
      C    <= {2 * BITLEN{1'b0}}; 
    end else begin 
      A_1d <= A; 
      B_1d <= B; 
      C    <= C_wire; 
    end 
  end 

  // Alternatively, instantiate mul_star to use a multiplier coded using
  // "*" instead of an explicitly specified structure.
  mul_trees #(.BITLEN(BITLEN)) mytree
    ( A_1d, 
      B_1d, 
      C_wire 
      ); 
endmodule

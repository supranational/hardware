// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
  Parameterized width full multiply

              -------       ----
    A    --> |       |     | FF |
             | A * B | --> |    | --> P
    B    --> |       |     | /\ |
              -------       ----
                             ^
    clk  --------------------|


  Can be used to represent an FPGA DSP multiplier for unsigned values
*/

module multiplier
  #(
    parameter integer A_BIT_LEN       = 17,
    parameter integer B_BIT_LEN       = 17,
    parameter integer MUL_OUT_BIT_LEN = A_BIT_LEN + B_BIT_LEN
    )
  (
   input  logic                       clk,
   input  logic [A_BIT_LEN-1:0]       A,
   input  logic [B_BIT_LEN-1:0]       B,
   output logic [MUL_OUT_BIT_LEN-1:0] P
   );
  
  logic [MUL_OUT_BIT_LEN-1:0] P_result;
  
  always_comb begin
    P_result[MUL_OUT_BIT_LEN-1:0] = A[A_BIT_LEN-1:0] * B[B_BIT_LEN-1:0];
  end
  
  always_ff @(posedge clk) begin
    P[MUL_OUT_BIT_LEN-1:0]  <= P_result[MUL_OUT_BIT_LEN-1:0];
  end
endmodule

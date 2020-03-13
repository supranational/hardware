// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module adder
  #(
    parameter int BIT_LEN   = 16
    )
  (
   input                     clk,
   input                     reset,
   input logic [BIT_LEN-1:0] A,
   input logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]  S
   );
  
  logic [BIT_LEN-1:0]       A_d1;
  logic [BIT_LEN-1:0]       B_d1;
  logic [BIT_LEN:0]         S_m1;
  
  always @(posedge clk) begin
    A_d1 <= A;
    B_d1 <= B;
    S    <= S_m1;
  end
  
`ifdef KSA
  kogge_stone_adder
`endif
`ifdef BKA
  brent_kung_adder
`endif
`ifdef CLA
  carry_lookahead_adder
`endif
`ifdef RCA
  ripple_carry_adder
`endif
    #(.BIT_LEN(BIT_LEN)
      )
  adder (
         .A(A_d1[BIT_LEN-1:0]),
         .B(B_d1[BIT_LEN-1:0]),
         .S(S_m1[BIT_LEN:0])
         );
endmodule

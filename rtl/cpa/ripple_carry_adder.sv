// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module ripple_carry_adder
  #(
    parameter int BIT_LEN      = 17
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]   S
   );
  
  logic [BIT_LEN:0]   carry;
  
  always_comb begin
    carry[0]   = 1'b0;
    S[BIT_LEN] = carry[BIT_LEN];
  end
  
   genvar i;
  generate
    for (i=0; i<BIT_LEN; i=i+1) begin : full_adders
      full_adder full_adder (
                             .A(A[i]),
                             .B(B[i]),
                             .Cin(carry[i]),
                             .Cout(carry[i+1]),
                             .S(S[i])
                             );
    end
  endgenerate
endmodule


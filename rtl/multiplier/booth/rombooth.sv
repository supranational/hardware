// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// 0 1 1 2 -2 -1 -1 0

module rombooth
  // LIMITATION: this module only works for 17 bits today.
  #( parameter BITLEN = 17 )
  (
   input [2:0]                     A,
   input [BITLEN:0]                multiplicand,
   output logic [BITLEN * 2 - 1:0] B
   );
  
  logic [BITLEN:0] twosmult;
  
  assign twosmult = (~multiplicand) + 18'h1;
  
  always_comb begin
    case (A)
      3'b000 : B <= 34'h0;
      3'b001 : B <= {16'h0, multiplicand};
      3'b010 : B <= {16'h0, multiplicand};
      3'b011 : B <= {15'h0, multiplicand, 1'b0};
      3'b100 : B <= {{15{twosmult[17]}}, twosmult, 1'b0};
      3'b101 : B <= {{16{twosmult[17]}}, twosmult};
      3'b110 : B <= {{16{twosmult[17]}}, twosmult};
      3'b111 : B <= 34'h0;
    endcase
  end
endmodule

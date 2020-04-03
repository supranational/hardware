// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module csa_bitlen 
  #( parameter BITLEN = 34 )
  (
   output [BITLEN - 1:0] C,
   output [BITLEN - 1:0] S,
   input [BITLEN - 1:0]  X,
   input [BITLEN - 1:0]  Y,
   input [BITLEN - 1:0]  Z
   );
  
  genvar i;
  generate
    for (i = 0 ; i < BITLEN ; i = i + 1) begin: loop1
      FA myadder(C[i], S[i], X[i], Y[i], Z[i]);
    end
  endgenerate
endmodule

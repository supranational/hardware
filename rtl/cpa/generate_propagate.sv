// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module generate_propagate
  #(
    parameter int BIT_LEN      = 17
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN-1:0] g,
   output logic [BIT_LEN-1:0] p
   );
  
  always_comb begin
    g = A & B;
    p = A ^ B;
    // Alternatively:
    //p = A | B;
  end
endmodule


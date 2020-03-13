// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module black_processor
  #(
    parameter int BIT_LEN      = 17
    )
  (
   input  logic [BIT_LEN-1:0] g_in,
   input  logic [BIT_LEN-1:0] p_in,
   input  logic [BIT_LEN-1:0] g_prime_in,
   input  logic [BIT_LEN-1:0] p_prime_in,
   output logic [BIT_LEN-1:0] g_out,
   output logic [BIT_LEN-1:0] p_out
   );
  
  always_comb begin
    g_out = g_in | (p_in & g_prime_in);
    p_out = p_in & p_prime_in;
  end
endmodule

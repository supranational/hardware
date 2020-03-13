// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Right now supports up to 16-bit CLA.  Need to modify for larger
// Could change intermediate lookahead_generators into modified 4-bit adders
// Need to add another level to get to 64 bit
module carry_lookahead_adder
  #(
    parameter int BIT_LEN      = 16
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]   S
   );
  
  localparam int GEN_WIDTH  = 4; // Currently fixed at 4
  localparam int NUM_GROUPS = (BIT_LEN / GEN_WIDTH) + 1;
  
  logic [BIT_LEN-1:0]   p;
  logic [BIT_LEN-1:0]   g;
  logic [BIT_LEN-1:0]   c;
  
  logic [NUM_GROUPS-1:0] p_group;
  logic [NUM_GROUPS-1:0] g_group;
  logic [GEN_WIDTH-2:0]  gen_c;
  
  // Could calculate p as A | B or as A ^ B
  // If using A | B -> s = c ^ A ^ B
  // If using A ^ B -> s = c ^ p
  
  always_comb begin
    g    = A & B;
    p    = A | B;
    c[0] = 1'b0;
    
    // (5) 4, 8, 12
    for (int j=0; j<GEN_WIDTH-1; j=j+1) begin 
      c[(j+1)*GEN_WIDTH] = gen_c[j];
    end
    
    for (int j=0; j<BIT_LEN; j=j+1) begin 
      S[j] = A[j] ^ B[j] ^ c[j];
    end
    
    //cout = g[0,n-1] | (c0 & p[0,n-1])  c0 = 0
    S[BIT_LEN] = g_group[NUM_GROUPS-1];
  end
  
  genvar i;
  generate
    for (i=0; i<NUM_GROUPS-1; i=i+1) begin : generators
      lookahead_generator_x4 
           lookahead_generator_x4 (
                                   .p(p[((i+1)*GEN_WIDTH)-1:(i*GEN_WIDTH)]),
                                   .g(g[((i+1)*GEN_WIDTH)-1:(i*GEN_WIDTH)]),
                                   .cin(c[i*GEN_WIDTH]),
                                   .cout(c[((i+1)*GEN_WIDTH)-1:(i*GEN_WIDTH)+1]),
                                   .p_group(p_group[i]),
                                   .g_group(g_group[i])
                                   ); 
    end
  endgenerate
  
  lookahead_generator_x4 
    lookahead_generator_x4 (
                            .p(p_group[NUM_GROUPS-2:0]),
                            .g(g_group[NUM_GROUPS-2:0]),
                            .cin(c[0]),
                            .cout(gen_c),
                            .p_group(p_group[NUM_GROUPS-1]),
                            .g_group(g_group[NUM_GROUPS-1])
                            ); 
endmodule


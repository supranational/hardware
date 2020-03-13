// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "adder_defines.sv"

module brent_kung_adder
  #(
    parameter int BIT_LEN   = 8
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]   S
   );
  
  localparam NUM_ROWS = 7;
  localparam int PROCESSORS[NUM_ROWS][BIT_LEN] = '{
    '{ W_P, G_P, W_P, B_P, W_P, B_P, W_P, B_P,
       W_P, B_P, W_P, B_P, W_P, B_P, W_P, B_P }, // 0
    '{ W_P, W_P, W_P, G_P, W_P, W_P, W_P, B_P,
       W_P, W_P, W_P, B_P, W_P, W_P, W_P, B_P }, // 1
    '{ W_P, W_P, W_P, W_P, W_P, W_P, W_P, G_P,
       W_P, W_P, W_P, W_P, W_P, W_P, W_P, B_P }, // 2
    '{ W_P, W_P, W_P, W_P, W_P, W_P, W_P, W_P,
       W_P, W_P, W_P, W_P, W_P, W_P, W_P, G_P }, // 3
    '{ W_P, W_P, W_P, W_P, W_P, W_P, W_P, W_P,
       W_P, W_P, W_P, G_P, W_P, W_P, W_P, W_P }, // 4
    '{ W_P, W_P, W_P, W_P, W_P, G_P, W_P, W_P,
       W_P, G_P, W_P, W_P, W_P, G_P, W_P, W_P }, // 5
    '{ W_P, W_P, G_P, W_P, G_P, W_P, G_P, W_P,
       G_P, W_P, G_P, W_P, G_P, W_P, G_P, W_P }  // 6
    };
  localparam int PRIME_INPUTS[NUM_ROWS][BIT_LEN] = '{
    '{  0,  0,  2,  2,  4,  4,  6,  6,
        8,  8, 10, 10, 12, 12, 14, 14 }, // 0
    '{  0,  1,  2,  1,  4,  5,  6,  5,
        8,  9, 10,  9, 12, 13, 14, 13 }, // 1
    '{  0,  1,  2,  3,  4,  5,  6,  3,
        8,  9, 10, 11, 12, 13, 14, 11 }, // 2
    '{  0,  1,  2,  3,  4,  5,  6,  7,
        8,  9, 10, 11, 12, 13, 14,  7 }, // 3
    '{  0,  1,  2,  3,  4,  5,  6,  7,
        8,  9, 10,  7, 12, 13, 14, 15 }, // 4
    '{  0,  1,  2,  3,  4,  3,  6,  7,
        8,  7, 10, 11, 12, 11, 14, 15 }, // 5
    '{  0,  1,  1,  3,  3,  5,  5,  7,
        7,  9,  9, 11, 11, 13, 13, 15 }  // 6
    };
   

  parallel_prefix_adder #(.BIT_LEN(BIT_LEN),
                          .NUM_ROWS(7),
                          .PROCESSORS(PROCESSORS),
                          .PRIME_INPUTS(PRIME_INPUTS)
                          )
  ppa_16_brent_kung (.A(A[BIT_LEN-1:0]),
                     .B(B[BIT_LEN-1:0]),
                     .S(S[BIT_LEN:0])
                     );
endmodule

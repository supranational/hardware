/*******************************************************************************
  Copyright 2019 Supranational LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*******************************************************************************/

`include "adder_defines.sv"

module kogge_stone_adder
  #(
    parameter int BIT_LEN   = 8
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]   S
   );
  
  // 4 bits
  // localparam NUM_ROWS = 2;
  // localparam int PROCESSORS[NUM_ROWS][BIT_LEN] = '{
  //                            '{ W_P, G_P, B_P, B_P }, // 0
  //                            '{ W_P, W_P, G_P, G_P }  // 1
  //                                                  };
  
  // localparam int PRIME_INPUTS[NUM_ROWS][BIT_LEN] = '{
  //                            '{  0,  0,  1,  2 }, // 0
  //                            '{  0,  1,  0,  1 }  // 1
  //                                                    };
  
  
  // 16 bits
  localparam NUM_ROWS = 4;
  localparam int PROCESSORS[NUM_ROWS][BIT_LEN] = '{
    '{ W_P, G_P, B_P, B_P, B_P, B_P, B_P, B_P,
       B_P, B_P, B_P, B_P, B_P, B_P, B_P, B_P }, // 0
    '{ W_P, W_P, G_P, G_P, B_P, B_P, B_P, B_P,
       B_P, B_P, B_P, B_P, B_P, B_P, B_P, B_P }, // 1
    '{ W_P, W_P, W_P, W_P, G_P, G_P, G_P, G_P,
       B_P, B_P, B_P, B_P, B_P, B_P, B_P, B_P }, // 2
    '{ W_P, W_P, W_P, W_P, W_P, W_P, W_P, W_P,
       G_P, G_P, G_P, G_P, G_P, G_P, G_P, G_P }  // 3
    };

   localparam int PRIME_INPUTS[NUM_ROWS][BIT_LEN] = '{
    '{  0,  0,  1,  2,  3,  4,  5,  6,
        7,  8,  9, 10, 11, 12, 13, 14 }, // 0
    '{  0,  1,  0,  1,  2,  3,  4,  5,
        6,  7,  8,  9, 10, 11, 12, 13 }, // 1
    '{  0,  1,  2,  3,  0,  1,  2,  3,
        4,  5,  6,  7,  8,  9, 10, 11 }, // 2
    '{  0,  1,  2,  3,  4,  5,  6,  7,
        0,  1,  2,  3,  4,  5,  6,  7 }  // 3
    };

  parallel_prefix_adder #(.BIT_LEN(BIT_LEN),
                          .NUM_ROWS(NUM_ROWS),
                          .PROCESSORS(PROCESSORS),
                          .PRIME_INPUTS(PRIME_INPUTS)
                          )
  kogge_stone_adder (
                     .A(A[BIT_LEN-1:0]),
                     .B(B[BIT_LEN-1:0]),
                     .S(S[BIT_LEN:0])
                     );
endmodule

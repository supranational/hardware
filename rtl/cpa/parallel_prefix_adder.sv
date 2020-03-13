// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
   Implements a Parameterized Parallel Prefix Adder
   3 stages 
     Generate/Propagate 
     Group carry
     Sum

   The group carry stage may have many levels.  
   The smallest for N bits is log2(N)
   The largest for N bits is N-1

   Each level has one of three processors per node (white, gray, black)

   White: (g_out, p_out) = (g_in, p_in)
   Gray:  (g_out, p_out) = (g_in | (p_in & g_prime_in), p_in)
   Black: (g_out, p_out) = (g_in | (p_in & g_prime_in), (p_in & p_prime_in))

   The graph is defined by two parameters
   PROCESSORS - which processor this node should be
   PRIME_INPUTS - which other node in the previous level feeds the processor

               -----------
    i:k   --> |           |
              | Processor | --> i:j
    k-1:j --> |           |
               -----------
   
   i:k is this column's node from the previous row
   k-1:j is defined in the PRIME_INPUTS parameter array
   PROCESSORS defines which type of processor to instantiate
   
   Currently only processor valency of two is supported per node

   Carry operator: o
   (G,P) o (G',P') = (G | (P&G'), P&P')
   (Gi:j, Pi:j) = (Gi:k, Pi:k) o (Gk-1:j, Pk-1:j)

   Example of the default 8-bit Kogge Stone 

             A7  B7  A6  B6  A5  B5  A4  B4  A3  B3  A2  B2  A1  B1  A0  B0
              |  |    |  |    |  |    |  |    |  |    |  |    |  |    |  |
  G/P Stage    GP      GP      GP      GP      GP      GP      GP      GP
              |  |    |  |    |  |    |  |    |  |    |  |    |  |    |  |
  ----------- |  |    |  |    |  |    |  |    |  |    |  |    |  |    |  |
              |  |    |  |    |  |    |  |    |  |    |  |    |  |    |  |
             (g7,p7) (g6,p6) (g5,p5) (g4,p4) (g3,p3) (g2,p2) (g1,p1) (g0,p0)
               |  _____|  _____|  _____|  _____|  _____|  _____|  _____| 
               | |     | |     | |     | |     | |     | |     | |     |
                B       B       B       B       B       B       G      W
               7:6     6:5     5:4     4:3     3:2     2:1     1:0    0:0
               |  _____|_______|       |       |       |       |       |
               | |     |  _____|_______|       |       |       |       |
               | |     | |     |  _____|_______|       |       |       |
  Group        | |     | |     | |     |  _____|_______|       |       | 
  Carry        | |     | |     | |     | |     |  _____|_______|       | 
  Stage        | |     | |     | |     | |     | |     |  _____|_______| 
               | |     | |     | |     | |     | |     | |     |       |
                B       B       B       B       G       G      W       W
               7:4     6:3     5:2     4:1     3:0     2:0    1:0    0:0
               |  _____|_______|_______|_______|       |       |       |
               | |     |  _____|_______|_______|_______|       |       |
               | |     | |     |  _____|_______|_______|_______|       |
               | |     | |     | |     |  _____|_______|_______|_______| 
               | |     | |     | |     | |     |       |       |       |
                G       G       G       G      W       W       W       W
               7:0     6:0     5:0     4:0    3:0     2:0     1:0     0:0
               |       |       |       |       |       |       |       |
  -----------  |       |       |       |       |       |       |       |
               |       |       |       |       |       |       |       |
          __G7_|  __G6_|  __G5_|  __G4_|  __G3_|  __G2_|  __G1_|  __G0_| 
         |     | |     | |     | |     | |     | |     | |     | |     |
  Sum    |    P7 |    P6 |    P5 |    P4 |    P3 |    P2 |    P1 |    P0
  Stage  |     | |     | |     | |     | |     | |     | |     | |     |
         |     XOR     XOR     XOR     XOR     XOR     XOR     XOR     |
         |      |       |       |       |       |       |       |      |
        S8     S7      S6      S5      S4      S3      S2      S1     S0
*/

`include "adder_defines.sv"

module parallel_prefix_adder
  #(
    // Parameters set as example 8-bit Kogge-Stone
    parameter int BIT_LEN   = 8,
    parameter int NUM_ROWS  = 3,
    parameter int PROCESSORS[NUM_ROWS][BIT_LEN] = '{
        //  0    1    2    3    4    5    6    7
        //  0    1    2    3    4    5    6    7
        '{ W_P, G_P, B_P, B_P, B_P, B_P, B_P, B_P }, // 0
        '{ W_P, W_P, G_P, G_P, B_P, B_P, B_P, B_P }, // 1
        '{ W_P, W_P, W_P, W_P, B_P, B_P, B_P, B_P }  // 2
    },
    parameter int PRIME_INPUTS[NUM_ROWS][BIT_LEN] = '{
        //  0   1   2   3   4   5   6   7
        '{  0,  0,  1,  2,  3,  4,  5,  6 }, // 0
        '{  0,  1,  0,  1,  2,  3,  4,  5 }, // 1
        '{  0,  1,  2,  3,  0,  1,  2,  3 }  // 2
    }
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]   S
   );
  
  logic [BIT_LEN-1:0] g[NUM_ROWS+1];
  logic [BIT_LEN-1:0] p[NUM_ROWS+1];
  
  always_comb begin
    g[0] = A & B;
    p[0] = A ^ B;
    
    for (int i=0; i<NUM_ROWS; i++) begin : rows
      for (int j=0; j<BIT_LEN; j++) begin : cols
        g[i+1][j] = (PROCESSORS[i][j] == W_P) ? 
                    g[i][j] :
                    g[i][j] | (p[i][j] & g[i][PRIME_INPUTS[i][j]]);
        
        p[i+1][j] = (PROCESSORS[i][j] == B_P) ? 
                    p[i][j] & p[i][PRIME_INPUTS[i][j]] :
                    p[i][j];
      end
    end
    
    S[0] = p[0][0];
    for (int i=1; i<BIT_LEN; i=i+1) begin
      S[i] = g[NUM_ROWS][i-1] ^ p[0][i];
    end
    S[BIT_LEN] = g[NUM_ROWS][BIT_LEN-1];
  end
endmodule

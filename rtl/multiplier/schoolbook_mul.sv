// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
   Multiply two arrays element by element using the schoolbook algorithm
   The products are split into low (L) and high (H) values
   The products in each column are summed using compressor trees
   Leave results in carry/sum format

   Example A*B 4x4 element multiply results in 8 carry/sum values 

                                           |----------------------------------|
                                           |   B3   |   B2   |   B1   |   B0  |
                                           |----------------------------------|
                                           |----------------------------------|
                                     x     |   A3   |   A2   |   A1   |   A0  |
                                           |----------------------------------|
      -------------------------------------------------------------------------

       Col
   Row     7        6        5        4        3        2        1        0
    0                                       A00B03L  A00B02L  A00B01L  A00B00L 
    1                              A00B03H  A00B02H  A00B01H  A00B00H          
    2                              A01B03L  A01B02L  A01B01L  A01B00L          
    3                     A01B03H  A01B02H  A01B01H  A01B00H                   
    4                     A02B03L  A02B02L  A02B01L  A02B00L                   
    5            A02B03H  A02B02H  A02B01H  A02B00H                            
    6            A03B03L  A03B02L  A03B01L  A03B00L                            
    7 + A03B03H  A03B02H  A03B01H  A03B00H
      -------------------------------------------------------------------------
         C7,S7    C6,S6    C5,S5    C4,S4    C3,S3    C2,S2    C1,S1    C0,S0
*/

module schoolbook_mul
  #(
    parameter integer NUM_ELEMENTS    = 33,
    parameter integer A_BIT_LEN       = 17,
    parameter integer B_BIT_LEN       = 17,
    parameter integer MUL_OUT_BIT_LEN = A_BIT_LEN + B_BIT_LEN,
    parameter integer WORD_LEN        = 16,
    parameter integer COL_BIT_LEN     = MUL_OUT_BIT_LEN - WORD_LEN,
    parameter integer TREE_HEIGHTS[260] = '{
    // 0   1   2   3   4   5   6   7   8   9 
       0,  0,  1,  1,  2,  3,  3,  4,  4,  4,  //   0 -   9
       5,  5,  5,  5,  6,  6,  6,  6,  6,  6,  //  10 -  19
       7,  7,  7,  7,  7,  7,  7,  7,  7,  8,  //  20 -  29
       8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  //  30 -  39
       8,  8,  8,  9,  9,  9,  9,  9,  9,  9,  //  40 -  49
       9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  //  50 -  59
       9,  9,  9,  9, 10, 10, 10, 10, 10, 10,  //  60 -  69
      10, 10, 10, 10, 10, 10, 10, 10, 10, 10,  //  70 -  79
      10, 10, 10, 10, 10, 10, 10, 10, 10, 10,  //  80 -  89
      10, 10, 10, 10, 10, 11, 11, 11, 11, 11,  //  90 -  99
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,  // 100 - 109
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,  // 110 - 119
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,  // 120 - 129
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,  // 130 - 139
      11, 11, 12, 12, 12, 12, 12, 12, 12, 12,  // 140 - 149
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12,  // 150 - 159
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12,  // 160 - 169
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12,  // 170 - 179
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12,  // 180 - 189
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12,  // 190 - 199
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12,  // 200 - 209
      12, 12, 13, 13, 13, 13, 13, 13, 13, 13,  // 210 - 219
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,  // 220 - 229
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,  // 230 - 239
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13,  // 240 - 249
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13   // 250 - 259
    },
    parameter integer TREE_HEIGHT     = TREE_HEIGHTS[((NUM_ELEMENTS*2)-1)],
    parameter integer OUT_BIT_LEN     = COL_BIT_LEN + TREE_HEIGHT
    )
  (
   input  logic                       clk,
   input  logic [A_BIT_LEN-1:0]       A[NUM_ELEMENTS],
   input  logic [B_BIT_LEN-1:0]       B[NUM_ELEMENTS],
   output logic [OUT_BIT_LEN-1:0]     Cout[NUM_ELEMENTS*2],
   output logic [OUT_BIT_LEN-1:0]     S[NUM_ELEMENTS*2]
   );
  
  logic [MUL_OUT_BIT_LEN-1:0] mul_result[NUM_ELEMENTS*NUM_ELEMENTS]; 
  logic [COL_BIT_LEN-1:0]     grid[NUM_ELEMENTS*2][NUM_ELEMENTS*2]; 
  
  
  // Instantiate all the multipliers, requires NUM_ELEMENTS^2 muls
  genvar i, j;
  generate
    for (i=0; i<NUM_ELEMENTS; i=i+1) begin : mul_A
      for (j=0; j<NUM_ELEMENTS; j=j+1) begin : mul_B
        multiplier #(.A_BIT_LEN(A_BIT_LEN),
                     .B_BIT_LEN(B_BIT_LEN),
                     .MUL_OUT_BIT_LEN(MUL_OUT_BIT_LEN)
                     ) multiplier (
                                   .clk(clk),
                                   .A(A[i][A_BIT_LEN-1:0]),
                                   .B(B[j][B_BIT_LEN-1:0]),
                                   .P(mul_result[(NUM_ELEMENTS*i)+j])
                                   );
      end
    end
  endgenerate
  
  // Sort results into columns, split into lower and upper slices
  // Fills a parallelogram in the grid array
  // Starts with a single entry in a column, grows by two until the middle
  // Peaks in the middle two columns with (NUM_ELEMENTS * 2) - 1 entries each
  // Then declines two per column until the end with a single entry
  generate
    for (i=0; i<NUM_ELEMENTS; i=i+1) begin : grid_row
      for (j=0; j<NUM_ELEMENTS; j=j+1) begin : grid_col
        always_comb begin
          grid[(i+j)][(2*i)]     =
                   {{(MUL_OUT_BIT_LEN - (WORD_LEN*2)){1'b0}},
                    mul_result[(NUM_ELEMENTS*i)+j][WORD_LEN-1:0]};
          grid[(i+j+1)][((2*i)+1)] =
                   mul_result[(NUM_ELEMENTS*i)+j][MUL_OUT_BIT_LEN-1:WORD_LEN];
        end
      end
    end
  endgenerate
  
  // Sum each column using compressor tree
  generate
    // The first and last columns have only one entry, return in S
    always_ff @(posedge clk) begin
      Cout[0][OUT_BIT_LEN-1:0]                  <= '0;
      Cout[(NUM_ELEMENTS*2)-1][OUT_BIT_LEN-1:0] <= '0;
      
      S[0][OUT_BIT_LEN-1:0]                     <= 
            {{(OUT_BIT_LEN - COL_BIT_LEN){1'b0}},
             grid[0][0][COL_BIT_LEN-1:0]};

      S[(NUM_ELEMENTS*2)-1][OUT_BIT_LEN-1:0]    <= 
            {{(OUT_BIT_LEN - COL_BIT_LEN){1'b0}},
             grid[(NUM_ELEMENTS*2)-1][(NUM_ELEMENTS*2)-1][COL_BIT_LEN-1:0]};
    end

    // Loop through grid parallelogram
    // The number of elements increases up to the midpoint then decreases
    // Starting grid row is 0 for the first half, decreases by 2 thereafter
    // Instantiate compressor tree per column
    for (i=1; i<(NUM_ELEMENTS*2)-1; i=i+1) begin : col_sums
      localparam integer CUR_ELEMENTS = (i < NUM_ELEMENTS) ? 
                                              ((i*2)+1) :
                                              ((NUM_ELEMENTS*4) - 1 - (i*2));
      localparam integer GRID_INDEX   = (i < NUM_ELEMENTS) ? 
                                              0 :
                                              (((i - NUM_ELEMENTS) * 2) + 1);

      localparam integer CUR_TREE_HEIGHT = TREE_HEIGHTS[CUR_ELEMENTS];
      localparam integer RESULT_BIT_LEN  = COL_BIT_LEN + CUR_TREE_HEIGHT;
      
      logic [RESULT_BIT_LEN-1:0]  Cout_col;
      logic [RESULT_BIT_LEN-1:0]  S_col; 
      
      compressor_tree_3_to_2 #(.NUM_ELEMENTS(CUR_ELEMENTS),
                               .BIT_LEN(COL_BIT_LEN)
                               )
      compressor_tree_3_to_2 (
               .terms(grid[i][GRID_INDEX:(GRID_INDEX + CUR_ELEMENTS - 1)]),
               .C(Cout_col),
               .S(S_col)
         );
      
      always_ff @(posedge clk) begin
        Cout[i][OUT_BIT_LEN-1:0] <= {{(OUT_BIT_LEN - RESULT_BIT_LEN){1'b0}},
                                     Cout_col[RESULT_BIT_LEN-1:0]};
        
        S[i][OUT_BIT_LEN-1:0]    <= {{(OUT_BIT_LEN - RESULT_BIT_LEN){1'b0}},
                                     S_col[RESULT_BIT_LEN-1:0]};
      end
    end
  endgenerate
endmodule

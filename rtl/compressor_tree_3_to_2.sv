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

/*
  Tree built out of 3:2 compressors.  
  Parameterized to take any number of inputs, each of a common size
  Output is bit length number of carry and sum values.
*/

module compressor_tree_3_to_2
   #(
     parameter integer NUM_ELEMENTS      = 9,
     parameter integer BIT_LEN           = 16,
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
     parameter integer TREE_HEIGHT       = TREE_HEIGHTS[NUM_ELEMENTS],
     parameter integer RESULT_BIT_LEN    = BIT_LEN + TREE_HEIGHT
    )
   (
    input  logic [BIT_LEN-1:0]        terms[NUM_ELEMENTS],
    output logic [RESULT_BIT_LEN-1:0] C,
    output logic [RESULT_BIT_LEN-1:0] S
   );

   // If there is only one or two elements, then return the input (no tree)
   // If there are three elements, this is the last level in the tree
   // For greater than three elements:
   //   Instantiate a set of carry save adders to process this level's terms
   //   Recursive instantiate this module to complete the rest of the tree
   generate
      if (NUM_ELEMENTS == 1) begin // Return value
         always_comb begin
            C = '0;
            S = terms[0];
         end
      end
      else if (NUM_ELEMENTS == 2) begin // Return value
         always_comb begin
            C = terms[1];
            S = terms[0];
         end
      end
      else if (NUM_ELEMENTS == 3) begin // last level
         carry_save_adder #(.BIT_LEN(BIT_LEN))
            carry_save_adder (
                              .A(terms[0]),
                              .B(terms[1]),
                              .Cin(terms[2]),
                              .Cout(C[BIT_LEN:1]),
                              .S(S[BIT_LEN-1:0])
                             );

         always_comb begin
            C[0]         = 0;
            S[BIT_LEN]   = 0;
         end
      end
      else begin
         localparam integer NUM_RESULTS = ($rtoi($floor(NUM_ELEMENTS/3)) * 2) + 
                                          (NUM_ELEMENTS%3);

         logic [BIT_LEN:0] next_level_terms[NUM_RESULTS];

         carry_save_adder_tree_level #(.BIT_LEN(BIT_LEN),
                                       .NUM_ELEMENTS(NUM_ELEMENTS),
                                       .NUM_RESULTS(NUM_RESULTS)
                                      )
            carry_save_adder_tree_level (
                                         .terms(terms),
                                         .results(next_level_terms)
                                        );

         compressor_tree_3_to_2 #(.NUM_ELEMENTS(NUM_RESULTS),
                                  .BIT_LEN(BIT_LEN+1)
                                 )
            compressor_tree_3_to_2 (
                                    .terms(next_level_terms),
                                    .C(C),
                                    .S(S)
                                   );
      end
   endgenerate
endmodule

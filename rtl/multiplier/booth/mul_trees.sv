// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module mul_trees 
  #( parameter BITLEN = 17 )
  (
   input [BITLEN - 1:0]      A,
   input [BITLEN - 1:0]      B,
   output [2 * BITLEN - 1:0] C
   );
  logic [33:0] RES0;
  logic [33:0] RES1;
  logic [33:0] RES2;
  logic [33:0] RES3;
  logic [33:0] RES4;
  logic [33:0] RES5;
  logic [33:0] RES6;
  logic [33:0] RES7;
  logic [33:0] RES8;
  
  logic [33:0] RES0_new;
  logic [33:0] RES1_new;
  logic [33:0] RES2_new;
  logic [33:0] RES3_new;
  logic [33:0] RES4_new;
  logic [33:0] RES5_new;
  logic [33:0] RES6_new;
  logic [33:0] RES7_new;
  logic [33:0] RES8_new;    
  
  logic [33:0] L1S;
  logic [33:0] L1C;
  logic [33:0] L2S;
  logic [33:0] L2C;
  logic [33:0] L3S;
  logic [33:0] L3C;
  logic [33:0] L4S;
  logic [33:0] L4C;
  logic [33:0] L5S;
  logic [33:0] L5C;
  logic [33:0] L6S;
  logic [33:0] L6C;
  logic [33:0] L7S;
  logic [33:0] L7C;
  
  rombooth row0({B[ 1:0],1'b0}, {1'b0,A}, RES0);
  rombooth row1({B[ 3:1]}, {1'b0,A}, RES1);
  rombooth row2({B[ 5:3]}, {1'b0,A}, RES2);
  rombooth row3({B[ 7:5]}, {1'b0,A}, RES3);
  rombooth row4({B[ 9:7]}, {1'b0,A}, RES4);
  rombooth row5({B[11:9]}, {1'b0,A}, RES5);
  rombooth row6({B[13:11]}, {1'b0,A}, RES6);
  rombooth row7({B[15:13]}, {1'b0,A}, RES7);
  rombooth row8({1'b0,B[16:15]}, {1'b0,A}, RES8);
  
  assign RES0_new =  RES0;
  assign RES1_new = {RES1[31:0],2'b0};
  assign RES2_new = {RES2[29:0],4'b0};
  assign RES3_new = {RES3[27:0],6'b0};
  assign RES4_new = {RES4[25:0],8'b0};
  assign RES5_new = {RES5[23:0],10'b0};
  assign RES6_new = {RES6[21:0],12'b0};
  assign RES7_new = {RES7[19:0],14'b0};
  assign RES8_new = {RES8[17:0],16'b0};
  
  csa_bitlen #(.BITLEN(34)) 
    level1(L1C, L1S, RES0_new, RES1_new, RES2_new);
  csa_bitlen #(.BITLEN(34)) 
    level2(L2C, L2S, RES3_new, RES4_new, RES5_new);
  csa_bitlen #(.BITLEN(34)) 
    level3(L3C, L3S, RES6_new, RES7_new, RES8_new);
  
  csa_bitlen #(.BITLEN(34)) 
    level4(L4C, L4S, {L1C[32:0], 1'b0}, L1S, {L2C[32:0], 1'b0});
  csa_bitlen #(.BITLEN(34)) 
    level5(L5C, L5S, L2S, {L3C[32:0], 1'b0}, L3S);
  
  csa_bitlen #(.BITLEN(34)) 
    level6(L6C, L6S, {L4C[32:0], 1'b0}, L4S, {L5C[32:0], 1'b0});
  
  csa_bitlen #(.BITLEN(34)) 
    level7(L7C, L7S, L5S, {L6C[32:0], 1'b0}, L6S);
  
  assign C = L7S + {L7C[32:0], 1'b0};
endmodule

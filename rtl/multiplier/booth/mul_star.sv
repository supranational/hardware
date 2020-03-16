// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module mul_star 
  // LIMITATION: this module only works for 17 bits today.
  #( parameter BITLEN = 17 )
  (
   input logic [BITLEN - 1:0]      A,
   input logic [BITLEN - 1:0]      B,
   output logic [2 * BITLEN - 1:0] C
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
  
  rombooth row0({B[ 1:0],1'b0}, {1'b0,A}, RES0);
  rombooth row1({B[ 3:1]}, {1'b0,A}, RES1);
  rombooth row2({B[ 5:3]}, {1'b0,A}, RES2);
  rombooth row3({B[ 7:5]}, {1'b0,A}, RES3);
  rombooth row4({B[ 9:7]}, {1'b0,A}, RES4);
  rombooth row5({B[11:9]}, {1'b0,A}, RES5);
  rombooth row6({B[13:11]}, {1'b0,A}, RES6);
  rombooth row7({B[15:13]}, {1'b0,A}, RES7);
  rombooth row8({1'b0,B[16:15]}, {1'b0,A}, RES8);

  always_comb begin
    C  = '0;
    C += RES0;
    C += {RES1[31:0],2'b0};
    C += {RES2[29:0],4'b0};
    C += {RES3[27:0],6'b0};
    C += {RES4[25:0],8'b0};
    C += {RES5[23:0],10'b0};
    C += {RES6[21:0],12'b0};
    C += {RES7[19:0],14'b0};
    C += {RES8[17:0],16'b0};
  end
endmodule

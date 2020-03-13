// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*    
  A parameterized carry save adder (CSA)
  Loops through each input bit and feeds a full adder (FA)
             --------------------------------
            | CSA                            |
            |         for each i in BIT_LEN  |
            |            -------             |
            |           | FA    |            |
  A[]   --> |  Ai   --> |       | --> Si     | --> S[]
  B[]   --> |  Bi   --> |       |            |
  Cin[] --> |  Cini --> |       | --> Couti  | --> Cout[]
            |            -------             |
             --------------------------------
*/

module carry_save_adder
  #(
    parameter int BIT_LEN = 19
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   input  logic [BIT_LEN-1:0] Cin,
   output logic [BIT_LEN-1:0] Cout,
   output logic [BIT_LEN-1:0] S
   );

  genvar i;
  generate
    for (i=0; i<BIT_LEN; i++) begin : csa_fas
      full_adder full_adder(
                            .A(A[i]),
                            .B(B[i]),
                            .Cin(Cin[i]),
                            .Cout(Cout[i]),
                            .S(S[i])
                            );
    end
  endgenerate
endmodule

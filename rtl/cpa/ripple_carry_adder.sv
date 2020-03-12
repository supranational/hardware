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

module ripple_carry_adder
  #(
    parameter int BIT_LEN      = 17
    )
  (
   input  logic [BIT_LEN-1:0] A,
   input  logic [BIT_LEN-1:0] B,
   output logic [BIT_LEN:0]   S
   );
  
  logic [BIT_LEN:0]   carry;
  
  always_comb begin
    carry[0]   = 1'b0;
    S[BIT_LEN] = carry[BIT_LEN];
  end
  
   genvar i;
  generate
    for (i=0; i<BIT_LEN; i=i+1) begin : full_adders
      full_adder full_adder (
                             .A(A[i]),
                             .B(B[i]),
                             .Cin(carry[i]),
                             .Cout(carry[i+1]),
                             .S(S[i])
                             );
    end
  endgenerate
endmodule


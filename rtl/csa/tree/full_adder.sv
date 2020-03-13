// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
  A basic 1-bit full adder
              -------
             | FA    |
    A    --> |       | --> S
    B    --> |       |
    Cin  --> |       | --> Cout
              -------
*/

module full_adder
  (
   input  logic A,
   input  logic B,
   input  logic Cin,
   output logic Cout,
   output logic S
   );

  always_comb begin
    S    =  A ^ B ^ Cin;
    Cout = (A & B) | (Cin & (A ^ B));
  end
endmodule

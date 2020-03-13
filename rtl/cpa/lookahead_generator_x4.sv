// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module lookahead_generator_x4
  (
   input  logic [3:0] p,
   input  logic [3:0] g,
   input  logic       cin,
   output logic [2:0] cout,
   output logic       p_group,
   output logic       g_group
   );
  
  always_comb begin
    p_group = &p;
    
    g_group = g[3]                        | 
              (g[2] & p[3])               | 
              (g[1] & p[2] & p[3])        | 
              (g[0] & p[1] & p[2] & p[3]);
    
    cout[0] = g[0] | (cin & p[0]);
    
    cout[1] = g[1]                        | 
              (g[0] & p[1])               | 
              (cin  & p[0] & p[1]);
    
    cout[2] = g[2]                        | 
              (g[1] & p[2])               |  
              (g[0] & p[1] & p[2])        | 
              (cin  & p[0] & p[1] & p[2]);
  end
endmodule

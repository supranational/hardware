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

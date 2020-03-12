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

module white_processor
  #(
    parameter int BIT_LEN      = 17
    )
  (
   input  logic [BIT_LEN-1:0] g_in,
   input  logic [BIT_LEN-1:0] p_in,
   output logic [BIT_LEN-1:0] g_out,
   output logic [BIT_LEN-1:0] p_out
   );
    
  always_comb begin
    g_out = g_in;
    p_out = p_in;
  end
endmodule

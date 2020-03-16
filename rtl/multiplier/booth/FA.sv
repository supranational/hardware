// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module FA
  (
   output C,
   output S,
   input  X,
   input  Y,
   input  Z
   );
  
  assign {C, S} = X + Y + Z;
endmodule

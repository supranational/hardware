// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modular Squaring Unit
// Input Montgomery value a_mont = (a * R) % m
// Output modular square (a^2 * R) % m
//
// Cycle 0
//   /---------- TotalWordBits ---------\
//   |----------------------------------|
//   |             sq_nr_i              |
//   |----------------------------------|
//   |----------------------------------|
//   |             sq_r_i               |
//   |----------------------------------|
//
//                    |
//                   \ /
//
//                Flop inputs
//                          __________________________
// Cycle 1            |    |                          |
//                   \ /  \ /                         |
//                ______________                      |
//   start -----> \____________/                      |
//                                                    |
//                       |                            |
//                      \ /                           |
//                                                    |
//             Flop multiplier inputs                 |
//                                                    |
// Cycle 2            |                               |
//                   \ /                              |
//                                                    |
//   |----------------------------------|             |
//   |              sq_nr_o             |             |
//   |----------------------------------|             |
//   |----------------------------------|             |
//   |              sq_r_o              |             |
//   |----------------------------------|             |
//                                                    |
//  output <----------|                               |
//                   \ /                              |
//                                                    |
//       |--------------------------|                 |
//       |        Multiplier        |                 |
//       |--------------------------|                 |
//                                                    |
//                    |                               |
//                   \ /                              |
//                                                    |
//             Flop multiplier outputs                |
//                                                    |
// Cycle 3            |                               |
//                   \ /                              |
//                                                    |
//   /--------- MulPartialBits ---------\             |
//   |----------------------------------|             |
//   |            part_nr_q             |             |
//   |----------------------------------|             |
//   |----------------------------------|             |
//   |            part_r_q              |             |
//   |----------------------------------|             |
//                                                    |
//                    |                               |
//                   \ /                              |
//                                                    |
//       |--------------------------|                 |
//       |         Reducer          |                 |
//       |--------------------------|                 |
//                                                    |
//                    |                               |
//                   \ /                              |
//                                                    |
//   /---------- TotalWordBits ---------\             |
//   |----------------------------------|             |
//   |              red_nr              |             |
//   |----------------------------------|             |
//   |----------------------------------|             |
//   |              red_r               |             |
//   |----------------------------------|             |
//                                                    |
//                    |                               |
//                   \ /                              |
//                    --------------------------------|
//
//                   __    __    __    __    __    __    __    __
//  clk_i         __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
//                   _____
//  start_i       __|     |______________________________________
//                                                       _____
//  stop_i        ______________________________________|     |__
//                         _____
//  valid_q       ________|     |________________________________
//                               _____
//  valid_q1      ______________|     |__________________________
//                                     _____       _____
//  valid_q2      ____________________|     |_____|     |________
//                                           _____       _____
//  valid_o       __________________________|     |_____|     |__
//                   _____
//  sq_xr_i       --X_____X--------------------------------------
//                         _____
//  sq_in_xr_q    --------X_____X--------------------------------
//                               _____       _____       _____
//  sq_xr_o       --------------X_____X-----X_____X-----X_____X--
//
//    Go through multiplier
//                               _____       _____       _____
//  part_xr_d     --------------X_____X-----X_____X-----X_____X--
//                                     _____       _____       __
//  part_xr_q     --------------------X_____X-----X_____X-----X__
//
//    Go through reducer
//                                     _____       _____       __
//  red_xr        --------------------X_____X-----X_____X-----X__
//
//  TODO - figure out clock gating strategy

module msu (
  input  logic                                    clk_i,
  input  logic                                    rst_ni,
  input  logic                                    start_i,
  input  logic                                    stop_i,
  input  logic [(msu_pkg::TotalWordBits - 1):0]   sq_nr_i,
  input  logic [(msu_pkg::TotalWordBits - 1):0]   sq_r_i,
  output logic [(msu_pkg::TotalWordBits - 1):0]   sq_nr_o,
  output logic [(msu_pkg::TotalWordBits - 1):0]   sq_r_o,
  output logic                                    valid_o
);

  // Set this parameter if flopping middle of triangle out of squarer
  localparam int FlopSqPartsMidValues = 1;

  // Flop start input signal and pipeline for output valid signal
  logic                                    valid_q;
  logic                                    valid_q1;
  logic                                    valid_q2;

  // Flop sq inputs
  logic [(msu_pkg::TotalWordBits - 1):0]   sq_in_nr_d;
  logic [(msu_pkg::TotalWordBits - 1):0]   sq_in_r_d;
  logic [(msu_pkg::TotalWordBits - 1):0]   sq_in_nr_q;
  logic [(msu_pkg::TotalWordBits - 1):0]   sq_in_r_q;

  // Values out of squarer
  logic [(msu_pkg::LowerTriBits  - 1):0]  sq_parts_lower_nr_d;
  logic [msu_pkg::LowerTriBits:0]         sq_parts_lower_r_d;
  logic [(msu_pkg::TargetBits    - 1):0]  sq_parts_mid_nr_d;
  logic [msu_pkg::TargetBits:0]           sq_parts_mid_r_d;
  logic [(msu_pkg::UpperTriBits  - 2):0]  sq_parts_upper_nr_d;
  logic [(msu_pkg::UpperTriBits  - 1):0]  sq_parts_upper_r_d;

  // Flop values out of squarer
  logic [(msu_pkg::LowerTriBits  - 1):0]  sq_parts_lower_nr_q;
  logic [msu_pkg::LowerTriBits:0]         sq_parts_lower_r_q;
  logic [(msu_pkg::TargetBits    - 1):0]  sq_parts_mid_nr_q;
  logic [msu_pkg::TargetBits:0]           sq_parts_mid_r_q;
  logic [(msu_pkg::UpperTriBits  - 2):0]  sq_parts_upper_nr_q;
  logic [(msu_pkg::UpperTriBits  - 1):0]  sq_parts_upper_r_q;

  // Middle of triangle inputs to reducer
  logic [(msu_pkg::TargetBits    - 1):0]  sq_parts_mid_nr_to_red;
  logic [msu_pkg::TargetBits:0]           sq_parts_mid_r_to_red;

  // Values out of reducer
  logic [(msu_pkg::TotalWordBits - 1):0]   red_nr;
  logic [(msu_pkg::TotalWordBits - 1):0]   red_r;

  // To flop sq outputs
  logic [(msu_pkg::TotalWordBits - 1):0]   sq_out_nr_d;
  logic [(msu_pkg::TotalWordBits - 1):0]   sq_out_r_d;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_q   <= 1'b0;
      valid_q1  <= 1'b0;
      valid_q2  <= 1'b0;
      valid_o   <= 1'b0;
    end else begin
      valid_q   <= start_i;
      valid_q1  <= valid_q;
      valid_q2  <= (valid_q1 | valid_o) & ~stop_i;
      valid_o   <= valid_q2;
    end
  end

  always_comb begin
    sq_in_nr_d  = start_i ? sq_nr_i : sq_in_nr_q;
    sq_in_r_d   = start_i ? sq_r_i  : sq_in_r_q;

    sq_out_nr_d = valid_q  ? sq_in_nr_q : 
                  valid_q2 ? red_nr     : sq_nr_o;
    sq_out_r_d  = valid_q  ? sq_in_r_q  : 
                  valid_q2 ? red_r      : sq_r_o;

    if (FlopSqPartsMidValues == 1) begin
      sq_parts_mid_nr_to_red = sq_parts_mid_nr_q;
      sq_parts_mid_r_to_red  = sq_parts_mid_r_q;
    end else begin
      sq_parts_mid_nr_to_red = sq_parts_mid_nr_d;
      sq_parts_mid_r_to_red  = sq_parts_mid_r_d;
    end
  end

  always_ff @(posedge clk_i) begin
    sq_in_nr_q           <= sq_in_nr_d;
    sq_in_r_q            <= sq_in_r_d;

    sq_nr_o              <= sq_out_nr_d;
    sq_r_o               <= sq_out_r_d;

    sq_parts_lower_nr_q  <= sq_parts_lower_nr_d;
    sq_parts_lower_r_q   <= sq_parts_lower_r_d;
    sq_parts_upper_nr_q  <= sq_parts_upper_nr_d;
    sq_parts_upper_r_q   <= sq_parts_upper_r_d;

    if (FlopSqPartsMidValues == 1) begin
      sq_parts_mid_nr_q  <= sq_parts_mid_nr_d;
      sq_parts_mid_r_q   <= sq_parts_mid_r_d;
    end
  end

  squarer i_squarer (
    .clk_i(clk_i),
    .nr_i(sq_nr_o),
    .r_i(sq_r_o),
    .sq_parts_lower_nr_o(sq_parts_lower_nr_d),
    .sq_parts_lower_r_o(sq_parts_lower_r_d),
    .sq_parts_mid_nr_o(sq_parts_mid_nr_d),
    .sq_parts_mid_r_o(sq_parts_mid_r_d),
    .sq_parts_upper_nr_o(sq_parts_upper_nr_d),
    .sq_parts_upper_r_o(sq_parts_upper_r_d)
  );

  reducer i_reducer (
    .clk_i(clk_i),
    .sq_parts_lower_nr_i(sq_parts_lower_nr_q),
    .sq_parts_lower_r_i(sq_parts_lower_r_q),
    .sq_parts_mid_nr_i(sq_parts_mid_nr_to_red),
    .sq_parts_mid_r_i(sq_parts_mid_r_to_red),
    .sq_parts_upper_nr_i(sq_parts_upper_nr_q),
    .sq_parts_upper_r_i(sq_parts_upper_r_q),
    .nr_o(red_nr),
    .r_o(red_r)
  );

endmodule

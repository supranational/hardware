// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Reduce the inputs to closer to modulus width bits
// Meant to be close to a % n

module reducer (
  input  logic                                     clk_i,
  input  logic [(msu_pkg::LowerTriBits  - 1):0]    sq_parts_lower_nr_i,
  input  logic [msu_pkg::LowerTriBits:0]           sq_parts_lower_r_i,
  input  logic [(msu_pkg::TargetBits    - 1):0]    sq_parts_mid_nr_i,
  input  logic [msu_pkg::TargetBits:0]             sq_parts_mid_r_i,
  input  logic [(msu_pkg::UpperTriBits  - 2):0]    sq_parts_upper_nr_i,
  input  logic [(msu_pkg::UpperTriBits  - 1):0]    sq_parts_upper_r_i,
  output logic [(msu_pkg::TotalWordBits - 1):0]    nr_o,
  output logic [(msu_pkg::TotalWordBits - 1):0]    r_o
);

  // Set this parameter if using the module for adder trees
  localparam int UseSumTermsModules = 0;

  logic [msu_pkg::TargetBits:0]         grid_row_col[msu_pkg::RedGridRows];

  logic [(msu_pkg::RedSumBits - 1):0]   red_sums[msu_pkg::WordElements];

  logic [(msu_pkg::FullWordBits - 1):0] red_parts[msu_pkg::NumElements];

  always_comb begin

    //////////////////////
    //  Reduction Grid  //
    //////////////////////

    for (int i = 0; i < msu_pkg::RedGridRows; i++) begin
      grid_row_col[i] =  '0;
    end

    // Use montgomery reduction table to reduce lower bits
    for (int i = 0; i < msu_pkg::LowerTriBits; i++) begin
      grid_row_col[i] = {{1'b0}, msu_pkg::MontRedTable[i] & 
        {msu_pkg::TargetBits{sq_parts_lower_nr_i[i]}}};
    end

    // Redundant bits are only a single bit starting with second element
    for (int i = 1; i < msu_pkg::OuterTriTrees; i++) begin
      grid_row_col[((i - 1) + msu_pkg::LowerTriBits)] = {{1'b0},
        msu_pkg::MontRedTable[(i * msu_pkg::WordBits)] & 
        {msu_pkg::TargetBits{sq_parts_lower_r_i[(i * msu_pkg::WordBits)]}}};
    end

    // Middle bits are passed directly into result
    grid_row_col[((msu_pkg::LowerTriBits + msu_pkg::OuterTriTrees) - 1)] = 
      {{1'b0}, sq_parts_mid_nr_i[(msu_pkg::TargetBits - 1):0]};
    grid_row_col[(msu_pkg::LowerTriBits + msu_pkg::OuterTriTrees)] = 
      sq_parts_mid_r_i[msu_pkg::TargetBits:0];

    // Use pre-calculated reduction table to reduce upper bits
    for (int i = 0; i < (msu_pkg::UpperTriBits - 1); i++) begin
      grid_row_col[(msu_pkg::LowerTriBits + msu_pkg::OuterTriTrees + 1 + i)] = 
        {{1'b0}, msu_pkg::UpperRedTable[i] &
         {msu_pkg::TargetBits{sq_parts_upper_nr_i[i]}}};
    end

    for (int i = 1; i < (msu_pkg::OuterTriTrees + 1); i++) begin
      grid_row_col[(msu_pkg::LowerTriBits + msu_pkg::OuterTriTrees + 
                   msu_pkg::UpperTriBits + (i - 1))] = 
        {{1'b0}, msu_pkg::UpperRedTable[(i * msu_pkg::WordBits)] &
         {msu_pkg::TargetBits{sq_parts_upper_r_i[(i * msu_pkg::WordBits)]}}};
    end


    /////////////////////////////
    //  Reduction Adder Trees  //
    /////////////////////////////

    if (UseSumTermsModules == 0) begin : set_terms
      // Sum grid columns in tree bit sized chunks
      // Limits the carry propagation chain to tree bits 
      for (int i = 0; i < msu_pkg::WordElements; i++) begin
        red_sums[i] = '0;
        for (int j = 0; j < msu_pkg::RedGridRows; j++) begin
          red_sums[i] +=
            grid_row_col[j]
              [(i * msu_pkg::TreeBits) +:msu_pkg::TreeBits];
        end
      end
    end

    ///////////////////////////////////////////////
    //  Partially reduce reduction tree results  //
    ///////////////////////////////////////////////

    // Partially reduce sums
    red_parts[0] = {{1'b0}, red_sums[0][(msu_pkg::WordBits - 1):0]};

    for (int i = 1; i < msu_pkg::WordElements; i++) begin
      red_parts[i] =
        {{(msu_pkg::FullWordBits -
          (msu_pkg::RedSumBits - msu_pkg::WordBits)){1'b0}},
         red_sums[(i - 1)][(msu_pkg::RedSumBits - 1):msu_pkg::WordBits]} +
        {{1'b0}, red_sums[i][(msu_pkg::WordBits - 1):0]};
    end

    // Last element also needs to add the most significant redundant bit
    //   from the middle triangle result which did not fit in the adder tree
    red_parts[msu_pkg::WordElements] =
      {{(msu_pkg::FullWordBits -
         (msu_pkg::RedSumBits - msu_pkg::WordBits)){1'b0}},
       red_sums[(msu_pkg::WordElements - 1)]
               [(msu_pkg::RedSumBits - 1):msu_pkg::WordBits]}    + 
      {{(msu_pkg::WordBits){1'b0}}, 
       grid_row_col[(msu_pkg::LowerTriBits + msu_pkg::OuterTriTrees)]
                   [msu_pkg::TargetBits]};

    ///////////////////////////////////////////
    //  Vectorize partially reduced results  //
    ///////////////////////////////////////////

    nr_o = '0;
    r_o  = '0;
    for (int i = 0; i < msu_pkg::NumElements; i++) begin
      nr_o[(i * msu_pkg::WordBits) +:msu_pkg::WordBits] =
        red_parts[i][(msu_pkg::WordBits - 1):0];
      r_o[((i + 1) * msu_pkg::WordBits)
            +:(msu_pkg::FullWordBits - msu_pkg::WordBits)] =
        red_parts[i][(msu_pkg::FullWordBits - 1):msu_pkg::WordBits];
    end
  end

  /////////////////////////////////////
  //  Sum Terms Modules (if enabled) //
  /////////////////////////////////////
  if (UseSumTermsModules == 1) begin : sum_terms_gen
    
    for (genvar ii = 0; ii < msu_pkg::WordElements; 
         ii++) begin : sum_terms_col_gen
      logic [msu_pkg::TreeBits-1:0] terms[msu_pkg::RedGridRows];

      always_comb begin
        for (int jj = 0; jj < msu_pkg::RedGridRows; jj++) begin
          terms[jj] = grid_row_col[jj][(ii * msu_pkg::TreeBits) 
                      +:msu_pkg::TreeBits];
        end
      end

      red_sum_terms i_red_sum_terms (
        .clk_i(clk_i),
        .terms_i(terms),
        .sum_o(red_sums[ii])
      );
    end
  end
endmodule

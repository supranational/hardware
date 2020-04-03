// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Square the input (a^2)
// Input is a non-redundant vector plus redundant vector
// Output is a non-redundant vector and a redundant vector
// The output is split into three (lower, middle, and upper portions)
// This represents the square adder tree triangle broken down into parts
// The lower and upper portions are small equal parts on the outside that
//  are meant to go fast into reduction tree
// The middle portion has the largest adder trees and is slower then the outside

module squarer (
  input  logic                                   clk_i,
  input  logic [(msu_pkg::TotalWordBits - 1):0]  nr_i,
  input  logic [(msu_pkg::TotalWordBits - 1):0]  r_i,
  output logic [(msu_pkg::LowerTriBits  - 1):0]  sq_parts_lower_nr_o,
  output logic [msu_pkg::LowerTriBits:0]         sq_parts_lower_r_o,
  output logic [(msu_pkg::TargetBits    - 1):0]  sq_parts_mid_nr_o,
  output logic [msu_pkg::TargetBits:0]           sq_parts_mid_r_o,
  output logic [(msu_pkg::UpperTriBits  - 2):0]  sq_parts_upper_nr_o,
  output logic [(msu_pkg::UpperTriBits  - 1):0]  sq_parts_upper_r_o
);

  // Set this parameter if using the module for adder trees
  localparam int UseSumTermsModules = 0;

  // Grid containing square partial products
  logic [(msu_pkg::SqGridCols - 1):0]    grid_row_col[msu_pkg::SqGridRows];

  // Adder tree results
  logic [(msu_pkg::SqSumBits - 1):0]     sq_sums_lower[msu_pkg::OuterTriTrees];
  logic [(msu_pkg::SqSumBits - 1):0]     sq_sums_upper[msu_pkg::OuterTriTrees];
  logic [(msu_pkg::SqSumBits - 1):0]     sq_sums_mid[msu_pkg::WordElements];

  // Partially reduced adder tree results
  logic [(msu_pkg::FullWordBits - 1):0]  sq_parts_lower[msu_pkg::OuterTriTrees];
  logic [(msu_pkg::FullWordBits - 1):0]  sq_parts_upper[msu_pkg::OuterTriTrees];
  logic [(msu_pkg::FullWordBits - 1):0]  sq_parts_mid[msu_pkg::WordElements];


  always_comb begin

    ////////////////////
    //  Squarer Grid  //
    ////////////////////

    for (int i = 0; i < msu_pkg::SqGridRows; i++) begin
      grid_row_col[i] =  '0;
    end

    // Multiply each bit in r by all other bits - lower half
    for (int i = 0; i < msu_pkg::NumElements/2; i++) begin
      // r_i * nr_i * 2
      grid_row_col[2*i]
        [(((i + 1) * msu_pkg::WordBits) + 1) +:msu_pkg::TotalWordBits] =
        ({msu_pkg::TotalWordBits{r_i[((i + 1) * msu_pkg::WordBits)]}} & 
         nr_i);

      // r_i * r_i
      grid_row_col[2*i + 1]
        [((i + 1) * msu_pkg::WordBits) +:msu_pkg::TotalWordBits] =
        ({msu_pkg::TotalWordBits{r_i[((i + 1) * msu_pkg::WordBits)]}} & r_i);
    end

    // Square a * a
    // Multiply each bit in nr by all other nr bits
    for (int i = 0; i < msu_pkg::TotalWordBits; i++) begin
      // nr_i * nr_i
      grid_row_col[i + msu_pkg::NumElements][i +:msu_pkg::TotalWordBits] =
      //grid_row_col[i][i +:msu_pkg::TotalWordBits] =
        ({msu_pkg::TotalWordBits{nr_i[i]}} & nr_i);
    end

    // Multiply each bit in r by all other bits - upper half
    for (int i = msu_pkg::NumElements/2; i < (msu_pkg::NumElements - 1); 
         i++) begin
    //for (int i = 0; i < (msu_pkg::NumElements - 1); i++) begin
      // r_i * nr_i * 2
      grid_row_col[2*i + msu_pkg::TotalWordBits]
      //grid_row_col[i + msu_pkg::TotalWordBits]
        [(((i + 1) * msu_pkg::WordBits) + 1) +:msu_pkg::TotalWordBits] =
        ({msu_pkg::TotalWordBits{r_i[((i + 1) * msu_pkg::WordBits)]}} & 
         nr_i);

      // r_i * r_i
      grid_row_col[2*i + msu_pkg::TotalWordBits + 1]
      //grid_row_col[i + msu_pkg::TotalWordBits + (msu_pkg::NumElements - 1)]
        [((i + 1) * msu_pkg::WordBits) +:msu_pkg::TotalWordBits] =
        ({msu_pkg::TotalWordBits{r_i[((i + 1) * msu_pkg::WordBits)]}} & r_i);
    end

    ///////////////////////////
    //  Squarer Adder Trees  //
    ///////////////////////////

    if (UseSumTermsModules == 0) begin : set_terms
      // Sum grid columns in tree bit sized chunks
      // Split the grid into three portions | upper |    middle    | lower |
      // Limits the carry propagation chain to tree bits 

      // Feed the lower and upper portions of the grid triangle to adder trees
      for (int i = 0; i < msu_pkg::OuterTriTrees; i++) begin
        sq_sums_lower[i] = '0;
        for (int j = 0; j <= msu_pkg::SqGridRows/2 + msu_pkg::NumElements/2; 
             j++) begin
          sq_sums_lower[i] += grid_row_col[j]
            [(i * msu_pkg::TreeBits) +:msu_pkg::TreeBits];
        end

        sq_sums_upper[i] = '0;
        for (int j = msu_pkg::SqGridRows/2; j < msu_pkg::SqGridRows; j++) begin
          sq_sums_upper[i] += grid_row_col[j]
            [((i + msu_pkg::OuterTriTrees + msu_pkg::WordElements) 
              * msu_pkg::TreeBits) +:msu_pkg::TreeBits];
        end
      end
  
      // Feed the middle portion of the grid triangle to adder trees
      for (int i = 0; i < msu_pkg::WordElements; i++) begin
        sq_sums_mid[i] = '0;
        for (int j = 0; j < msu_pkg::SqGridRows; j++) begin
          sq_sums_mid[i] += grid_row_col[j]
            [((i + msu_pkg::OuterTriTrees) * msu_pkg::TreeBits) 
              +:msu_pkg::TreeBits];
        end
      end
    end

    ///////////////////////////////////////////
    //  Partially reduce adder tree results  //
    ///////////////////////////////////////////

    // First result in section consumes upper portion of adjacent
    sq_parts_lower[0] = {{1'b0}, sq_sums_lower[0][(msu_pkg::WordBits - 1):0]};
    sq_parts_upper[0] = 
      {{(msu_pkg::FullWordBits - 
         (msu_pkg::SqSumBits - msu_pkg::WordBits)){1'b0}},
       sq_sums_mid[(msu_pkg::WordElements - 1)]
                  [(msu_pkg::SqSumBits - 1):msu_pkg::WordBits]} +
      {{1'b0}, sq_sums_upper[0][(msu_pkg::WordBits - 1):0]};

    // Reduce rest of trees
    // Note very last tree in upper will not be greater than WordBits
    for (int i = 1; i < msu_pkg::OuterTriTrees; i++) begin
      sq_parts_lower[i] = 
        {{(msu_pkg::FullWordBits - 
           (msu_pkg::SqSumBits - msu_pkg::WordBits)){1'b0}},
         sq_sums_lower[(i - 1)][(msu_pkg::SqSumBits - 1):msu_pkg::WordBits]} +
        {{1'b0}, sq_sums_lower[i][(msu_pkg::WordBits - 1):0]};
      sq_parts_upper[i] = 
        {{(msu_pkg::FullWordBits - 
           (msu_pkg::SqSumBits - msu_pkg::WordBits)){1'b0}},
         sq_sums_upper[(i - 1)][(msu_pkg::SqSumBits - 1):msu_pkg::WordBits]} +
        {{1'b0}, sq_sums_upper[i][(msu_pkg::WordBits - 1):0]};
    end

    // First result in section consumes upper portion of adjacent
    // After partially reducing the lower triangle
    //  need to take the redundant bit into middle triangle since weight is in
    //  unreduced target range
    sq_parts_mid[0] = 
      {{(msu_pkg::FullWordBits - 
         (msu_pkg::SqSumBits - msu_pkg::WordBits)){1'b0}},
       sq_sums_lower[(msu_pkg::OuterTriTrees - 1)]
                    [(msu_pkg::SqSumBits - 1):msu_pkg::WordBits]}       +
      {{(msu_pkg::WordBits){1'b0}},
       sq_parts_lower[(msu_pkg::OuterTriTrees - 1)][msu_pkg::WordBits]} + 
      {{1'b0}, sq_sums_mid[0][(msu_pkg::WordBits - 1):0]};

    // Now that the redundant bit of the last element in the lower triangle
    //   has been added to the middle portion, it can be reset to 0
    sq_parts_lower[(msu_pkg::OuterTriTrees - 1)][msu_pkg::WordBits] = 1'b0;

    for (int i = 1; i < msu_pkg::WordElements; i++) begin
      sq_parts_mid[i] = 
        {{(msu_pkg::FullWordBits - 
           (msu_pkg::SqSumBits - msu_pkg::WordBits)){1'b0}},
         sq_sums_mid[(i - 1)][(msu_pkg::SqSumBits - 1):msu_pkg::WordBits]} +
        {{1'b0}, sq_sums_mid[i][(msu_pkg::WordBits - 1):0]};
    end

    //////////////////////////////////////////
    //  Vectorize partially reduced results //
    //////////////////////////////////////////

    sq_parts_lower_nr_o = '0;
    sq_parts_lower_r_o  = '0;
    sq_parts_mid_nr_o   = '0;
    sq_parts_mid_r_o    = '0;
    sq_parts_upper_nr_o = '0;
    sq_parts_upper_r_o  = '0;

    for (int i = 0; i < msu_pkg::OuterTriTrees; i++) begin
      sq_parts_lower_nr_o[(i * msu_pkg::WordBits) +:msu_pkg::WordBits] =
        sq_parts_lower[i][(msu_pkg::WordBits - 1):0];

      sq_parts_lower_r_o[((i + 1) * msu_pkg::WordBits)
                         +:(msu_pkg::FullWordBits - msu_pkg::WordBits)] =
        sq_parts_lower[i][(msu_pkg::FullWordBits - 1):msu_pkg::WordBits];

      sq_parts_upper_nr_o[(i * msu_pkg::WordBits) +:msu_pkg::WordBits] =
        sq_parts_upper[i][(msu_pkg::WordBits - 1):0];

      sq_parts_upper_r_o[((i + 1) * msu_pkg::WordBits)
                         +:(msu_pkg::FullWordBits - msu_pkg::WordBits)] =
        sq_parts_upper[i][(msu_pkg::FullWordBits - 1):msu_pkg::WordBits];
    end

    for (int i = 0; i < msu_pkg::WordElements; i++) begin
      sq_parts_mid_nr_o[(i * msu_pkg::WordBits) +:msu_pkg::WordBits] =
        sq_parts_mid[i][(msu_pkg::WordBits - 1):0];

      sq_parts_mid_r_o[((i + 1) * msu_pkg::WordBits)
                         +:(msu_pkg::FullWordBits - msu_pkg::WordBits)] =
        sq_parts_mid[i][(msu_pkg::FullWordBits - 1):msu_pkg::WordBits];
    end
  end

  /////////////////////////////////////
  //  Sum Terms Modules (if enabled) //
  /////////////////////////////////////
  if (UseSumTermsModules == 1) begin : sum_terms_gen

    for (genvar ii = 0; ii < msu_pkg::OuterTriTrees; 
         ii++) begin : sum_terms_col_gen_lower
      logic [msu_pkg::TreeBits-1:0] terms[msu_pkg::SqGridRowsLower];

      always_comb begin
        for (int jj = msu_pkg::SqGridRowsMinLower; 
             jj <= msu_pkg::SqGridRowsMaxLower; jj++) begin
          terms[jj-msu_pkg::SqGridRowsMinLower] = 
                 grid_row_col[jj][(ii * msu_pkg::TreeBits) +:msu_pkg::TreeBits];
        end
      end
      
      sq_sum_terms_lower i_sq_sum_terms_lower (
        .clk_i(clk_i),
        .terms_i(terms),
        .sum_o(sq_sums_lower[ii])
      );
    end

    for (genvar ii = 0; ii < msu_pkg::OuterTriTrees; 
         ii++) begin : sum_terms_col_gen_upper
      logic [msu_pkg::TreeBits-1:0] terms[msu_pkg::SqGridRowsUpper];

      always_comb begin
        for (int jj = msu_pkg::SqGridRowsMinUpper; 
             jj <= msu_pkg::SqGridRowsMaxUpper; jj++) begin
          terms[jj-msu_pkg::SqGridRowsMinUpper] = grid_row_col[jj]
               [((ii + msu_pkg::OuterTriTrees + msu_pkg::WordElements) * 
                 msu_pkg::TreeBits) 
                +:msu_pkg::TreeBits];
        end
      end
      
      sq_sum_terms_upper i_sq_sum_terms_upper (
        .clk_i(clk_i),
        .terms_i(terms),
        .sum_o(sq_sums_upper[ii])
      );
    end

    for (genvar ii = 0; ii < msu_pkg::WordElements; ii++) begin
      logic [msu_pkg::TreeBits-1:0] terms[msu_pkg::SqGridRows];

      always_comb begin
        for (int jj = 0; jj < msu_pkg::SqGridRows; jj++) begin
          terms[jj] = grid_row_col[jj][((ii + msu_pkg::OuterTriTrees) * 
                                        msu_pkg::TreeBits) 
                +:msu_pkg::TreeBits];
        end
      end
      
      sq_sum_terms_mid i_sq_sum_terms_mid (
        .clk_i(clk_i),
        .terms_i(terms),
        .sum_o(sq_sums_mid[ii])
      );
    end
  end
endmodule

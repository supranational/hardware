// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modular squaring unit global parameters

package msu_pkg;
  /////////////////////////////
  // Configurable parameters //
  /////////////////////////////
  parameter int WordBits       = 16;
  parameter int WordElements   = 16;

  //////////////////////
  // Fixed parameters //
  //////////////////////
  parameter int WordBitsMask      = (2**WordBits) - 1;
  parameter int TargetBits        = WordElements * WordBits;
  parameter int TargetBitsMask    = (2**TargetBits) - 1;
  parameter int NumElements       = WordElements + 1;    // 1 redundant element
  parameter int FullWordBits      = WordBits + 1;        // 1 redundant bit
  parameter int FullWordBitsMask  = (2**FullWordBits) - 1;
  parameter int TotalWordBits     = NumElements * WordBits;
  parameter int TotalBits         = NumElements * FullWordBits;
  parameter int SqGridRows        = TotalWordBits + ((NumElements - 1) * 2);
  parameter int SqGridRowsMinLower= 0;
  parameter int SqGridRowsMaxLower= (msu_pkg::SqGridRows/2 + 
                                     msu_pkg::NumElements/2);
  parameter int SqGridRowsLower   = (msu_pkg::SqGridRowsMaxLower - 
                                     msu_pkg::SqGridRowsMinLower + 1);
  parameter int SqGridRowsMinUpper= msu_pkg::SqGridRows/2;
  parameter int SqGridRowsMaxUpper= msu_pkg::SqGridRows - 1;
  parameter int SqGridRowsUpper   = (msu_pkg::SqGridRowsMaxUpper - 
                                     msu_pkg::SqGridRowsMinUpper + 1);
  // Only need - 1 columns in square grid, make whole though for ease of trees
  //parameter int SqGridCols        = (TotalWordBits * 2) - 1;
  parameter int SqGridCols        = TotalWordBits * 2;
  parameter int TreeBits          = WordBits;
  parameter int TreeBitsMask      = (2**TreeBits) - 1;
  parameter int OuterTriTrees     = NumElements - (WordElements / 2);
  parameter int LowerTriBits      = OuterTriTrees * WordBits;
  parameter int LowTriBitsMask    = (2**LowerTriBits) - 1;
  parameter int UpperTriBits      = (OuterTriTrees * WordBits) + 1;
  parameter int SqSumBits         = $clog2(SqGridRows) + TreeBits;

  // Reduction grid rows:
  //   Lower triangle non-redundant bitwise montgomery
  //   Lower triangle redundant bitwise montgomery
  //   Middle triangle non-redundant and redundant bits intact
  //   Upper triangle non-redundant bitwise pre-calc
  //   Upper triangle redundant bitwise pre-calc
  parameter int RedGridRows       = 
    LowerTriBits + (OuterTriTrees - 1) + 2 + (UpperTriBits - 1) + OuterTriTrees;

  // Extra bit for redundant in middle triangle after partial reduction
  // Everything else in grid should be TargetBits wide
  parameter int RedGridCols       = TargetBits + 1;
  parameter int RedSumBits        = $clog2(RedGridRows) + TreeBits;

  // R = b^n
  parameter [LowerTriBits:0]     BtoTheN = {{1'b1}, {LowerTriBits{1'b0}}};

  /////////////
  // Modulus // 
  /////////////
  // TODO - Set Modulus
  parameter [(TargetBits - 1):0] Modulus = (TargetBits == 2048) ?
    2048'h85776e9add84f39e71545a137a1d50068d723104f77383c13458a748e9bb17bca3f2c9bf9c6316b950f244556f25e2a25a92118719c78df48f4ff31e78de58575487ce1eaf19922ad9b8a714e61a441c12e0c8b2bad640fb19488dec4f65d4d9259f4329e6f4590b9a164106cf6a659eb4862b21fb97d43588561712e8e5216afcbd04c340212ef7cca5a5a19e4d6e3c1846d424c17c627923c6612f4826867323a7711a8133287637ebdcd9e87a1613e443df789558867f5ba91faf7a024204f7c1bd874da5e709d4713d60c8a70639eb1167b367a9c3787c65c1e582e2e662f728b4fa42485e3a0a5d2f346baa9455e3e70682c2094cac629f6fbed82c07cd :
    (TargetBits == 1024) ? 1024'hc05748bbfb5acd7e5a77dc03d9ec7d8bb957c1b95d9b206090d83fd1b67433ce83ead7376ccfd612c72901f4ce0a2e07e322d438ea4f34647555d62d04140e1084e999bb4cd5f947a76674009e2318549fd102c5f7596edc332a0ddee3a355186b9a046f0f96a279c1448a9151549dc663da8a6e89cf8f511baed6450da2c1cb :
    (TargetBits == 512) ? 512'h7be8ced99bbeac8439335ed9c885a0b82f2851964372c283ff0cfc017f422012451d377de8915ce63270acfefd6b6cdf1616d2fd662733d2b5ffe0a4f20f64c1 :
    (TargetBits == 256) ? 256'h4903d72a9ea2fb2795496eb04ee87dde57113bd8a8192f26db4e763141802c27 : 
    (TargetBits == 32) ? 32'hd82c07cd : 
    (TargetBits == 40) ? 40'h62d82c07cd : 
    (TargetBits == 64) ? 64'h629f6fbed82c07cd: {TargetBits{1'b0}};


  ////////////////////////////////////
  // Modular multiplicative inverse //
  ////////////////////////////////////

  // Input a, m
  // Output z where az = 1 mod m
  function automatic [(TargetBits-1):0] mod_inverse(
    input [(TargetBits-1):0] a_i,
    input [(TargetBits-1):0] m_i
  );
    logic [((TargetBits * 2) - 1):0] z;
    logic [((TargetBits * 2) - 1):0] next_z;
    logic [((TargetBits * 2) - 1):0] tmp_z;
    logic [((TargetBits * 2) - 1):0] x;
    logic [((TargetBits * 2) - 1):0] next_x;
    logic [((TargetBits * 2) - 1):0] tmp_x;
    logic [((TargetBits * 2) - 1):0] q;

    z         = '0;
    next_z    = '0;
    next_z[0] = 1'b1;
    x         = {{TargetBits{1'b0}}, m_i};
    next_x    = {{TargetBits{1'b0}}, a_i};

    while (next_x != '0) begin
      q      = x / next_x;

      tmp_z  = next_z;
      next_z = z - q * next_z;
      z      = tmp_z;

      tmp_x  = next_x;
      next_x = x - q * next_x;
      x      = tmp_x;
    end

    // Check if z < 0
    if (z[((TargetBits * 2) - 1)] == 1'b1) begin
      z += m_i;
    end

    return z[(TargetBits-1):0];
  endfunction

  parameter [(LowerTriBits-1):0] Mu = BtoTheN - 
    mod_inverse(Modulus, {{((TargetBits - LowerTriBits) - 1){1'b0}}, BtoTheN});

  parameter [(TargetBits-1):0] RInv = 
    mod_inverse({{((TargetBits - LowerTriBits) - 1){1'b0}}, BtoTheN}, Modulus);

  ////////////////////////////////
  // Montgomery reduction table //
  ////////////////////////////////
  typedef logic [(TargetBits - 1):0] mont_red_table_t[LowerTriBits];

  function automatic mont_red_table_t mont_reduction_table();
    mont_red_table_t ret_table;

    for (int i = 0; i < LowerTriBits; i++) begin
      logic [(TargetBits * 2):0]    tmp;
      logic [(LowerTriBits - 1):0]  T1;
      logic [(LowerTriBits - 1):0]  T2;
      logic [(TargetBits * 2):0]    T3;
      logic [(TargetBits - 1):0]    T4;

      T1    = '0;
      T1[i] = 1'b1;
      tmp   = T1 * Mu;
      T2    = tmp[(LowerTriBits - 1):0];
      T3    = T2 * Modulus;
      tmp   = ((T3 >> LowerTriBits) + 1);
      T4    = tmp[(TargetBits - 1):0];

      ret_table[i] = T4;
    end

    return ret_table;
  endfunction

  parameter mont_red_table_t MontRedTable = mont_reduction_table();


  ////////////////////////////////////
  // Pre-calculated reduction table //
  ////////////////////////////////////
  typedef logic [(TargetBits - 1):0] upper_red_table_t[UpperTriBits];

  function automatic upper_red_table_t upper_reduction_table();
    upper_red_table_t ret_table;

    for (int i = 0; i < UpperTriBits; i++) begin
      logic [((UpperTriBits + TargetBits) - 1):0]  cur_weight;
      cur_weight = '0;
      cur_weight[(i + TargetBits)] = 1'b1;
      ret_table[i] = cur_weight % Modulus;
    end
    
    return ret_table;
  endfunction

  parameter upper_red_table_t UpperRedTable = upper_reduction_table();

endpackage

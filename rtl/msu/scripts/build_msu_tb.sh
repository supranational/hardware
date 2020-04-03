#!/bin/bash
# Copyright Supranational LLC
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

mkdir -p sim

echo ""
echo "****** Compliling MSU TB"
echo ""
vcs -full64 -sverilog \
   rtl/msu_pkg.sv \
   rtl/sq_sum_terms.sv \
   rtl/sq_sum_terms_mid.sv \
   rtl/sq_sum_terms_lower.sv \
   rtl/sq_sum_terms_upper.sv \
   rtl/red_sum_terms.sv \
   rtl/squarer.sv \
   rtl/reducer.sv \
   rtl/msu.sv \
   tb/msu_tb.sv \
   -o sim/msu_tb


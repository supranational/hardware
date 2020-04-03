#!/bin/bash
# Copyright Supranational LLC
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

echo ""
echo "****** Cleaning work area"
echo ""
echo "rm -Rf sim/*"
rm -Rf sim
echo "rm -Rf csrc"
rm -Rf csrc
echo "rm -f ucli.key"
rm -f ucli.key
rm -f trace.vcd


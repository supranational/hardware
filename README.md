# Open Source Hardware Designs

This repository contains open source hardware written in verilog RTL that can be used for FPGA or ASIC based designs. 

Much of this work comes out of the https://www.vdfalliance.org/ studies focused on building a low latency Modular Squaring Unit (MSU) design for use as a verifiable delay function evaluator. Watch for our upcoming blog series on Medium (https://medium.com/@supranational) describing the optimization of these primitives and and the construction of a low latency squaring design.

## Contents

Within the rtl directory you can find the following primitives and designs:

**cpa (carry propagate adder)**

Various adder implementations (ripple carry, carry lookahead, brent kung, kogge stone). Makes use of white, black, and gray cells as described in http://www.cs.um.edu.mt/gordon.pace/Teaching/FunctionalHDLs/prefix.pdf and elsewhere. 

**csa (carry save adder)**

Contains two approaches to compression trees which produce the sum of N inputs. 
- tree - This design uses an explicit tree of compressor cells to produce a redundant carry and sum output
- rtl/csa/sum_terms.v - Uses a series of "+" operations to produce a single sum output. While not expressed as a carry save design in some cases it may get implemented that way by the synthesis tool

**multiplier**

Contains two multiplier designs:
- schoolbook_mul.sv - A fully parameterized polynomial multiplier with configurable polynomial degree and coefficient bit-width
- booth - A booth encoded multiplier. Limited to 17 bits currently

**msu**

Contains a full Modular Squaring Unit (MSU) implementation of the Ozturk approach targeted toward an ASIC. It applies lessons from the primitive studies to optimize each of the components for the lowest latency outcome. 

The design is fully paramaterized in many dimensions, including word size and overall bitwidth. By default it is configured as a 16 element polynomial with 16 bit elements for a total of 256 bits but these settings can be changed in rtl/msu_pkg.sv.

To build and run a simulation:
```
./scripts/build_msu_tb.sh
./scripts/run_msu_tb.sh
```

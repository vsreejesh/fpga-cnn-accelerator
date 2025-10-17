# RTL Source Files

This folder contains the Register Transfer Level (RTL) Verilog source code implementing a hardware accelerator for a Convolutional Neural Network (CNN) targeting FPGA platforms.

## Overview

The RTL code implements a simple CNN inference pipeline for 28×28 grayscale images, designed with resource efficiency and clarity. Key modules include:

- **control_fsm.v**: FSM controller orchestrating data flow and operation sequencing.
- **processing_unit.v**: Multiply-Accumulate (MAC) unit performing convolution operations using 3×3 kernels and signed fixed-width integers.
- **max_pooling_unit.v**: Max pooling module performing 2×2 downsampling on feature maps to reduce spatial resolution.
- **dense_layer.v**: Fully connected dense layer performing classification using accumulated features from the pooled map.
- **cnn_top.v / cnnn_top.v**: Top-level module integrating sub-modules and managing input/output signals.
## Design Details

- The design uses sequential FSM control without deep pipelining.
- Convolution operations are performed serially over sliding windows.
- Max pooling and dense layers activate only after prior stages complete processing.

## How to Use

- The RTL files can be simulated using the provided testbench.
- The design can be synthesized for FPGA deployment.
- Users can customize convolution kernels and dense layer weights by modifying the initialization files or registers.


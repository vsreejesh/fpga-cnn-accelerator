# Testbench Files

This folder contains the Verilog testbenches used to verify the functionality of the CNN hardware accelerator RTL design.

## Overview

- The testbenches instantiate the top-level CNN module and provide stimulus for simulation.
- They load sample input images (28×28 pixels) and kernel weights.
- The testbenches generate necessary clock and reset signals.
- They monitor the CNN output prediction and `done` signals to validate correct inference.
- Console messages display classification results for easy interpretation.

## Usage

- Run simulations using your preferred Verilog simulator (e.g., ModelSim, Vivado).
- Testbench files are designed to be self-contained for straightforward testing.
- Modify input datasets or add new tests for extended verification.

## Included Files

- `cat_or_dog.v`: Main testbench for binary classification CNN, includes image loading and output checking.
- Additional helper files or scripts may be included for simulation automation.

---change the path of the image.hex file as per the testbench

This testbench ensures the correctness of the CNN accelerator design before deployment on FPGA hardware. Use it to validate changes, test new image inputs, or benchmark performance.


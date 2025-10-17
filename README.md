# FPGA CNN Accelerator

## Project Overview

This repository features an FPGA-based Convolutional Neural Network (CNN) accelerator designed for efficient inference on 28×28 grayscale images. It implements key CNN operations such as 3×3 convolution, max pooling, and fully connected dense layers in Verilog HDL. The design uses sequential FSM control and fixed-point signed integer arithmetic to perform multiply-accumulate (MAC) operations.

## Repository Structure

- **rtl/**: Verilog source files implementing the CNN layers and FSM control.
- **testbench/**: Testbench files for simulation, including image inputs and stimulus generation.
- **docs/**: Documentation files including project report PDF and simulation waveform images.
- **scripts/**: Python scripts for training models, and converting between image and hex formats.
- **data/**: Hex files containing input images and trained weights used in simulation and hardware.

## Features

- Sequential FSM-based pipeline controlling convolution, pooling, and classification.
- Fixed-width signed integer arithmetic for hardware efficiency.
- Simulation testbench verifying functionality with sample image inputs.
- Modular RTL design facilitating customization and extension.

## How to Use

1. Run simulations using the testbench with provided data.
2. Modify or retrain CNN weights using Python scripts.
3. Synthesize and deploy the RTL on an FPGA board.
4. Consult documentation for detailed design and performance insights.

## Contribution

Contributions improving performance, pipelining, or adding features are welcome. Please provide test results and follow coding conventions.




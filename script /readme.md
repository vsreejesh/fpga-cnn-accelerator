# Scripts

This folder contains Python scripts used for data preparation, model training, and conversion utilities essential to the FPGA CNN accelerator workflow.

## Included Scripts

- **train_model.py**  
  Script for training the convolutional neural network model. It handles dataset loading, model configuration, training loops, and saving trained weights. This forms the basis for generating weights used in FPGA inference.

- **image_to_hex.py**  
  Utility to convert grayscale image files (e.g., PNG, JPG) into hex format (.hex), suitable for FPGA memory initialization. Helps transform input images into a format readable by the FPGA testbench and hardware.

- **hex_to_image.py**  
  Utility to convert FPGA memory hex dumps back into image format. Useful for verification and visualization of intermediate or output feature maps during simulation or hardware testing.

## Usage

- Use `train_model.py` to develop or retrain CNN models; output weight files can be integrated into the FPGA design.
- Use `image_to_hex.py` to prepare input samples for FPGA testbenches or hardware runs.
- Use `hex_to_image.py` for debugging and analyzing intermediate data by converting back to viewable images.

---

These scripts automate crucial parts of the design flow bridging software model development and FPGA hardware implementation.


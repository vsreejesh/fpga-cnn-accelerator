# Data Files

This folder contains input images, kernel weights, and dense layer weights in hex format used for simulation and FPGA inference with the CNN hardware accelerator.

## Contents

- **Input Images (hex files):**  
  - `cat.hex`, `dog.hex`, `dog1.hex`  
  Hexadecimal representation of 28×28 grayscale images. These files are used as inputs for simulation testbenches to verify image classification.
change path for this file in cat_or_dog.v (testbench)

- **Kernel Weights:**  
  - `kernel.hex`  
  Hexadecimal file containing the 3×3 convolution kernel weights applied during the convolution stage.
change path for this file in cnn_top.v

- **Dense Layer Weights:**  
  - `dense_weights_c0.hex`, `dense_weights_c1.hex`  
  Hex files containing weights for the fully connected dense layer corresponding to class 0 and class 1, used for classification decisions.
 chnage path for this file in dense_layer.v
## Usage

- These files initialize memories during simulation or FPGA implementation.
- Input hex files represent image pixel values packed for easy loading into FPGA BRAM or distributed memory.
- Weight hex files are used to configure the neural network parameters in the hardware accelerator.
- Users can replace these files with new hex-encoded images or weights to test different inputs or retrained models.

---

This data folder bridges software model training and FPGA hardware testing by providing appropriately formatted data for the accelerator pipeline.


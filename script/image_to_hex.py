from PIL import Image
import numpy as np
from skimage.transform import resize
from skimage.color import rgb2gray

# ==============================================================================
# --- Configuration ---
# 1. The name of your input image file (e.g., a .png or .jpg)
IMAGE_FILE_TO_CONVERT = "dogg.jpg" 

# 2. The name of the output hex file for the Verilog simulation
OUTPUT_HEX_FILE = "dog.hex"
# ==============================================================================

def convert_image_to_hex(image_path, output_path):
    """Opens, preprocesses, and converts an image file to the Verilog hex format."""
    try:
        # Open the image
        img = Image.open(image_path)
    except FileNotFoundError:
        print(f"Error: The file '{image_path}' was not found.")
        print("Please make sure your image file is in the same directory as this script.")
        return

    # Convert to numpy array of floats
    img_array = np.array(img, dtype=float)

    # If the image has an alpha channel, remove it
    if img_array.shape[-1] == 4:
        img_array = img_array[..., :3]

    # Convert to grayscale if it's a color image
    if len(img_array.shape) == 3:
        grayscale_img = rgb2gray(img_array)
    else:
        grayscale_img = img_array / 255.0 # Ensure it's normalized if already grayscale

    # Resize to 28x28
    resized_img = resize(grayscale_img, (28, 28), anti_aliasing=True)

    # Scale to 8-bit integers (0-255)
    processed_img_int = np.round(resized_img * 255).astype(np.uint8)

    # Flatten the 2D image into a 1D array
    flattened_img = processed_img_int.flatten()

    # Write the hex values to the output file
    with open(output_path, 'w') as f:
        f.write(f"// 28x28 Grayscale Image Data for {image_path}\n")
        for pixel_val in flattened_img:
            f.write(f"{format(pixel_val, '02x')}\n")
    
    print(f"Successfully converted '{image_path}' to '{output_path}'.")
    print(f"Your Verilog simulation will now use this image.")

if __name__ == '__main__':
    # Create a dummy image if the target image doesn't exist, to make the script runnable
    try:
        Image.open(IMAGE_FILE_TO_CONVERT)
    except FileNotFoundError:
        print(f"NOTE: '{IMAGE_FILE_TO_CONVERT}' not found. Creating a dummy 32x32 PNG image for demonstration.")
        print("Replace 'my_image.png' with your own image file.")
        dummy_array = np.zeros((32, 32, 3), dtype=np.uint8)
        dummy_array[8:24, 8:24, :] = [255, 0, 255] # Magenta square
        dummy_image = Image.fromarray(dummy_array)
        dummy_image.save(IMAGE_FILE_TO_CONVERT)

    convert_image_to_hex(IMAGE_FILE_TO_CONVERT, OUTPUT_HEX_FILE)

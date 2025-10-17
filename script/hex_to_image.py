from PIL import Image
import numpy as np

# ==============================================================================
# --- Configuration ---
# 1. The name of the hex file you want to convert back to an image
INPUT_HEX_FILE = "dog.hex"

# 2. The name of the output image file that will be created
OUTPUT_IMAGE_FILE = "dog_reconstructed_image.png"

# 3. The dimensions of the image
IMAGE_WIDTH = 28
IMAGE_HEIGHT = 28
# ==============================================================================

def convert_hex_to_image(hex_path, image_path, width, height):
    """Reads a Verilog-style hex file and converts it into a grayscale image."""
    pixel_values = []
    try:
        with open(hex_path, 'r') as f:
            for line in f:
                # Ignore comments and empty lines
                line = line.strip()
                if not line or line.startswith('//'):
                    continue
                
                # Convert hex value to integer
                try:
                    pixel_val = int(line, 16)
                    pixel_values.append(pixel_val)
                except ValueError:
                    print(f"Warning: Skipping invalid hex value '{line}' in {hex_path}")
                    continue
    except FileNotFoundError:
        print(f"Error: The file '{hex_path}' was not found.")
        return

    print(f"Read {len(pixel_values)} pixel values from {hex_path}.")

    # Check if we have the correct number of pixels
    expected_pixels = width * height
    if len(pixel_values) != expected_pixels:
        print(f"Error: Expected {expected_pixels} pixels for a {width}x{height} image, but found {len(pixel_values)}.")
        return

    # Convert the list to a NumPy array and reshape it
    image_array = np.array(pixel_values, dtype=np.uint8).reshape((height, width))

    # Create an image from the array and save it
    img = Image.fromarray(image_array, 'L') # 'L' mode is for grayscale
    img.save(image_path)

    print(f"Successfully reconstructed image and saved it as '{image_path}'.")

if __name__ == '__main__':
    convert_hex_to_image(INPUT_HEX_FILE, OUTPUT_IMAGE_FILE, IMAGE_WIDTH, IMAGE_HEIGHT)

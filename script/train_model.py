import numpy as np
import tensorflow as tf
from tensorflow.keras.datasets import cifar10
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense
from skimage.transform import resize
from skimage.color import rgb2gray

# ==============================================================================
# --- CHOOSE YOUR CLASSES ---
# Select any two classes from the list below to train the model on.
#
# CIFAR-10 classes: 
# 0: airplane
# 1: automobile
# 2: bird
# 3: cat
# 4: deer
# 5: dog
# 6: frog
# 7: horse
# 8: ship
# 9: truck
# ==============================================================================
CLASS_A = 3  # e.g., cat
CLASS_B = 5  # e.g., dog
# ==============================================================================

def export_weights_to_hex(model, conv_kernel_file, dense_w0_file, dense_w1_file, dense_b_file):
    """Extracts, formats, and saves the trained weights and biases to hex files."""
    print("\n--- Exporting Weights for Verilog ---")

    # --- Convolution Layer ---
    conv_layer = model.layers[0]
    conv_weights, conv_biases = conv_layer.get_weights()
    # NOTE: Your hardware doesn't seem to use a conv bias, so we ignore conv_biases[0]

    # Scale kernel weights to 8-bit signed integers (-128 to 127)
    # Find the absolute max value to scale by
    max_val = np.max(np.abs(conv_weights))
    scaling_factor = 127.0 / max_val
    
    kernel_int = np.round(conv_weights * scaling_factor).astype(int).flatten()

    with open(conv_kernel_file, 'w') as f:
        f.write("// 3x3 Convolution Kernel (8-bit signed hex)\n")
        for w in kernel_int:
            # Format as two's complement hex
            hex_val = format(w & 0xFF, '02x')
            f.write(f"{hex_val}\n")
    print(f"Successfully saved convolution kernel to {conv_kernel_file}")

    # --- Dense Layer ---
    dense_layer = model.layers[3]
    dense_weights, dense_biases = dense_layer.get_weights()

    # Scale dense weights to 8-bit signed integers
    max_val_dense = np.max(np.abs(dense_weights))
    scaling_factor_dense = 127.0 / max_val_dense
    dense_weights_int = np.round(dense_weights * scaling_factor_dense).astype(int)

    # Scale dense biases to 16-bit signed integers
    # In a real scenario, biases might need their own scaling. For simplicity, we use a large range.
    dense_biases_int = np.round(dense_biases * 100).astype(int) # Simple scaling for demo

    # Class 0 weights and bias
    weights_c0 = dense_weights_int[:, 0]
    bias_c0 = dense_biases_int[0]
    with open(dense_w0_file, 'w') as f:
        f.write("// Dense Layer Weights for Class 0 (8-bit signed hex)\n")
        for w in weights_c0:
            f.write(f"{format(w & 0xFF, '02x')}\n")
    print(f"Successfully saved Class 0 dense weights to {dense_w0_file}")

    # Class 1 weights and bias
    weights_c1 = dense_weights_int[:, 1]
    bias_c1 = dense_biases_int[1]
    with open(dense_w1_file, 'w') as f:
        f.write("// Dense Layer Weights for Class 1 (8-bit signed hex)\n")
        for w in weights_c1:
            f.write(f"{format(w & 0xFF, '02x')}\n")
    print(f"Successfully saved Class 1 dense weights to {dense_w1_file}")

    # Save biases
    with open(dense_b_file, 'w') as f:
        f.write("// Dense Layer Biases (16-bit signed hex)\n")
        f.write(f"// Class 0 Bias:\n{format(bias_c0 & 0xFFFF, '04x')}\n")
        f.write(f"// Class 1 Bias:\n{format(bias_c1 & 0xFFFF, '04x')}\n")
    print(f"Successfully saved dense biases to {dense_b_file}")
    print("\nNOTE: Your dense_layer.v currently has hardcoded biases.")
    print("You will need to manually update them with the values from dense_biases.hex")


def preprocess_data(x, y, class_a, class_b):
    """Filters for two classes and preprocesses images to match hardware."""
    # Filter for instances of the two classes
    indices = np.where((y == class_a) | (y == class_b))[0]
    x_filtered, y_filtered = x[indices], y[indices]

    # Convert labels to 0 and 1
    y_filtered = np.where(y_filtered == class_a, 0, 1)

    # Preprocess images: RGB -> Grayscale -> Resize 28x28 -> Normalize
    print(f"Preprocessing {len(x_filtered)} images...")
    x_processed = np.array([resize(rgb2gray(img), (28, 28), anti_aliasing=True) for img in x_filtered])
    
    # Reshape for the model (add channel dimension)
    x_processed = x_processed.reshape(x_processed.shape + (1,))
    
    return x_processed, y_filtered


def main():
    # 1. Load CIFAR-10 data
    (x_train, y_train), (x_test, y_test) = cifar10.load_data()
    y_train, y_test = y_train.flatten(), y_test.flatten()

    # 2. Preprocess data using the globally selected classes
    print(f"\nTraining model on Class {CLASS_A} vs Class {CLASS_B}...")
    x_train_processed, y_train_processed = preprocess_data(x_train, y_train, CLASS_A, CLASS_B)
    x_test_processed, y_test_processed = preprocess_data(x_test, y_test, CLASS_A, CLASS_B)

    # 3. Define the Keras model to match the Verilog architecture
    model = Sequential([
        Conv2D(1, (3, 3), activation='relu', input_shape=(28, 28, 1)), # 28x28 -> 26x26
        MaxPooling2D((2, 2)),                                         # 26x26 -> 13x13
        Flatten(),                                                    # 13x13 = 169 features
        Dense(2, activation='softmax')                                # 169 features -> 2 classes
    ])
    model.summary()

    # 4. Compile and train the model
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    model.fit(x_train_processed, y_train_processed, epochs=10, validation_data=(x_test_processed, y_test_processed))

    # 5. Evaluate the model
    loss, accuracy = model.evaluate(x_test_processed, y_test_processed)
    print(f"\nFinal Test Accuracy: {accuracy*100:.2f}%")

    # 6. Export the trained weights into hex files for Verilog
    export_weights_to_hex(
        model,
        conv_kernel_file="kernel.hex",
        dense_w0_file="dense_weights_c0.hex",
        dense_w1_file="dense_weights_c1.hex",
        dense_b_file="dense_biases.hex"
    )

if __name__ == '__main__':
    main()
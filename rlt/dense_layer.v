`timescale 1ns / 1ps

module dense_layer(
    input clk,
    input reset,
    input start,
    input signed [15:0] feature_in, // Sequential input of 169 features

    output reg done,
    output reg signed [31:0] class_0_score, // Widened to prevent overflow
    output reg signed [31:0] class_1_score  // Widened to prevent overflow
);

    // --- Parameters ---
    localparam INPUT_VECTOR_SIZE = 169; // 13x13 flattened feature map

    // --- FSM State Definitions ---
    parameter S_IDLE    = 3'b000;
    parameter S_COMPUTE = 3'b001;
    parameter S_ADD_BIAS= 3'b010;
    parameter S_DONE    = 3'b011;

    reg [2:0] state;

    // --- Internal memories and registers ---
    reg [7:0] feature_count;
    reg signed [31:0] acc_c0, acc_c1; // Widened accumulators

    // --- Weights and Biases ---
    // In a real design, these would be in a ROM or loaded from memory.
    reg signed [7:0] weights_c0 [0:INPUT_VECTOR_SIZE-1];
    reg signed [7:0] weights_c1 [0:INPUT_VECTOR_SIZE-1];
    reg signed [15:0] bias_c0   = 16'sd50;
    reg signed [15:0] bias_c1   = 16'sd100;
    
    initial begin
        // Load weights from external files
        $readmemh("D:/cnn_samples/sample/data/dense_weights_c0.hex", weights_c0);
        $readmemh("D:/cnn_samples/sample/data/dense_weights_c1.hex", weights_c1);
    end

    // --- Sequential Logic ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            done <= 1'b0;
            feature_count <= 0;
            acc_c0 <= 0;
            acc_c1 <= 0;
            class_0_score <= 0;
            class_1_score <= 0;
        end 
        else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        acc_c0 <= 0;
                        acc_c1 <= 0;
                        feature_count <= 0;
                        state <= S_COMPUTE;
                        done <= 1'b0; // De-assert done only when starting
                    end
                end

                S_COMPUTE: begin
                    // Multiply-accumulate for each incoming feature
                    acc_c0 <= acc_c0 + (feature_in * weights_c0[feature_count]);
                    acc_c1 <= acc_c1 + (feature_in * weights_c1[feature_count]);

                    if (feature_count == INPUT_VECTOR_SIZE - 1) begin
                        state <= S_ADD_BIAS;
                    end else begin
                        feature_count <= feature_count + 1;
                    end
                end

                S_ADD_BIAS: begin
                    // Add bias after all features are accumulated
                    // acc registers now hold the final dot product from the last S_COMPUTE cycle
                    class_0_score <= acc_c0 + bias_c0;
                    class_1_score <= acc_c1 + bias_c1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    done <= 1'b1;    // Assert done to signal completion
                    state <= S_IDLE; // Go back to IDLE, done will remain high
                end
                
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule

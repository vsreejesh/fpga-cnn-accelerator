/*`timescale 1ns / 1ps

module cnn_top(
    input clk,
    input reset,
    input start,
    output reg prediction, // Final output: 0 or 1
    output reg done
);

    // --- Master FSM State Definitions ---
    parameter IDLE        = 4'b0000;
    parameter CONV_START  = 4'b0001;
    parameter CONV_WAIT   = 4'b0010;
    parameter POOL_START  = 4'b0011;
    parameter POOL_WAIT   = 4'b0100; // Wait for autonomous pooling to finish
    parameter DENSE_START = 4'b0101;
    parameter DENSE_FEED  = 4'b0110; // New state to feed dense layer
    parameter DENSE_WAIT  = 4'b0111;
    parameter PREDICT     = 4'b1000;
    parameter DONE_STATE  = 4'b1001;

    reg [3:0] state;

    // --- Wires and Regs for connecting modules ---

    // Convolution signals
    wire conv_fsm_done, latch_conv_result;
    reg start_conv_fsm;
    wire [9:0] image_addr;
    wire [3:0] kernel_addr;
    wire signed [15:0] conv_result_pu;
    wire start_pu, done_pu;
    reg [9:0] conv_pixel_counter;
    reg signed [15:0] feature_map [0:675]; // 26x26 = 676 elements

    // Pooling signals
    reg start_pooling;
    wire pool_done;
    wire [9:0] pool_in_addr; // Pooling unit provides address
    wire [7:0] out_map_addr;
    wire signed [15:0] pool_max_val_out;
    wire pool_write_en;
    reg signed [15:0] pooled_map [0:168]; // 13x13 = 169 elements

    // Dense layer signals
    reg start_dense;
    wire dense_done;
    reg signed [15:0] dense_feature_in;
    reg [7:0] dense_pixel_counter;
    wire signed [31:0] class_0_score, class_1_score; // WIDENED

    // --- Data storage ---
    reg [7:0] image_reg [0:783];  // 28x28 input image
    reg signed [7:0] kernel_reg [0:8];
    integer i;

    // --- Instantiate Convolution FSM ---
    control_fsm CONV_FSM (
        .clk(clk), .reset(reset), .start(start_conv_fsm), .done_pu(done_pu),
        .pixel_addr_out(image_addr), .weight_addr_out(kernel_addr),
        .start_pu(start_pu), .latch_result(latch_conv_result), .final_done(conv_fsm_done)
    );

    // --- Instantiate Convolution Processing Unit ---
    processing_unit CONV_PU (
        .clk(clk), .reset(reset), .start_pu(start_pu),
        .pixel_in(image_reg[image_addr]), .weight_in(kernel_reg[kernel_addr]),
        .result_out(conv_result_pu), .done_pu(done_pu)
    );

    // --- Instantiate Max Pooling Layer ---
    max_pooling_layer_26x26 POOL_UNIT (
        .clk(clk), .reset(reset), .start(start_pooling),
        .in_map_addr(pool_in_addr),
        .in_map_pixel(feature_map[pool_in_addr]), // Provide pixel based on address
        .out_map_addr(out_map_addr),
        .out_map_pixel(pool_max_val_out),
        .out_map_write_en(pool_write_en),
        .done(pool_done)
    );

    // --- Instantiate Dense Layer ---
    dense_layer DENSE_LAYER (
        .clk(clk), .reset(reset), .start(start_dense),
        .feature_in(dense_feature_in), // Feed from dedicated register
        .done(dense_done),
        .class_0_score(class_0_score),
        .class_1_score(class_1_score)
    );

    // --- Master FSM (Sequential) ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            prediction <= 0;
            conv_pixel_counter <= 0;
            dense_pixel_counter <= 0;
            start_conv_fsm <= 0;
            start_pooling <= 0;
            start_dense <= 0;
            dense_feature_in <= 0;
        end else begin
            // Default assignments for one-cycle start pulses
            start_conv_fsm <= 0;
            start_pooling  <= 0;
            start_dense    <= 0;

            case(state)
                IDLE: begin
                    if (start) begin
                        state <= CONV_START;
                        done <= 0; // De-assert done when starting
                    end
                end

                CONV_START: begin
                    start_conv_fsm <= 1;
                    state <= CONV_WAIT;
                end

                CONV_WAIT: begin
                    if (conv_fsm_done) begin
                        state <= POOL_START;
                    end
                end

                POOL_START: begin
                    start_pooling <= 1;
                    state <= POOL_WAIT;
                end

                POOL_WAIT: begin
                    if (pool_done) begin
                        state <= DENSE_START;
                    end
                end

                DENSE_START: begin
                    start_dense <= 1;
                    dense_pixel_counter <= 1; // Set up counter for the next element
                    dense_feature_in <= pooled_map[0]; // Pre-load the first feature for the pipeline
                    state <= DENSE_FEED;
                end

                DENSE_FEED: begin
                    // Feed the next feature based on the counter
                    dense_feature_in <= pooled_map[dense_pixel_counter];

                    if (dense_pixel_counter == 168) begin
                        state <= DENSE_WAIT; // Finished feeding
                    end else begin
                        dense_pixel_counter <= dense_pixel_counter + 1;
                    end
                end

                DENSE_WAIT: begin
                    if (dense_done) begin
                        state <= PREDICT;
                    end
                end

                PREDICT: begin
                    prediction <= (class_0_score > class_1_score) ? 0 : 1;
                    state <= DONE_STATE;
                end

                DONE_STATE: begin
                    done <= 1;
                    state <= IDLE; // Unconditionally transition to IDLE
                end
            endcase

            // --- Data Handling Logic ---

            // Latch convolution result with ReLU
            if (latch_conv_result) begin
                feature_map[conv_pixel_counter] <= conv_result_pu[15] ? 0 : conv_result_pu;
                conv_pixel_counter <= conv_pixel_counter + 1;
            end

            // Store result from autonomous pooling layer
            if (pool_write_en) begin
                pooled_map[out_map_addr] <= pool_max_val_out;
            end
        end
    end

    // --- Data Initialization from files ---
    initial begin
        $readmemh("D:/cnn_samples/sample/data/image.hex", image_reg);
        $readmemh("D:/cnn_samples/sample/data/kernel.hex", kernel_reg);
    end

endmodule
*/

`timescale 1ns / 1ps

module cnn_top(
    input clk,
    input reset,
    input start,
    // CHANGED: Port is now a single packed vector (8 bits * 784 pixels = 6272 bits)
    input [6271:0] image_data_in_packed,
    output reg prediction, 
    output reg done
);

    // --- FSM Definitions ---
    parameter IDLE        = 4'b0000;
    parameter CONV_START  = 4'b0001;
    parameter CONV_WAIT   = 4'b0010;
    parameter POOL_START  = 4'b0011;
    parameter POOL_WAIT   = 4'b0100;
    parameter DENSE_START = 4'b0101;
    parameter DENSE_FEED  = 4'b0110;
    parameter DENSE_WAIT  = 4'b0111;
    parameter PREDICT     = 4'b1000;
    parameter DONE_STATE  = 4'b1001;

    reg [3:0] state;

    // --- Internal Unpacked Image Memory ---
    // This memory is loaded from the packed input port.
    reg [7:0] image_reg [0:783];

    // --- Wires and Regs ---
    wire conv_fsm_done, latch_conv_result, start_pu, done_pu;
    reg start_conv_fsm, start_pooling, start_dense;
    wire [9:0] image_addr; 
    wire [3:0] kernel_addr;
    wire signed [15:0] conv_result_pu;
    reg [9:0] conv_pixel_counter;
    reg signed [15:0] feature_map [0:675];

    wire pool_done;
    wire [9:0] pool_in_addr;
    wire [7:0] out_map_addr;
    wire signed [15:0] pool_max_val_out;
    wire pool_write_en;
    reg signed [15:0] pooled_map [0:168];

    wire dense_done;
    reg signed [15:0] dense_feature_in;
    reg [7:0] dense_pixel_counter;
    wire signed [31:0] class_0_score, class_1_score;

    reg signed [7:0] kernel_reg [0:8];
    integer i; // for unpacking loop

    // --- Combinational logic to unpack the input vector into a 2D-addressable memory ---
    always @(*) begin
        for (i = 0; i < 784; i = i + 1) begin
            image_reg[i] = image_data_in_packed[i*8 +: 8];
        end
    end

    // --- Instantiations ---
    control_fsm CONV_FSM (
        .clk(clk), .reset(reset), .start(start_conv_fsm), .done_pu(done_pu),
        .pixel_addr_out(image_addr), .weight_addr_out(kernel_addr),
        .start_pu(start_pu), .latch_result(latch_conv_result), .final_done(conv_fsm_done)
    );

    processing_unit CONV_PU (
        .clk(clk), .reset(reset), .start_pu(start_pu),
        .pixel_in(image_reg[image_addr]), // Reads from the internal unpacked memory
        .weight_in(kernel_reg[kernel_addr]),
        .result_out(conv_result_pu), .done_pu(done_pu)
    );

    max_pooling_layer_26x26 POOL_UNIT (
        .clk(clk), .reset(reset), .start(start_pooling),
        .in_map_addr(pool_in_addr),
        .in_map_pixel(feature_map[pool_in_addr]),
        .out_map_addr(out_map_addr),
        .out_map_pixel(pool_max_val_out),
        .out_map_write_en(pool_write_en),
        .done(pool_done)
    );

    dense_layer DENSE_LAYER (
        .clk(clk), .reset(reset), .start(start_dense),
        .feature_in(dense_feature_in),
        .done(dense_done),
        .class_0_score(class_0_score),
        .class_1_score(class_1_score)
    );

    // --- Master FSM ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            prediction <= 0;
            conv_pixel_counter <= 0;
            dense_pixel_counter <= 0;
            start_conv_fsm <= 0;
            start_pooling <= 0;
            start_dense <= 0;
            dense_feature_in <= 0;
        end else begin
            start_conv_fsm <= 0;
            start_pooling  <= 0;
            start_dense    <= 0;

            case(state)
                IDLE: begin
                    if (start) begin
                        state <= CONV_START;
                        done <= 0;
                    end
                end
                CONV_START: begin
                    start_conv_fsm <= 1;
                    state <= CONV_WAIT;
                end
                CONV_WAIT: begin
                    if (conv_fsm_done) state <= POOL_START;
                end
                POOL_START: begin
                    start_pooling <= 1;
                    state <= POOL_WAIT;
                end
                POOL_WAIT: begin
                    if (pool_done) state <= DENSE_START;
                end
                DENSE_START: begin
                    start_dense <= 1;
                    dense_pixel_counter <= 1;
                    dense_feature_in <= pooled_map[0];
                    state <= DENSE_FEED;
                end
                DENSE_FEED: begin
                    dense_feature_in <= pooled_map[dense_pixel_counter];
                    if (dense_pixel_counter == 168) begin
                        state <= DENSE_WAIT;
                    end else begin
                        dense_pixel_counter <= dense_pixel_counter + 1;
                    end
                end
                DENSE_WAIT: begin
                    if (dense_done) state <= PREDICT;
                end
                PREDICT: begin
                    prediction <= (class_0_score > class_1_score) ? 0 : 1;
                    state <= DONE_STATE;
                end
                DONE_STATE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase

            if (latch_conv_result) begin
                feature_map[conv_pixel_counter] <= conv_result_pu[15] ? 0 : conv_result_pu;
                conv_pixel_counter <= conv_pixel_counter + 1;
            end

            if (pool_write_en) begin
                pooled_map[out_map_addr] <= pool_max_val_out;
            end
        end
    end

    // --- Data Initialization ---
    initial begin
        $readmemh("D:/cnn_samples/sample/data/kernel.hex", kernel_reg);
    end

endmodule



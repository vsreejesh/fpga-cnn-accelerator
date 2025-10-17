`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.10.2025 10:59:19
// Design Name: 
// Module Name: cnn_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// cnn_top.v
module cnn_top(
    input clk,
    input reset,
    input start,
    output reg [7:0] out_pixel, // Assuming 8-bit pixel values
    output reg done
);

    // --- Internal Storage ---
    // 5x5 Input Image (25 pixels)
    reg [7:0] image_reg [0:24];
    // 3x3 Kernel (9 weights)
    reg [7:0] kernel_reg [0:8];

    // --- Wires for internal connection ---
    wire [7:0] pixel_to_pu;
    wire [7:0] weight_to_pu;
    wire [15:0] result_from_pu; // Result will be wider
    wire start_pu;
    wire done_pu;

    // --- Instantiate Modules ---
    control_fsm FSM (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done_pu(done_pu),
        .pixel_out(pixel_to_pu),
        .weight_out(weight_to_pu),
        .start_pu(start_pu),
        .final_done(done),
        .final_result(out_pixel)
    );

    processing_unit PU (
        .clk(clk),
        .reset(reset),
        .start_pu(start_pu),
        .pixel_in(pixel_to_pu),
        .weight_in(weight_to_pu),
        .result_out(result_from_pu),
        .done_pu(done_pu)
    );

    // Initialize image and kernel (example values)
    initial begin
        // A simple image with a vertical edge
        {image_reg[0], image_reg[1], image_reg[2], image_reg[3], image_reg[4]} = {8'd0, 8'd0, 8'd100, 8'd0, 8'd0};
        {image_reg[5], image_reg[6], image_reg[7], image_reg[8], image_reg[9]} = {8'd0, 8'd0, 8'd100, 8'd0, 8'd0};
        // ... and so on for all 25 pixels

        // A simple vertical edge detection kernel
        {kernel_reg[0], kernel_reg[1], kernel_reg[2]} = {8'd1, 8'd0, 8'd-1};
        {kernel_reg[3], kernel_reg[4], kernel_reg[5]} = {8'd1, 8'd0, 8'd-1};
        {kernel_reg[6], kernel_reg[7], kernel_reg[8]} = {8'd1, 8'd0, 8'd-1};
    end

endmodule

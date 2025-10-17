`timescale 1ns / 1ps

module tb_max_pool_26x26();

    // --- Signals ---
    reg clk;
    reg reset;
    reg start;
    wire [9:0] in_map_addr;
    reg signed [15:0] in_map_pixel;
    wire [7:0] out_map_addr;
    wire signed [15:0] out_map_pixel;
    wire out_map_write_en;
    wire done;

    // --- Instantiate DUT ---
    max_pooling_layer_26x26 DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .in_map_addr(in_map_addr),
        .in_map_pixel(in_map_pixel),
        .out_map_addr(out_map_addr),
        .out_map_pixel(out_map_pixel),
        .out_map_write_en(out_map_write_en),
        .done(done)
    );

    // --- Testbench memories ---
    reg signed [15:0] in_feature_map [0:675];  // 26x26 input
    reg signed [15:0] out_feature_map [0:168]; // 13x13 output
    integer i;

    // --- Clock generation ---
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // --- Initialize input feature map ---
    initial begin
        // Fill with a simple pattern: 0,1,2,...49 repeating
        for (i = 0; i < 676; i = i + 1)
            in_feature_map[i] = i % 50;

        // Put a known maximum value in the first 2x2 block
        in_feature_map[0] = 10;
        in_feature_map[1] = 20;
        in_feature_map[26] = 30;
        in_feature_map[27] = 100; // This should become first pooled output

        // Initialize output memory
        for (i = 0; i < 169; i = i + 1)
            out_feature_map[i] = 0;
    end

    // --- Test sequence ---
    initial begin
        reset = 1; start = 0;
        #20 reset = 0;
        #10 start = 1;
        #10 start = 0;

        // Wait until pooling is done
        wait(done == 1);
        $display(">>> MAX POOLING COMPLETE at time %0t <<<", $time);

        // Print first 10 output pixels
        for (i = 0; i < 10; i = i + 1) begin
            $display("Pooled Output[%0d] = %d", i, out_feature_map[i]);
        end

        #20 $finish;
    end

    // --- Memory simulation ---
    always @(posedge clk) begin
        // Provide data requested by DUT
        in_map_pixel <= in_feature_map[in_map_addr];

        // Capture output if DUT writes
        if (out_map_write_en) begin
            out_feature_map[out_map_addr] <= out_map_pixel;
            $display("Time %0t: Writing %d to out_map[%0d]", $time, out_map_pixel, out_map_addr);
        end
    end

endmodule

/* 
`timescale 1ns / 1ps

module tb_single_image_verify();

    // --- Testbench Signals ---
    reg clk;
    reg reset;
    reg start;
    // Packed vector to drive the DUT input
    reg [6271:0] image_data_packed; 

    wire prediction;
    wire done;

    integer i; // for packing loop

    // --- Instantiate the DUT (Device Under Test) ---
    cnn_top DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .image_data_in_packed(image_data_packed),
        .prediction(prediction),
        .done(done)
    );

    // --- Testbench Image Memory (unpacked) ---
    reg [7:0] image_mem [0:783];

    // --- Clock Generation (100 MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Main Test Sequence ---
    initial begin
        // 1. Load the single test image from image.hex
        $readmemh("D:/cnn_samples/sample/data/dog.hex", image_mem);
        $display("\nTESTBENCH: Loading test image from image.hex...");

        // 2. Pack the image data into the wide vector for the DUT
        for (i = 0; i < 784; i = i + 1) begin
            image_data_packed[i*8 +: 8] = image_mem[i];
        end

        // 3. Reset and start the DUT
        reset = 1; start = 0;
        #20;
        reset = 0;
        #10;
        start = 1;
        #10;
        start = 0;

        // 4. Wait for the CNN to finish
        $display("TESTBENCH: CNN processing started. Waiting for result...");
        wait (done == 1);
        #1; // Allow prediction output to settle

        // 5. Check the result and print the corresponding animal name
        $display("--------------------------------------------------");
        $display("TESTBENCH: CNN processing complete!");
        if (prediction === 1'b0) begin
            $display("--> The accelerator predicted: CAT");
        end else begin
            $display("--> The accelerator predicted: DOG");
        end
        $display("--------------------------------------------------");

        // 6. Finish the simulation
        #20;
        $finish;
    end

endmodule */

`timescale 1ns / 1ps

module tb_single_image_verify();

    // --- Testbench Signals ---
    reg clk;
    reg reset;
    reg start;
    reg [6271:0] image_data_packed; 

    wire prediction;
    wire done;

    integer i; // for packing loop

    // --- Wires for Monitoring Internal DUT Signals ---
    // These wires are connected to internal signals of the DUT using hierarchical paths.
    // Add these to your waveform viewer to see the internal FSM flow.
    wire [3:0] top_fsm_state;
    wire       conv_fsm_start;
    wire       conv_fsm_done;
    wire       pool_start;
    wire       pool_done;
    wire       dense_start;
    wire       dense_done;
    wire       pu_start; // start signal for the processing_unit
    wire       pu_done;  // done signal from the processing_unit

    // --- Instantiate the DUT (Device Under Test) ---
    cnn_top DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .image_data_in_packed(image_data_packed),
        .prediction(prediction),
        .done(done)
    );

    // --- Assign internal signals to testbench wires for waveform viewing ---
    assign top_fsm_state    = DUT.state;
    assign conv_fsm_start   = DUT.start_conv_fsm;
    assign conv_fsm_done    = DUT.conv_fsm_done;
    assign pool_start       = DUT.start_pooling;
    assign pool_done        = DUT.pool_done;
    assign dense_start      = DUT.start_dense;
    assign dense_done       = DUT.dense_done;
    assign pu_start         = DUT.start_pu;
    assign pu_done          = DUT.done_pu;

    // --- Testbench Image Memory (unpacked) ---
    reg [7:0] image_mem [0:783];

    // --- Clock Generation (100 MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Main Test Sequence ---
    initial begin
        // 1. Load the single test image from image.hex
        $readmemh("D:/cnn_samples/sample/data/dog.hex", image_mem);
        $display("\nTESTBENCH: Loading test image from image.hex...");

        // 2. Pack the image data into the wide vector for the DUT
        for (i = 0; i < 784; i = i + 1) begin
            image_data_packed[i*8 +: 8] = image_mem[i];
        end

        // 3. Reset and start the DUT
        reset = 1; start = 0;
        #20;
        reset = 0;
        #10;
        start = 1;
        #10;
        start = 0;

        // 4. Wait for the CNN to finish
        $display("TESTBENCH: CNN processing started. Waiting for result...");
        wait (done == 1);
        #1; // Allow prediction output to settle

        // 5. Check the result and print the corresponding animal name
        $display("--------------------------------------------------");
        $display("TESTBENCH: CNN processing complete!");
        if (prediction === 1'b0) begin
            $display("--> The accelerator predicted: CAT");
        end else begin
            $display("--> The accelerator predicted: DOG");
        end
        $display("--------------------------------------------------");

        // 6. Finish the simulation
        #20;
        $finish;
    end

endmodule

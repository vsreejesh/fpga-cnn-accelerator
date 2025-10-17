`timescale 1ns / 1ps

module tb_dense_layer();

    // --- Testbench Signals ---
    reg clk;
    reg reset;
    reg start;
    reg signed [15:0] feature_in;

    wire done;
    wire signed [31:0] class_0_score;
    wire signed [31:0] class_1_score;

    // --- Instantiate the DUT (Device Under Test) ---
    dense_layer DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .feature_in(feature_in),
        .done(done),
        .class_0_score(class_0_score),
        .class_1_score(class_1_score)
    );

    // --- Parameters ---
    localparam INPUT_VECTOR_SIZE = 169;

    // --- Testbench Memory ---
    reg signed [15:0] input_vector [0:INPUT_VECTOR_SIZE-1];
    integer i;

    // --- Clock Generation (100 MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Test Sequence ---
    initial begin
        // 1. Initialize Input Vector
        // For simplicity, let's make every input feature equal to 1
        for (i = 0; i < INPUT_VECTOR_SIZE; i = i + 1) begin
            input_vector[i] = 1;
        end
        
        // 2. Reset and Start the DUT
        reset = 1; start = 0; feature_in = 0;
        #20;
        reset = 0;
        #10;
        start = 1; // Assert start for one cycle
        feature_in <= input_vector[0]; // Pre-load the first feature to align with DUT pipeline
        #10;
        start = 0;

        // 3. Feed the rest of the input vector sequentially
        $display("Time %0t: Starting to feed input vector...", $time);
        for (i = 1; i < INPUT_VECTOR_SIZE; i = i + 1) begin
            @(posedge clk);
            feature_in <= input_vector[i];
        end

        // De-assert feature_in after the last feature is sent
        @(posedge clk);
        feature_in <= 0;

        // 4. Wait for completion
        $display("Time %0t: Finished feeding vector. Waiting for done...", $time);
        wait (done == 1);

        // 5. Display results
        #1; // Allow signals to settle for display
        $display("\n>>> Dense Layer Computation Complete at time %0t <<<", $time);
        $display("    Class 0 Score: %d", class_0_score);
        $display("    Class 1 Score: %d\n", class_1_score);

        // 6. Finish simulation
        #20;
        $finish;
    end

endmodule

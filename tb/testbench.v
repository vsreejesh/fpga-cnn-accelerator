`timescale 1ns / 1ps

module tb_cnn_top();

    // --- Testbench Signals ---
    reg clk;
    reg reset;
    reg start;

    wire prediction;
    wire done;

    // --- Instantiate the DUT (Device Under Test) ---
    cnn_top DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .prediction(prediction),
        .done(done)
    );

    // --- Clock Generation (100 MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Test Sequence ---
    initial begin
        // 1. Apply reset
        reset = 1; start = 0;
        #20;
        reset = 0;
        
        // 2. Assert start for one cycle to begin CNN processing
        #10;
        start = 1;
        #10;
        start = 0;

        // 3. Wait for the entire CNN to complete
        $display("Time %0t: CNN processing started. Waiting for done signal...", $time);
        wait (done == 1);

        // 4. Display final prediction
        #1; // Allow signals to settle for display
        $display("\n>>> CNN End-to-End processing COMPLETE at time %0t <<<", $time);
        $display("    Final Prediction: %b\n", prediction);

        // 5. Finish simulation
        #20;
        $finish;
    end

endmodule

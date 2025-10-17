`timescale 1ns / 1ps

module processing_unit(
    input clk,
    input reset,
    input start_pu,
    input signed [7:0] pixel_in,
    input signed [7:0] weight_in,
    output reg [15:0] result_out,
    output reg done_pu
);

    reg [3:0] mac_count;
    reg signed [15:0] accumulator;
    wire signed [15:0] current_product;

    // Calculate product combinationally to avoid timing issues
    assign current_product = pixel_in * weight_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mac_count <= 0;
            accumulator <= 0;
            done_pu <= 0;
            result_out <= 0;
        end else begin
            // By default, done is low unless the specific end condition is met
            done_pu <= 0;

            if (start_pu) begin
                if (mac_count == 0) begin
                    // First operation: load the first product into the accumulator
                    accumulator <= current_product;
                end else begin
                    // Subsequent operations: accumulate the products
                    accumulator <= accumulator + current_product;
                end

                if (mac_count == 8) begin
                    // On the 9th cycle, the final result is calculated and done is signaled
                    result_out <= accumulator + current_product;
                    done_pu <= 1;
                    mac_count <= 0; 
                end else begin
                    mac_count <= mac_count + 1;
                end
            end else begin
                // If the Processing Unit is not active, keep its counter reset
                mac_count <= 0;
            end
        end
    end
endmodule


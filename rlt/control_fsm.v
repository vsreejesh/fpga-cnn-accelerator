`timescale 1ns / 1ps

module control_fsm(
    input clk,
    input reset,
    input start,
    input done_pu,

    output reg [9:0] pixel_addr_out,    // WIDENED for 28x28 image (784 addresses)
    output reg [3:0] weight_addr_out,
    output reg start_pu,
    output reg latch_result,
    output reg final_done
);

    // --- Parameters for new dimensions ---
    localparam IN_WIDTH = 28;
    localparam OUT_WIDTH = 26;
    localparam KERNEL_SIZE = 9; // 3x3
    localparam OUT_MAP_SIZE = OUT_WIDTH * OUT_WIDTH; // 26x26 = 676

    // --- State Machine Definition ---
    parameter IDLE          = 3'b000;
    parameter COMPUTE_RUN   = 3'b001;
    parameter COMPUTE_WAIT  = 3'b010;
    parameter DONE_STATE    = 3'b100;

    reg [2:0] state, next_state;

    // --- Counters ---
    reg [9:0] out_pixel_count; // WIDENED for 676 output pixels
    reg [3:0] mac_cycle_count; // Counts 0-8 for 3x3 kernel MACs

    // --- Local variables for address calculation ---
    integer base_row;
    integer base_col;
    integer mac_row;
    integer mac_col;

    // --- Combinational (Next State) Logic ---
    always @(*) begin
        // Default values
        next_state = state;
        start_pu = 0;
        latch_result = 0;
        final_done = 0;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = COMPUTE_RUN;
                end
            end
            
            COMPUTE_RUN: begin
                start_pu = 1;
                if (mac_cycle_count == KERNEL_SIZE - 1) begin // End of 3x3 kernel
                    next_state = COMPUTE_WAIT;
                end else begin
                    next_state = COMPUTE_RUN;
                end
            end
            
            COMPUTE_WAIT: begin
                latch_result = 1;
                if (out_pixel_count == OUT_MAP_SIZE - 1) begin // End of 26x26 map
                    next_state = DONE_STATE;
                end else begin
                    next_state = COMPUTE_RUN; // Compute next output pixel
                end
            end
            
            DONE_STATE: begin
                final_done = 1;
                if (!start) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // --- Sequential (State and Counter) Logic ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            out_pixel_count <= 0;
            mac_cycle_count <= 0;
        end else begin
            state <= next_state;
            
            // MAC cycle counter resets for each new output pixel
            if (next_state == COMPUTE_RUN) begin
                if (state == IDLE || state == COMPUTE_WAIT) begin
                    mac_cycle_count <= 0;
                end else begin
                    mac_cycle_count <= mac_cycle_count + 1;
                end
            end
            
            // Output pixel counter increments after each result is latched
            if (state == COMPUTE_WAIT) begin
                out_pixel_count <= out_pixel_count + 1;
            end
            
            // Reset main counter when returning to idle
            if (next_state == IDLE) begin
                out_pixel_count <= 0;
            end
        end
    end
    
    // --- Combinational (Address Generation) Logic ---
    always @(*) begin
        // Calculate base row/col from the 26x26 output map perspective
        base_row = out_pixel_count / OUT_WIDTH;
        base_col = out_pixel_count % OUT_WIDTH;

        // Calculate local row/col within the 3x3 kernel
        mac_row = mac_cycle_count / 3;
        mac_col = mac_cycle_count % 3;
        
        // Calculate the pixel address in the 28x28 input image
        pixel_addr_out = (base_row + mac_row) * IN_WIDTH + (base_col + mac_col);
        
        // The weight address is simply the MAC cycle number
        weight_addr_out = mac_cycle_count;
    end

endmodule

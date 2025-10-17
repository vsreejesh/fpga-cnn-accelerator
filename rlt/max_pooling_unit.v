`timescale 1ns / 1ps

module max_pooling_layer_26x26(
    input clk,
    input reset,
    input start,

    // Interface to read the 26x26 input feature map
    output reg [9:0] in_map_addr,
    input signed [15:0] in_map_pixel,

    // Interface to write the 13x13 output feature map
    output reg [7:0] out_map_addr,
    output reg signed [15:0] out_map_pixel,
    output reg out_map_write_en,

    output reg done
);

    // --- Parameters ---
    localparam IN_MAP_WIDTH = 26;
    localparam OUT_MAP_WIDTH = 13;
    localparam OUT_MAP_SIZE = OUT_MAP_WIDTH * OUT_MAP_WIDTH; // 169

    // --- FSM States ---
    localparam IDLE = 3'b000;
    localparam READ_0 = 3'b001;
    localparam READ_1 = 3'b010;
    localparam READ_2 = 3'b011;
    localparam READ_3 = 3'b100;
    localparam COMPARE_WRITE = 3'b101;
    localparam DONE_STATE = 3'b110;

    reg [2:0] state;

    // --- Counters & Registers ---
    reg [7:0] out_pixel_count;
    reg signed [15:0] window_pixels [0:3];
    reg signed [15:0] max_val; 
    
    // --- Temporary variables for address calculation ---
    integer out_row;
    integer out_col;
    integer base_in_row;
    integer base_in_col;

    // --- Combinational block to find the maximum value ---
    always @(*) begin
        max_val = window_pixels[0];
        if (window_pixels[1] > max_val) max_val = window_pixels[1];
        if (window_pixels[2] > max_val) max_val = window_pixels[2];
        if (window_pixels[3] > max_val) max_val = window_pixels[3];
    end

    // --- Sequential block for state transitions and outputs ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            out_pixel_count <= 0;
            out_map_write_en <= 0;
            done <= 0;
        end else begin
            // Default assignments
            out_map_write_en <= 0;

            case(state)
                IDLE: begin
                    if (start) begin
                        state <= READ_0;
                        out_pixel_count <= 0;
                        done <= 0; // De-assert done when a new operation starts
                    end
                end
                
                READ_0: begin
                    window_pixels[0] <= in_map_pixel;
                    state <= READ_1;
                end
                
                READ_1: begin
                    window_pixels[1] <= in_map_pixel;
                    state <= READ_2;
                end
                
                READ_2: begin
                    window_pixels[2] <= in_map_pixel;
                    state <= READ_3;
                end
                
                READ_3: begin
                    window_pixels[3] <= in_map_pixel;
                    state <= COMPARE_WRITE;
                end
                
                COMPARE_WRITE: begin
                    out_map_pixel <= max_val;
                    out_map_write_en <= 1;
                    
                    if (out_pixel_count == OUT_MAP_SIZE - 1) begin
                        state <= DONE_STATE;
                    end else begin
                        out_pixel_count <= out_pixel_count + 1;
                        state <= READ_0;
                    end
                end
                
                DONE_STATE: begin
                    done <= 1;    // Assert done to signal completion
                    state <= IDLE; // Go back to IDLE, done will remain high
                end
            endcase
        end
    end

    // --- Combinational Address Generation ---
    always @(*) begin
        out_row = out_pixel_count / OUT_MAP_WIDTH;
        out_col = out_pixel_count % OUT_MAP_WIDTH;
        base_in_row = out_row * 2;
        base_in_col = out_col * 2;

        case(state)
            READ_0:  in_map_addr = (base_in_row + 0) * IN_MAP_WIDTH + (base_in_col + 0);
            READ_1:  in_map_addr = (base_in_row + 0) * IN_MAP_WIDTH + (base_in_col + 1);
            READ_2:  in_map_addr = (base_in_row + 1) * IN_MAP_WIDTH + (base_in_col + 0);
            READ_3:  in_map_addr = (base_in_row + 1) * IN_MAP_WIDTH + (base_in_col + 1);
            default: in_map_addr = 0;
        endcase
        
        out_map_addr = out_pixel_count;
    end

endmodule

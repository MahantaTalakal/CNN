`timescale 1ns / 1ps

module conv_controller #(parameter dim=28)(
    input clk, rst, start,
    input [7:0] pixel_in,
    output wire [15:0] conv_out,
    output reg done,
    output wire load_done,conv_done,pool_done
    );

    reg [8:0] i, j;
    reg [9:0] pixel_count;
    reg [15:0] input_image[0:783];  
    reg [15:0] conv_result[0:675];
    
    wire [15:0] input_kernel[0:8];
    
    assign input_kernel[0] = {8'b0,8'b00010011}; 
    assign input_kernel[1] = {8'b0,8'b11011000}; 
    assign input_kernel[2] = {8'b0,8'b01100010}; 
    assign input_kernel[3] = {8'b0,8'b00110010}; 
    assign input_kernel[4] = {8'b0,8'b01011110}; 
    assign input_kernel[5] = {8'b0,8'b01110110}; 
    assign input_kernel[6] = {8'b0,8'b00111011}; 
    assign input_kernel[7] = {8'b0,8'b01000110}; 
    assign input_kernel[8] = {8'b0,8'b11110100}; 

    localparam [3:0] IDLE = 4'd0,
                     LOAD_IMAGE = 4'd1,
                     WAIT_CONV = 4'd2,
                     START_CONV = 4'd3,
                     WAIT_POOL = 4'd4,
                     MAX_POOL = 4'd5,
                     DONE = 4'd6;

    reg [2:0] state_reg, state_next;
    wire [15:0] pixel_in_window[0:8];
    reg [15:0] conv_out_reg [675:0];
    reg [15:0] max_pool_out [0:168];
    reg [3:0] pool_i, pool_j;
    wire [15:0] a, b, c, d;
    wire [15:0] conv_out_temp;
    wire[63:0] pool_window;

    assign pixel_in_window[0] = {input_image[(dim * i) + j],8'b0};     
    assign pixel_in_window[1] = {input_image[(dim * i) + (j+1)],8'b0};
    assign pixel_in_window[2] = {input_image[(dim * i) + (j+2)],8'b0};
    assign pixel_in_window[3] = {input_image[(dim * (i+1)) + j],8'b0};     
    assign pixel_in_window[4] = {input_image[(dim * (i+1)) + (j+1)],8'b0};
    assign pixel_in_window[5] = {input_image[(dim * (i+1)) + (j+2)],8'b0};
    assign pixel_in_window[6] = {input_image[(dim * (i+2)) + j],8'b0};     
    assign pixel_in_window[7] = {input_image[(dim * (i+2)) + (j+1)],8'b0};
    assign pixel_in_window[8] = {input_image[(dim * (i+2)) + (j+2)],8'b0};
    
    assign a = conv_out_reg[(2 * pool_i) * 26 + (2 * pool_j)];
    assign b = conv_out_reg[(2 * pool_i) * 26 + (2 * pool_j + 1)];
    assign c = conv_out_reg[(2 * pool_i + 1) * 26 + (2 * pool_j)];
    assign d = conv_out_reg[(2 * pool_i + 1) * 26 + (2 * pool_j + 1)];

    wire [143:0] pixel_window, kernel_window;
    
    assign pixel_window = {pixel_in_window[8], pixel_in_window[7], pixel_in_window[6],
                           pixel_in_window[5], pixel_in_window[4], pixel_in_window[3],
                           pixel_in_window[2], pixel_in_window[1], pixel_in_window[0]};

    assign kernel_window = {input_kernel[8], input_kernel[7], input_kernel[6],
                            input_kernel[5], input_kernel[4], input_kernel[3],
                            input_kernel[2], input_kernel[1], input_kernel[0]};
                            
    assign pool_window={d,c,b,a};
    
                
    MAC M1(
        .input_img(pixel_window),
        .input_kernel(kernel_window),
        .rst(rst),
        .en(load_done),
        .conv_out(conv_out_temp)
    );
    
    Max_Pool pool1(
        .rst(rst),
        .en(conv_done),
        .pixel_in(pool_window),
        .max_out(conv_out)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) 
            state_reg <= IDLE;
        else 
            state_reg <= state_next;
    end

    always @(posedge clk) begin
        if (rst)
            pixel_count <= 0;
        else if (state_reg == LOAD_IMAGE && pixel_count < 784) begin
            input_image[pixel_count] <= pixel_in;
            pixel_count <= pixel_count + 1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            i <= 0;
            j <= 0;
        end else if (state_reg == START_CONV) begin
            conv_out_reg [(i*26)+j] <= conv_out_temp;
            if (j < 26) 
                j <= j + 1;
            else begin
                j <= 0;
                i <= i + 1;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            pool_i <= 0;
            pool_j <= 0;
        end else if (state_reg == MAX_POOL) begin
            if (pool_j < 12) 
                pool_j <= pool_j + 1;
            else begin
                pool_j <= 0;
                pool_i <= pool_i + 1;
            end
        end
    end

    always @(*) begin
        state_next = state_reg;
        done = 0;
        case (state_reg)
            IDLE:
            
                if (start)
                    state_next = LOAD_IMAGE;
                    
            LOAD_IMAGE:
            
                if (pixel_count >= 784)
                    state_next = WAIT_CONV;
                    
            WAIT_CONV:
            
                state_next = START_CONV;
                
            START_CONV:
            
                if (i >= 26)
                    state_next = WAIT_POOL;
                    
            WAIT_POOL:
            
                state_next = MAX_POOL;
                    
            MAX_POOL:
            
                if (pool_i >= 12 && pool_j >= 12)
                    state_next = DONE;
                    
            DONE: begin
                done = 1;
                state_next = IDLE;
            end
        endcase
    end
    
    assign load_done = pixel_count >= 784 ? 1 : 0 ;
    assign conv_done = (i >= 26) ? 1 : 0;
    assign pool_done = (pool_i >= 13) ? 1 : 0;

    
endmodule

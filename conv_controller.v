`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.03.2025 12:42:44
// Design Name: 
// Module Name: conv_controller
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


module conv_controller #(parameter dim=28)(
    input clk, rst, start,
    input [7:0] pixel_in,
    output wire [19:0] conv_out,
    output reg done
    );
    
    reg [20:0] conv_out_temp;
    reg [8:0] i, j;
    reg [9:0] pixel_count;
    
    reg [7:0] input_image[783:0];  
     
    wire [7:0] input_kernel1, input_kernel2, input_kernel3;
    wire [7:0] input_kernel4, input_kernel5, input_kernel6;
    wire [7:0] input_kernel7, input_kernel8, input_kernel9;
   
    reg [20:0] conv_result[675:0];
    
    wire load_done;

     assign input_kernel1 = 8'd00010011;
     assign input_kernel2 = 8'd11011000;
     assign input_kernel3 = 8'd01100010;
     assign input_kernel4 = 8'd00110010;
     assign input_kernel5 = 8'd01011110;
     assign input_kernel6 = 8'd01110110;
     assign input_kernel7 = 8'd00111011;
     assign input_kernel8 = 8'd01000110;
     assign input_kernel9 = 8'd11110100; 

    
    localparam [3:0] IDLE = 4'd0,
                     LOAD_IMAGE = 4'd1,
                     WAIT_CONV = 4'd2,
                     START_CONV = 4'd3,
                     MAX_POOL = 4'd4,
                     DONE = 4'd5;

    reg [2:0] state_reg, state_next;
    
    wire [7:0] pixel_in_1, pixel_in_2, pixel_in_3;
    wire [7:0] pixel_in_4, pixel_in_5, pixel_in_6;
    wire [7:0] pixel_in_7, pixel_in_8, pixel_in_9;
    
    wire [71:0] pixel_window;
    wire [71:0] kernel_window;

    assign pixel_in_1 = input_image[(dim * i) + j];     
    assign pixel_in_2 = input_image[(dim * i) + (j+1)];
    assign pixel_in_3 = input_image[(dim * i) + (j+2)];

    assign pixel_in_4 = input_image[(dim * (i+1)) + j];     
    assign pixel_in_5 = input_image[(dim * (i+1)) + (j+1)];
    assign pixel_in_6 = input_image[(dim * (i+1)) + (j+2)];

    assign pixel_in_7 = input_image[(dim * (i+2)) + j];     
    assign pixel_in_8 = input_image[(dim * (i+2)) + (j+1)];
    assign pixel_in_9 = input_image[(dim * (i+2)) + (j+2)];
    
    assign pixel_window ={  pixel_in_9, pixel_in_8, pixel_in_7,
                            pixel_in_6, pixel_in_5, pixel_in_4,
                            pixel_in_3, pixel_in_2, pixel_in_1  };
    
    assign kernel_window = { input_kernel9, input_kernel8, input_kernel7,
                             input_kernel6, input_kernel5, input_kernel4,
                             input_kernel3, input_kernel2, input_kernel1 };
                  
               
                                      
    MAC M1(
    .input_img(pixel_window),
    .input_kernel(kernel_window),
    .rst(rst),
    .en(load_done),
    .conv_out(conv_out)
    );
    
    
    always@(posedge clk) begin
    
    if(rst)state_reg<= IDLE;
    
    else state_reg<=state_next;
    
    end
    
    always @(posedge clk) begin

        if(rst) pixel_count <= 0;
            
        else if (state_reg == LOAD_IMAGE) begin
        
            input_image[pixel_count] <= pixel_in;
            pixel_count <= pixel_count + 1;
            
        end
        
    end
    
    always @(posedge clk) begin
        
        if(rst)begin
        i <= 0;
        j <= 0;
        end
        
        else if (state_reg == START_CONV) begin
        
           j<=j+1;
           if(j>26) begin
            j <= 0;
            i <= i+1;
           end
            
        end
        
    end
    
    always@(*) begin
        state_next=state_reg;
        done = 0;
    case (state_reg)
            IDLE: begin
                if (start)
                    state_next = LOAD_IMAGE;
                else
                    state_next = IDLE;
            end
            
            LOAD_IMAGE: begin
                if (pixel_count < 784) begin
                    state_next = LOAD_IMAGE;
                end else begin
                    state_next = WAIT_CONV;
                end
            end
            
            WAIT_CONV: begin
                if (load_done)
                    state_next = START_CONV;
                else
                    state_next = WAIT_CONV;
            end
            
            START_CONV: begin
                if(i>26) begin
                state_next = MAX_POOL;
                end 
            end
            
            MAX_POOL: begin
                state_next = DONE;
            end
            
            DONE: begin
                done = 1;
                state_next = IDLE; // Restart process
            end
            
            default: state_next = IDLE;
        endcase
    
    
    end
    
    assign load_done= (pixel_count>=784) ? 1 : 0;
    
    
endmodule

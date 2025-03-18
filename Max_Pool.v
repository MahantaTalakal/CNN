`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.03.2025 22:51:59
// Design Name: 
// Module Name: Max_Pool
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


module Max_Pool(
input rst,
input en,
input[79:0] pixel_in,
output reg [19:0] max_out
    );
    
    wire [19:0] a,b,c,d;
    assign a = pixel_in[19:0];
    assign b = pixel_in[39:20];
    assign c = pixel_in[59:40];
    assign d = pixel_in[79:60];
    
    always @* begin
    max_out = (rst || ~en) ? 20'b0 : 
                             (a > b) ? ((a > c) ? ((a > d) ? a : d) : ((c > d) ? c : d)) 
                              : ((b > c) ? ((b > d) ? b : d) : ((c > d) ? c : d));
               
   end
    
endmodule

module conv(
    input clk, rst, start,
    input [7:0] pixel_in,
    output wire [20:0] conv_out,
    output reg done
);
    initial begin
        $readmemb("input_kernel.mem", input_kernel);
    end
    
    reg [7:0] input_image[783:0];   // 28x28 image
    reg [7:0] input_kernel[8:0];    // 3x3 kernel
    reg [20:0] conv_result[675:0];  // 26x26 convolution result
    
    reg [20:0] conv_out_temp;
    reg [8:0] i, j;
    reg [9:0] pixel_count;

    localparam [2:0] IDLE = 3'd0,
                     LOAD_IMAGE = 3'd1,
                     START_CONV = 3'd2,
                     MAX_POOL = 3'd3,
                     DONE = 3'd4;

    reg [2:0] state_reg, state_next;
    reg [8:0] pool_i, pool_j;  // Pooling indices

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            pixel_count <= 0;
            i <= 0;
            j <= 0;
            pool_i <= 0;
            pool_j <= 0;
            conv_result[(i * 26) + j] <= 0;
            
        end else begin
            state_reg <= state_next;

            if (state_reg == LOAD_IMAGE) begin
                input_image[pixel_count] <= pixel_in;
                pixel_count <= pixel_count + 1;
            end

            if (state_reg == START_CONV) begin
                j <= j + 1;
                if (j >= 25) begin
                    i <= i + 1;
                    j <= 0;
                end
                
                conv_result[(i * 26) + j] <= conv_out_temp;
                
            end

            if (state_reg == MAX_POOL) begin
                pool_j <= pool_j + 2;  // Skip 2 columns
                if (pool_j >= 24) begin
                    pool_i <= pool_i + 2;  // Skip 2 rows
                    pool_j <= 0;
                end
            end
        end
    end
    
    always @(*) begin
        state_next = state_reg;
        done = 0;

        case (state_reg)
            IDLE: begin
                conv_out_temp = 0;
                done = 0;
                state_next = start ? LOAD_IMAGE : IDLE;
            end
            
            LOAD_IMAGE: begin
                if (pixel_count >= 784)
                    state_next = START_CONV;
                conv_out_temp = 0;
            end
            
            START_CONV: begin
                conv_out_temp = (input_image[(i * 28) + j]) * (input_kernel[0]) +
                                (input_image[(i * 28) + j + 1]) * (input_kernel[1]) +
                                (input_image[(i * 28) + j + 2]) * (input_kernel[2]) +
                                (input_image[((i + 1) * 28) + j]) * (input_kernel[3]) +
                                (input_image[((i + 1) * 28) + j + 1]) * (input_kernel[4]) +
                                (input_image[((i + 1) * 28) + j + 2]) * (input_kernel[5]) +
                                (input_image[((i + 2) * 28) + j]) * (input_kernel[6]) +
                                (input_image[((i + 2) * 28) + j + 1]) * (input_kernel[7]) +
                                (input_image[((i + 2) * 28) + j + 2]) * (input_kernel[8]);

                if (i >= 26)
                    state_next = MAX_POOL;
            end
            
            MAX_POOL: begin
               
                conv_out_temp = conv_result[(pool_i * 26) + pool_j];
                
                if (conv_result[(pool_i * 26) + pool_j + 1] > conv_out_temp)
                    conv_out_temp = conv_result[(pool_i * 26) + pool_j + 1];
                    
                if (conv_result[((pool_i + 1) * 26) + pool_j] > conv_out_temp)
                    conv_out_temp = conv_result[((pool_i + 1) * 26) + pool_j];
                    
                if (conv_result[((pool_i + 1) * 26) + pool_j + 1] > conv_out_temp)
                    conv_out_temp = conv_result[((pool_i + 1) * 26) + pool_j + 1];

                
                if (pool_i >=25)
                    state_next = DONE;
            end

            DONE: begin
            
                conv_out_temp = 0;
                done = 1;
                state_next = IDLE;
                
            end
            
            default: begin state_next = IDLE; conv_out_temp = 0; end
        endcase
    end
    
    assign conv_out = (rst | ~(state_reg == MAX_POOL)) ? 0 : conv_out_temp;

endmodule

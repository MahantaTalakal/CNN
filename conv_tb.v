`timescale 1ns / 1ps

module conv_tb;
    reg clk, rst, start;
    reg [7:0] pixel_in;
    wire [20:0] conv_out;
    wire done;
    wire [15:0] index;

    // Instantiate the DUT
    conv uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixel_in(pixel_in),
        .conv_out(conv_out),
        .done(done),
        .index(index)
    );

    // Clock generation
    always #5 clk = ~clk;

    // File handling
    integer file;
    reg [7:0] image_data[783:0]; // Array to store image pixels
    integer pixel_count = 0;      // Tracks pixels sent

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        pixel_in = 0;

        // Read input image from file
        $readmemb("input_img.mem", image_data);
        
        // Reset sequence
        #20;
        rst = 0;
        #10;

        // Start sending pixels
        start = 1;
        #10;
        start = 0;

        // Send one pixel per clock cycle
        while (pixel_count < 784) begin
            pixel_in = image_data[pixel_count];
            pixel_count = pixel_count + 1;
            #10; // Wait for clock cycle
        end

        $display("All pixels sent. Waiting for convolution + pooling process...");

        // Open file to write pooled results
        file = $fopen("pooled_output.txt", "w");
        if (file == 0) begin
            $display("Error: Could not open file.");
            $finish;
        end

        // Capture pooling output on every clock cycle until done is asserted
        while (!done) begin
            #10;
            $fwrite(file, "%d\n", conv_out);
        end
        
        $fclose(file);
        $display("Pooling results saved to pooled_output.txt");
        $finish;
    end
endmodule

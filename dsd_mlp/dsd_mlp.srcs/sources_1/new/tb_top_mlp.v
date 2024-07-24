`timescale 1ns / 1ns

module tb_top_mlp;
wire     y_buf_en;
wire     y_buf_wr_en;
wire [31:0] y_buf_addr;
wire [31:0] y_buf_data;
reg     clk = 1'b1;
reg     rst_n = 1'b0;
reg     start = 1'b0;

always #1 clk = ~clk;


top_mlp dut (
    .clk                      (clk                        ),
    .rst_n                    (rst_n                      ),
    .start_i                    (start                      ),
    .done_intr_o                 (                           ),
    .done_led_o                 (                           ),
    
    .y_buf_en               (y_buf_en                  ),
    .y_buf_wr_en             (y_buf_wr_en                  ),
    .y_buf_addr              (y_buf_addr                ),
    .y_buf_data              (y_buf_data                )
);





initial begin
    #40 rst_n = 1'b1;
    #10 start = 1'b1;
    #40 start = 1'b0;
end

endmodule
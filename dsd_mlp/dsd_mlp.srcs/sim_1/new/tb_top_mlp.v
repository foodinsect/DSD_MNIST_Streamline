`timescale 1ns / 1ns

module tb_top_mlp;

reg     clk = 1'b1;
reg     rst_n = 1'b0;
reg     start = 1'b0;

always #1 clk = ~clk;

parameter IMGNUM = 10;
parameter output_addr_width = $clog2(IMGNUM * 10);
reg     [31:0] outbuf [0:99];
wire                outbuf_we;
wire    [output_addr_width-1:0]   outbuf_addr;
wire    [31:0]      outbuf_data;
always @(posedge clk) begin
    if(outbuf_we) outbuf[outbuf_addr] <= outbuf_data;
end



top dut (
    .clk_i                      (clk                        ),
    .rstn_i                    (rst_n                      ),
    .start_i                    (start                      ),
    .done_intr_o                 (                           ),
    .done_led_o                 (                           ),

    .y_buf_wr_en             (outbuf_we                  ),
    .y_buf_addr              (outbuf_addr                ),
    .y_buf_data              (outbuf_data                )
);





initial begin
    #40 rst_n = 1'b1;
    #10 start = 1'b1;
    #40 start = 1'b0;
end

endmodule
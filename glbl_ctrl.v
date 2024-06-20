`timescale 1ns / 1ps
module glbl_ctrl(
input wire              clk_i,
input wire              rstn_i,

input   wire            buf_wr_done,

output  wire            done_intr_o,
output  wire            done_led_o
);

//hold irq pulse for 6 cycles
reg     [5:0]   irq_sr;
reg             led;
assign  done_intr_o = |{irq_sr};
assign  done_led_o = led;

always @(posedge clk_i) begin
    irq_sr[0] <= buf_wr_done;
    irq_sr[5:1] <= irq_sr[4:0];

    if(!rstn_i) led <= 1'b0;
    else begin
        if(done_intr_o) led <= 1'b1;
    end
end

endmodule
`timescale 1ns / 1ps

module pu_3(
    input wire  rstn_i,
    input wire  clk_i,
    input wire  start_i,
    input wire  en_i,
    input wire  valid_i,
    input wire  mac_clear,

    input wire signed [7:0]             din_i,       
    input wire signed [8*10-1:0]        win_i,        
    
    output wire signed [(32*10)-1:0]    data_o   
);

    wire signed [31:0] mac_outputs [10-1:0];
    reg     [1:0] acc_en_delay;
    
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin: mac_gen
            // MAC inst
            mac MAC_layer5 (
                .clk_i(clk_i),
                .rstn_i(rstn_i),
                .mac_en(en_i),
                .acc_en(acc_en_delay[1]),
                .image_data(din_i),
                .weight_data(win_i[(i+1)*8-1:i*8]),
                .dsp_output_o(mac_outputs[i])
            );
            
            assign  data_o[i*32 +: 32] = mac_outputs[i];

         end
    endgenerate
    
    always @(posedge clk_i) begin
        if (!rstn_i) begin 
            acc_en_delay <= 2'b0;
        end else begin
            acc_en_delay[0] <= en_i;
            acc_en_delay[1] <= acc_en_delay[0];
        end
    end
endmodule

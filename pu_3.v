`timescale 1ns / 1ps

module pu_3(
    input wire  rstn_i,
    input wire  clk_i,
    input wire  start_i,
    input wire  en_i,
    input wire  valid_i,
    input wire  mac_clear,

    input wire signed [7:0]             din_i,         // 맥 갯수 * 8  = 64비트
    input wire signed [8*10-1:0]        win_i,         // w in 비트수 = 8 = 8비트
    
    output wire signed [(32*10)-1:0] matmul_o    // 32비트 * 맥갯수 = 256 비트
);

    wire signed [31:0] mac_outputs [10-1:0];

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin: mac_gen

            // MAC 인스턴스 생성
            mac2 my_mac (
                .clk_i(clk_i),
                .rstn_i(rstn_i),
                .mac_en(en_i),
                .valid_i(valid_i),
                .mac_clear(mac_clear),
                .image_data(din_i),
                .weight_data(win_i[(i+1)*8-1:i*8]),
                .dsp_output_o(mac_outputs[i])
            );
            
            assign  matmul_o[i*32 +: 32] = mac_outputs[i];

         end
    endgenerate

endmodule

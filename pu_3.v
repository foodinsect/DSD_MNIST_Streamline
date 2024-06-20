`timescale 1ns / 1ps

module pu_3(
    input wire  rstn_i,
    input wire  clk_i,
    input wire  start_i,
    input wire  en_i,
    input wire  valid_i,
    input wire  mac_clear,

    input wire signed [7:0]             din_i,         // �� ���� * 8  = 64��Ʈ
    input wire signed [8*10-1:0]        win_i,         // w in ��Ʈ�� = 8 = 8��Ʈ
    
    output wire signed [(32*10)-1:0] matmul_o    // 32��Ʈ * �ư��� = 256 ��Ʈ
);

    wire signed [31:0] mac_outputs [10-1:0];

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin: mac_gen

            // MAC �ν��Ͻ� ����
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

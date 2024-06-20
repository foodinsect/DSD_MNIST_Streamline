`timescale 1ns / 1ps

module pu #(
    parameter COEFF = 17'b0_0000_0000_1101_1100,
    parameter DATA_WIDTH = 8,
    parameter MAC_CNT = 128
)(
    input wire  rstn_i,
    input wire  clk_i,
    input wire  mac_en_i,
    input wire  relu_en_i,
    input wire  mac_clear,

    input wire signed [DATA_WIDTH-1:0]              din_i,         
    input wire signed [DATA_WIDTH*MAC_CNT-1:0]      win_i,         // w in 비트수 = 8 = 8비트
    
    output wire                                     done_o,
    output wire signed [(DATA_WIDTH*MAC_CNT)-1:0]   matmul_o    // 32비트 * 맥갯수 = 256 비트
);
    wire    signed  [DATA_WIDTH-1:0]  mac_outputs [MAC_CNT-1:0];
    reg     [1:0] acc_en_delay;
    reg     [4:0] control_delay; 

    // 배열 내의 각 요소를 초기화합니다.
    genvar i;
    generate
        for (i = 0; i < MAC_CNT; i = i + 1) begin: mac_gen
            // MAC 인스턴스 생성
            mac #(
                .COEFF(COEFF)
            )  MAC_layer1 (
                .clk_i(clk_i),
                .rstn_i(rstn_i),
                .mac_en(mac_en_i),
                .relu_en(relu_en_i),
                .acc_en(acc_en_delay[1]),
                .qdq_en(control_delay[0]),
                .round_en(control_delay[2]),
                .sat_en(control_delay[3]),
                .mac_clear(control_delay[4]),
                .image_data(din_i),
                .weight_data(win_i[(i+1)*8-1:i*8]),
                .dsp_output_o(mac_outputs[i])
            );
            
            assign matmul_o[i*8 +: 8] = mac_outputs[i];
         end
    endgenerate

    always @(posedge clk_i) begin
        if (!rstn_i) begin
            acc_en_delay <= 2'b0;
            control_delay <= 3'b0;
        end else begin
            acc_en_delay[0] <= mac_en_i;
            acc_en_delay[1] <= acc_en_delay[0];
            control_delay[0] <= relu_en_i;
            control_delay[1] <= control_delay[0];
            control_delay[2] <= control_delay[1];
            control_delay[3] <= control_delay[2];
            control_delay[4] <= control_delay[3];
        end
    end
    
    assign done_o = control_delay[4];
endmodule

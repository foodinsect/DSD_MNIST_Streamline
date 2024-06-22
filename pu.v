`timescale 1ns / 1ps

/*
    .qdq_en(control_delay[0]),
    .round_en(control_delay[2]),
    .sat_en(control_delay[3]),
*/

module pu #(
    parameter COEFF = 17'b0_0000_0000_1101_1100,
    parameter DATA_WIDTH = 8,
    parameter MAC_NUM = 128
)(
    input wire  rstn_i,
    input wire  clk_i,
    input wire  mac_en_i,
    input wire  relu_en_i,
    
    input wire signed   [DATA_WIDTH-1:0]            din_i,         
    input wire signed   [DATA_WIDTH*MAC_NUM-1:0]    win_i,   
       
    output wire                                     temp_start,   
    output wire                                     done_o,
    output wire signed  [(DATA_WIDTH)-1:0]          data_o    
);
    wire    signed  [23:0]  mac_outputs [MAC_NUM-1:0];
    reg     signed  [23:0]  intermediate_result [MAC_NUM-1:0];
    reg     prcss_en;
    reg     [6:0] cnt [0:1];
    reg     [1:0] acc_en_delay;
    reg     [3:0] pu_en_delay;
    reg     [3:0] control_delay; 
    reg     [40:0] qdq_result;
    reg     [(DATA_WIDTH)-1:0]  rounded;
    reg     [(DATA_WIDTH)-1:0]  result;
    reg     [2:0] done_delay;

    genvar i;
    generate
        for (i = 0; i < MAC_NUM; i = i + 1) begin: mac_gen
            // MAC inst
            mac MAC_layer1 (
                .clk_i(clk_i),
                .rstn_i(rstn_i),
                .relu_en(relu_en_i),
                .acc_en(acc_en_delay[1]),
                .mac_clear(pu_en_delay[2]),
                .image_data(din_i),
                .weight_data(win_i[(i+1)*8-1:i*8]),
                .dsp_output_o(mac_outputs[i])
            );
            
            always @(posedge clk_i) begin
                if (!rstn_i) begin
                    intermediate_result[i] <= 0;
                end
                else if (relu_en_i) begin
                    intermediate_result[i] <= 0;
                end
                else if (pu_en_delay[0]) begin
                    intermediate_result[i] <= mac_outputs[i];
                end
            end
            
         end
    endgenerate

    always @(posedge clk_i) begin
        if (pu_en_delay[0]) begin
            qdq_result <= 41'b0;
            result <= 8'h00;
        end else begin
            if (control_delay[0]) begin             // Q/DQ
                qdq_result <= intermediate_result[(MAC_NUM - 1) - cnt[1]] * COEFF;
            end
            if (control_delay[1]) begin    // Round
                rounded <= qdq_result[23:16] + qdq_result[15];
            end
            if (control_delay[2]) begin    // Saturation
                if (rounded > 8'h7f) begin
                    result <= 8'h7f;
                end else begin
                    result <= rounded;
                end
            end
        end
    end

    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            prcss_en <= 0;
            cnt[0] <= 0;
        end
        else begin
            if (relu_en_i) begin
                prcss_en <= 1;
            end
            if (prcss_en) begin
                cnt[0] <= cnt[0] + 1;
            end
            if (cnt[0] == MAC_NUM-1) begin
                prcss_en <= 0;
                cnt[0] <= 0;
                done_delay[0] <= 1;
            end else begin
                done_delay[0] <= 0;
            end
        end
    end

    always @(posedge clk_i) begin
        if (!rstn_i) begin 
            acc_en_delay <= 2'b0;
            control_delay <= 5'b0;
        end else begin
            acc_en_delay[0] <= mac_en_i;
            acc_en_delay[1] <= acc_en_delay[0];
            control_delay[0] <= prcss_en;
            control_delay[1] <= control_delay[0];
            control_delay[2] <= control_delay[1];
            control_delay[3] <= control_delay[2];
            pu_en_delay[0] <= relu_en_i;
            pu_en_delay[1] <= pu_en_delay[0];
            pu_en_delay[2] <= pu_en_delay[1];
            pu_en_delay[3] <= pu_en_delay[2];
            done_delay[1] <= done_delay[0];
            done_delay[2] <= done_delay[1];
            cnt[1] <= cnt[0];
        end
    end
    
    assign temp_start = pu_en_delay[3];
    assign data_o = (control_delay[3]) ? result : 8'h00;
    assign done_o = done_delay[2];
endmodule

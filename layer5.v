`timescale 1ns / 1ps

module layer5(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    input wire      [12:0]          cnt,

    input   wire    [7:0]           layer4_data,
    output  wire    [4:0]           layer4_buf_addr,
    output  wire                    layer4_buf_en,
    
    output  wire    [10*32-1:0]     do_layer5,
    output  wire                    temp_wr_start,
    output  wire                    done_o
    );

    // layer 5 Weight
    wire    [5:0]           w5_buf_addr;
    wire                    w5_buf_en;
    wire    [8*10-1:0]      w5_buf_data;
    wire    mac_clear;
    
    wire    pu_en5, done_5, mac_valid_5;
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    ///////////////     LAYER 5
    local_ctrl_layer5 layer5_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .cnt(cnt),
        .w_addr_o(w5_buf_addr),
        .w_en_o(w5_buf_en),
        .x_addr_o(layer4_buf_addr),
        .x_en_o(layer4_buf_en),
        .mac_en_o(pu_en5),
        .mac_valid(mac_valid_5),
        .mac_clear(mac_clear),
        .temp_wr_o(temp_wr_start),
        .done_o()
    );
    
    pu_3 PU_5 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .mac_clear(mac_clear),
        .en_i(pu_en5),
        .valid_i(mac_valid_5),
        
        .din_i(layer4_data), 
        .win_i(w5_buf_data),
        
        .data_o(do_layer5)      
    );

    
    single_port_bram  #(
        .WIDTH(80),         // 8 * 10
        .DEPTH(32),
        .INIT_FILE("C:/try2/w5_buffer.txt")
    ) w5_buf (
        .clk(clk_i),
        .en(w5_buf_en),
        .wen(),
        .addr(w5_buf_addr),
        .din(),
        .dout(w5_buf_data)
    );
    
endmodule

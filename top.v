`timescale 1ns / 1ps
module top #(
    parameter IN_IMG_NUM = 10,
    parameter Y_BUF_DATA_WIDTH = 32,
	parameter Y_BUF_ADDR_WIDTH = 32,  							// add in 2023-05-10
    parameter Y_BUF_DEPTH = 10*IN_IMG_NUM * 4 					// modify in 2024-04-17, y_buf_addr has to increase +4 -> 0 - 396
)(
    input   wire                clk_i,
    input   wire                rstn_i,
    input   wire                start_i,
    
    output  wire                done_intr_o,
    output  wire                done_led_o,
    
    //output buffer interface
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [Y_BUF_ADDR_WIDTH-1:0]     y_buf_addr,         // [31:0] addr
    output  wire [Y_BUF_DATA_WIDTH-1:0]     y_buf_data          // [31:0] addr
);
    
    wire    layer1_buf_en, layer2_buf_en, layer3_buf_en, layer4_buf_en;
    
    wire    done_1, done_2, done_3, done_4, done_5;
    
    wire    [12:0]  cnt;
    
    wire    pu_done_1, temp_wr_start;
    wire    layer1_temp_clear;
    wire    layer2_temp_clear;
    wire    layer3_temp_clear;
    
    wire    [7:0]           layer1_data;
    wire    [6:0]           layer1_buf_addr;
    
    wire    [7:0]           layer2_data;
    wire    [5:0]           layer2_buf_addr;
    
    wire    [7:0]           layer3_data;
    wire    [5:0]           layer3_buf_addr;
    
    wire    [7:0]           layer4_data;
    wire    [4:0]           layer4_buf_addr;
    wire    [32*10-1:0]     do_layer5;

    wire    buf_wr_done;
    
    /*
        INPUT SWITCH PEDGE DETECTOR
    */
    reg     [2:0]   sw_syncchain;
    wire            sw_pdet = ~sw_syncchain[2] & sw_syncchain[1];
    always @(posedge clk_i) begin
        if(!rstn_i) sw_syncchain <= 3'b000;
        else begin
            sw_syncchain[2:1] <= sw_syncchain[1:0];
            sw_syncchain[0] <= start_i;
        end
    end

    
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////
   ///////////////   BRAM inst
   
   layer1 layer1_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(sw_pdet),

    .temp_rd_en(layer1_buf_en),
    .temp_rd_addr(layer1_buf_addr),
    .temp_clear(layer1_temp_clear),

    .cnt_o(cnt),
    .pu_done(pu_done_1),
    
    .data_o(layer1_data)
    );
    
    
   layer2 layer2_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(pu_done_1),
    .cnt(cnt),

    .layer1_data(layer1_data),
    .layer1_buf_addr(layer1_buf_addr),
    .layer1_buf_en(layer1_buf_en),

    .layer1_temp_clear(layer1_temp_clear),

    .temp_rd_en(layer2_buf_en),
    .temp_rd_addr(layer2_buf_addr),
    .temp_clear(layer2_temp_clear),
    .data_o(layer2_data)
    );
    
    
   layer3 layer3_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(layer1_temp_clear),
    .cnt(cnt),

    .layer2_data(layer2_data),
    .layer2_buf_addr(layer2_buf_addr),
    .layer2_buf_en(layer2_buf_en),
    
    .layer2_temp_clear(layer2_temp_clear),

    .temp_rd_en(layer3_buf_en),
    .temp_rd_addr(layer3_buf_addr),
    .temp_clear(layer3_temp_clear),
    .data_o(layer3_data)
    );
    
    
   layer4 layer4_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(layer2_temp_clear),
    .cnt(cnt),

    .layer3_data(layer3_data),
    .layer3_buf_addr(layer3_buf_addr),
    .layer3_buf_en(layer3_buf_en),
    
    .layer3_temp_clear(layer3_temp_clear),

    .temp_rd_en(layer4_buf_en),
    .temp_rd_addr(layer4_buf_addr),
    .temp_clear(temp_wr_start),
    .data_o(layer4_data)
    );
    
   layer5 layer5_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .cnt(cnt),
    .start_i(layer3_temp_clear),

    .layer4_data(layer4_data),
    .layer4_buf_addr(layer4_buf_addr),
    .layer4_buf_en(layer4_buf_en),

    .do_layer5(do_layer5),
    .temp_wr_start(temp_wr_start),
    .done_o(done_5)
    );
    
    temp_buf #(
        .DATAWIDHT(Y_BUF_DATA_WIDTH),
        .ADDR_WIDTH(Y_BUF_ADDR_WIDTH)
    ) temp_buf(
        .clk(clk_i),
        .rst_n(rstn_i),
        .data_in(do_layer5),
        .buf_wr_start(temp_wr_start),
        .temp_buf_addr(y_buf_addr),
        .temp_buf_data(y_buf_data),
        .temp_buf_en(y_buf_wr_en),
        .temp_buf_done(buf_wr_done)
    );
    
    glbl_ctrl global_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .buf_wr_done(buf_wr_done),
        .done_intr_o(done_intr_o),
        .done_led_o(done_led_o)
    );
    
endmodule
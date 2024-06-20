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
    

    // PU signal
    wire    pu_en2, pu_en3, pu_en4, pu_en5;
    wire    mac_valid_2, mac_valid_3, mac_valid_4, mac_valid_5;
    
    wire    x2_buf_en, x3_buf_en, x4_buf_en, x5_buf_en;
    
    wire    done_1, done_2, done_3, done_4, done_5;
    
    wire    [12:0]  cnt;
    
    wire    temp_wr_en_layer1,  temp_wr_en_layer5;
    wire    temp_wr_en_layer2, temp_wr_en_layer2_1;
    wire    temp_wr_en_layer3, temp_wr_en_layer3_1;
    wire    temp_wr_en_layer4, temp_wr_en_layer4_1;
    
    wire    [7:0]           x2_buf_data;
    wire    [6:0]           x2_buf_addr;
    
    wire    [7:0]           x3_buf_data;
    wire    [5:0]           x3_buf_addr;
    
    wire    [7:0]           x4_buf_data;
    wire    [5:0]           x4_buf_addr;
    
    wire    [7:0]           x5_buf_data;
    wire    [4:0]           x5_buf_addr;
    
    wire    [128*8-1:0]     do_layer1;
    wire    [32*8-1:0]      do_layer2;
    wire    [32*8-1:0]      do_layer3; 
    wire    [16*8-1:0]      do_layer4; 
    wire    [10*32-1:0]      do_layer5; 
    
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
    
    .do_layer1(do_layer1),
    .cnt_o(cnt),
    .temp_wr_en(temp_wr_en_layer1),
    .done_o()
    );
    
   // Instance of temp_bram
    temp_bram #(
        .MAC_CNT(128),
        .DATA_WIDTH(8)
    ) layer1_temp_bram (
        .clk_i(clk_i),
        .rstn_i(rstn_i),         // layer2 cal done -> clear
        .rd_temp_en(x2_buf_en),
        .data_in(do_layer1),
        .clear(temp_wr_en_layer2_1),
        
        .wr_temp_en(temp_wr_en_layer1),
        .temp_bram_index(x2_buf_addr),
        .data_out(x2_buf_data)
    );
    
   layer2 layer2_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(temp_wr_en_layer1),
    .x2_buf_data(x2_buf_data),
    .cnt(cnt),
    
    .x2_buf_addr(x2_buf_addr),
    .x2_buf_en(x2_buf_en),
    
    .temp_wr_en_layer2(temp_wr_en_layer2),
    .temp_wr_en_layer2_1(temp_wr_en_layer2_1),
    
    .do_layer2(do_layer2),
    .done_o()
    );
    
    // Instance of temp_bram
    temp_bram_half #(
        .MAC_CNT(32),
        .DATA_WIDTH(8)
    ) layer2_temp_bram (
        .clk_i(clk_i),
        .rstn_i(rstn_i),         // layer2 cal done -> clear
        .rd_temp_en(x3_buf_en),
        .data_in(do_layer2),
        .clear(temp_wr_en_layer3_1),
        
        .wr_temp_en(temp_wr_en_layer2),
        .wr_temp_en_1(temp_wr_en_layer2_1),
        .temp_bram_index(x3_buf_addr),
        .data_out(x3_buf_data)
    );
    
   layer3 layer3_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(temp_wr_en_layer2_1),
    .cnt(cnt),
    .x3_buf_data(x3_buf_data),
    
    .x3_buf_addr(x3_buf_addr),
    .x3_buf_en(x3_buf_en),
    
    .temp_wr_en_layer3(temp_wr_en_layer3),
    .temp_wr_en_layer3_1(temp_wr_en_layer3_1),
    
    .do_layer3(do_layer3),
    .done_o()
    );
    
    // Instance of temp_bram
    temp_bram_half #(
        .MAC_CNT(32),
        .DATA_WIDTH(8)
    ) layer3_temp_bram (
        .clk_i(clk_i),
        .rstn_i(rstn_i),         // layer2 cal done -> clear
        .rd_temp_en(x4_buf_en),
        .data_in(do_layer3),
        .clear(temp_wr_en_layer4_1),
        
        .wr_temp_en(temp_wr_en_layer3),
        .wr_temp_en_1(temp_wr_en_layer3_1),
        .temp_bram_index(x4_buf_addr),
        .data_out(x4_buf_data)
    );
    
   layer4 layer4_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(temp_wr_en_layer3_1),
    .cnt(cnt),
    .x4_buf_data(x4_buf_data),
    
    .x4_buf_addr(x4_buf_addr),
    .x4_buf_en(x4_buf_en),
    
    .temp_wr_en_layer4(temp_wr_en_layer4),
    .temp_wr_en_layer4_1(temp_wr_en_layer4_1),
    
    .do_layer4(do_layer4),
    .done_o()
    );
    // Instance of temp_bram
    temp_bram_half #(
        .MAC_CNT(16),
        .DATA_WIDTH(8)
    ) layer4_temp_bram (
        .clk_i(clk_i),
        .rstn_i(rstn_i),         // layer2 cal done -> clear
        .rd_temp_en(x5_buf_en),
        .data_in(do_layer4),
        .clear(done_5),
        
        .wr_temp_en(temp_wr_en_layer4),
        .wr_temp_en_1(temp_wr_en_layer4_1),
        .temp_bram_index(x5_buf_addr),
        .data_out(x5_buf_data)
    );
    
   layer5 layer5_inst(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .cnt(cnt),
    .start_i(temp_wr_en_layer4_1),
    .x5_buf_data(x5_buf_data),
    
    .x5_buf_addr(x5_buf_addr),
    .x5_buf_en(x5_buf_en),
    
    .do_layer5(do_layer5),
    .temp_wr_en_layer5(temp_wr_en_layer5),
    .done_o(done_5)
    );
    
    temp_buf temp_buf(
        .clk(clk_i),
        .rst_n(rstn_i),
        .temp_buf_en(y_buf_en),
        .data_in(do_layer5),
        .buf_wr_start(temp_wr_en_layer5),
        .buf_wr_en(y_buf_wr_en),
        .temp_buf_addr(y_buf_addr),
        .temp_buf_data(y_buf_data),
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
module layer2(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    input   wire    [12:0]          cnt,

    input   wire    [7:0]           layer1_data,

    input   wire                    temp_rd_en,         // for layer 3 calc.
    input   wire    [5:0]           temp_rd_addr,       // for layer 3 calc.
    input   wire                    temp_clear,
    
    
    output  wire                    layer1_buf_en,
    output  wire    [6:0]           layer1_buf_addr,
    output  wire                    layer1_temp_clear,
    
    output  wire    [7:0]           data_o
    );

    // layer 2 Weight
    wire    [7:0]           w2_buf_addr;
    wire                    w2_buf_en;
    wire    [8*32-1:0]      w2_buf_data;
    
    wire    mac_clear;
    
    wire    pu_en2, done_2, relu_en_2, temp_start;
    wire    [5:0]           temp_wr_addr;
    wire    temp_wr_en;
    wire    [7:0]           pu_data;
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    ///////////////     LAYER 2
   local_ctrl_layer2 layer2_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .temp_start_i(temp_start),
        .cnt(cnt),
        .w_addr_o(w2_buf_addr),
        .w_en_o(w2_buf_en),
        .x_addr_o(layer1_buf_addr),
        .x_en_o(layer1_buf_en),
        .mac_en_o(pu_en2),
        .relu_en_o(relu_en_2),
        .temp_wr_addr_o(temp_wr_addr),
        .temp_wr_en_o(temp_wr_en),
        .layer1_temp_clear_o(layer1_temp_clear),
        .mac_clear(mac_clear),
        .done_o()
    );
    
    pu #(
        .COEFF(17'b0_0000_0000_1101_1100),
        .DATA_WIDTH(8),
        .MAC_NUM(32)
    ) PU_2 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .mac_en_i(pu_en2),
        
        .relu_en_i(relu_en_2),
        
        .din_i(layer1_data), 
        .win_i(w2_buf_data),
        .temp_start(temp_start),
        .done_o(),
        .data_o(pu_data)     
    );
   
    // Instance of temp_bram
    temp_bram #(
        .MAC_CNT(64),
        .DATA_WIDTH(8)
    ) layer2_temp_bram (
        .clk_i(clk_i),
        .rstn_i(rstn_i),         // layer2 cal done -> clear
        .rd_temp_en(temp_rd_en),
        .data_in(pu_data),
        .clear(temp_clear),
        
        .wr_temp_en(temp_wr_en),
        .temp_wr_addr(temp_wr_addr),
        .temp_rd_addr(temp_rd_addr),
        .data_out(data_o)
    );
    
    
    single_port_bram  #(
        .WIDTH(256),       // 8*32
        .DEPTH(256),
        .INIT_FILE("C:/try2/w2_buffer.txt")
    ) w2_buf (
        .clk(clk_i),
        .en(w2_buf_en),
        .wen(),
        .addr(w2_buf_addr),
        .din(),
        .dout(w2_buf_data)
    );
    
    
endmodule
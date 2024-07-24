module layer4(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    input   wire    [12:0]          cnt,

    input   wire    [7:0]           layer3_data,
    
    input   wire    [5:0]           temp_rd_addr,       // for layer 4 calc.
    input   wire                    temp_rd_en,         // for layer 4 calc.
    input   wire                    temp_clear,

    output  wire                    layer3_buf_en,
    output  wire    [6:0]           layer3_buf_addr,
    output  wire                    layer3_temp_clear,
    
    output  wire    [7:0]           data_o
    );

    // layer 4 Weight
    wire    [6:0]           w4_buf_addr;
    wire                    w4_buf_en;
    wire    [8*16-1:0]      w4_buf_data;
    wire    mac_clear;
    wire    pu_en4, done_4, relu_en_4;

    wire    [5:0]           temp_wr_addr;
    wire    temp_wr_en, temp_start;
    wire    [7:0]           pu_data;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    ///////////////     LAYER 4

    local_ctrl_layer4 layer4_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .temp_start_i(temp_start),
        .cnt(cnt),
        
        .w_addr_o(w4_buf_addr),
        .w_en_o(w4_buf_en),
        .x_addr_o(layer3_buf_addr),
        .x_en_o(layer3_buf_en),
        
        .mac_en_o(pu_en4),
        .relu_en_o(relu_en_4),

        .temp_wr_addr_o(temp_wr_addr),
        .temp_wr_en_o(temp_wr_en),
        .layer3_temp_clear_o(layer3_temp_clear),
        .mac_clear(mac_clear),
        .done_o()
    );
    
    pu #(
        .COEFF(17'b0_0000_0001_0101_1111),
        .DATA_WIDTH(8),
        .MAC_NUM(16)
    ) PU_4 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .temp_start(temp_start),
        
        .mac_en_i(pu_en4),
        .relu_en_i(relu_en_4),
        
        .din_i(layer3_data), 
        .win_i(w4_buf_data),
        
        
        .data_o(pu_data)      
    );
   
    // Instance of temp_bram
    temp_bram #(
        .MAC_CNT(32),
        .DATA_WIDTH(8)
    ) layer4_temp_bram (
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
        .WIDTH(128),       // 8*16
        .DEPTH(128),
        .INIT_FILE("C:/data/w4_buffer.txt")
    ) w4_buf (
        .clk(clk_i),
        .en(w4_buf_en),
        .wen(),
        .addr(w4_buf_addr),
        .din(),
        .dout(w4_buf_data)
    );
    
endmodule
module layer3(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    input   wire    [12:0]          cnt,
    input   wire    [7:0]           x3_buf_data,
    
    output  wire    [5:0]           x3_buf_addr,
    output  wire                    x3_buf_en,
    output  wire                    temp_wr_en_layer3,
    output  wire                    temp_wr_en_layer3_1,
    
    output  wire    [32*8-1:0]      do_layer3,
    output  wire                    done_o
    );
    
     // layer 3 Weight
    wire    [7:0]           w3_buf_addr;
    wire                    w3_buf_en;
    wire    [8*32-1:0]      w3_buf_data;
    wire    mac_clear;
    wire    pu_en3, done_3, relu_en_3;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    ///////////////     LAYER 3
   local_ctrl_layer3 layer3_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .cnt(cnt),
        .w_addr_o(w3_buf_addr),
        .w_en_o(w3_buf_en),
        .x_addr_o(x3_buf_addr),
        .x_en_o(x3_buf_en),
        .mac_en_o(pu_en3),
        .relu_en_o(relu_en_3),
        .temp_wr_en(temp_wr_en_layer3),
        .temp_wr_en_1(temp_wr_en_layer3_1),
        .mac_clear(mac_clear),
        .done_o()
    );
    
    pu #(
        .COEFF(17'b0_0000_0001_1010_0001),
        .DATA_WIDTH(8),
        .MAC_CNT(32)
    ) PU_3 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        
        .mac_en_i(pu_en3),
        .relu_en_i(relu_en_3),
          
        .mac_clear(mac_clear),
        .din_i(x3_buf_data), // 첫 32-bit만 사용
        .win_i(w3_buf_data),
        
        .matmul_o(do_layer3)       // 행렬 연산 결과
    );
   

    
    
    single_port_bram  #(
        .WIDTH(256),       // 8*32
        .DEPTH(128),
        .INIT_FILE("C:/try2/w3_buffer.txt")
    ) w3_buf (
        .clk(clk_i),
        .en(w3_buf_en),
        .wen(),
        .addr(w3_buf_addr),
        .din(),
        .dout(w3_buf_data)
    );
    
endmodule
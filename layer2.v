module layer2(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    input   wire    [12:0]          cnt,
    
    input   wire    [7:0]           x2_buf_data,
    
    output  wire    [6:0]           x2_buf_addr,
    output  wire                    x2_buf_en,
    output  wire                    temp_wr_en_layer2,
    output  wire                    temp_wr_en_layer2_1,
    
    output  wire    [32*8-1:0]      do_layer2,
    output  wire                    done_o
    );

    // layer 2 Weight
    wire    [7:0]           w2_buf_addr;
    wire                    w2_buf_en;
    wire    [8*32-1:0]      w2_buf_data;
    
    wire    mac_clear;
    
    wire    pu_en2, done_2, relu_en_2;
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    ///////////////     LAYER 2
   local_ctrl_layer2 layer2_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .cnt(cnt),
        .w_addr_o(w2_buf_addr),
        .w_en_o(w2_buf_en),
        .x_addr_o(x2_buf_addr),
        .x_en_o(x2_buf_en),
        .mac_en_o(pu_en2),
        .relu_en_o(relu_en_2),
        .temp_wr_en(temp_wr_en_layer2),
        .temp_wr_en_1(temp_wr_en_layer2_1),
        .mac_clear(mac_clear),
        .done_o()
    );
    
    pu #(
        .COEFF(17'b0_0000_0000_1101_1100),
        .DATA_WIDTH(8),
        .MAC_CNT(32)
    ) PU_2 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .mac_en_i(pu_en2),
        
        .mac_clear(mac_clear),
        .relu_en_i(relu_en_2),       
        
        .din_i(x2_buf_data), // 첫 32-bit만 사용
        .win_i(w2_buf_data),
        
        .matmul_o(do_layer2)       // 행렬 연산 결과
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
module layer4(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    input   wire    [7:0]           x4_buf_data,
    input   wire    [12:0]          cnt,
    
    output  wire    [5:0]           x4_buf_addr,
    output  wire                    x4_buf_en,
    output  wire                    temp_wr_en_layer4,
    output  wire                    temp_wr_en_layer4_1,
    
    output  wire    [16*8-1:0]      do_layer4,
    output  wire                    done_o
    );

    // layer 4 Weight
    wire    [6:0]           w4_buf_addr;
    wire                    w4_buf_en;
    wire    [8*16-1:0]      w4_buf_data;
    wire    mac_clear;
    wire    pu_en4, done_4, relu_en_4;
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    ///////////////     LAYER 4
   local_ctrl_layer4 layer4_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .cnt(cnt),
        .w_addr_o(w4_buf_addr),
        .w_en_o(w4_buf_en),
        .x_addr_o(x4_buf_addr),
        .x_en_o(x4_buf_en),
        .mac_en_o(pu_en4),
        .relu_en_o(relu_en_4),
        .temp_wr_en(temp_wr_en_layer4),
        .temp_wr_en_1(temp_wr_en_layer4_1),
        .mac_clear(mac_clear),
        .done_o()
    );
    
    pu #(
        .COEFF(17'b0_0000_0001_0101_1111),
        .DATA_WIDTH(8),
        .MAC_CNT(16)
    ) PU_4 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        
        .mac_en_i(pu_en4),
        .relu_en_i(relu_en_4),
        .mac_clear(mac_clear),
        
        .din_i(x4_buf_data), // 첫 32-bit만 사용
        .win_i(w4_buf_data),
        
        .matmul_o(do_layer4)       // 행렬 연산 결과
    );
   
    single_port_bram  #(
        .WIDTH(128),       // 8*16
        .DEPTH(128),
        .INIT_FILE("C:/try2/w4_buffer.txt")
    ) w4_buf (
        .clk(clk_i),
        .en(w4_buf_en),
        .wen(),
        .addr(w4_buf_addr),
        .din(),
        .dout(w4_buf_data)
    );
    
endmodule
`timescale 1ns / 1ps

module layer1(
    input   wire                    clk_i,
    input   wire                    rstn_i,
    input   wire                    start_i,
    
    output  wire    [128*8-1:0]     do_layer1,
    output  wire    [12:0]          cnt_o,
    output  wire                    temp_wr_en,
    output  wire                    done_o
    );
    
    // image data 
    wire    [12:0]          x_buf_addr;
    wire                    x_buf_en;
    wire    [7:0]           x_buf_data;
    
    // layer 1 Weight
    wire    [9:0]           w1_buf_addr;
    wire                    w1_buf_en;
    wire    [8*128-1:0]     w1_buf_data;
    
    // layer result wire variable
    
    wire    pu_en1, relu_en_i;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    // image input data pre-processing 
    reg [32:0] x_input_data;
    wire [7:0] din;
    
    always @(*) begin
        if(!rstn_i) begin
            x_input_data <= 0;
        end
        else begin
            x_input_data <= x_buf_data[7] ? ({x_buf_data,16'b0 }>> 1) + 33'h1FFF_FFFF_F : ({x_buf_data,16'b0 } >> 1) + 33'h0000_0000_1;
        end
    end
    assign  din = (x_input_data[31:16] > 8'hff) ?  8'hff : (x_input_data[31:16] < 8'h00 ) ? 0 : x_input_data[23:16];
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////
    /////////////////// PU and Local Ctrl inst
    
    local_ctrl_layer1 layer1_ctrl(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .start_i(start_i),
        .w_addr_o(w1_buf_addr),
        .w_en_o(w1_buf_en),
        .x_addr_o(x_buf_addr),
        .x_en_o(x_buf_en),
        .mac_en_o(pu_en1),
        .relu_en_o(relu_en_i),
        .cnt_o(cnt_o),
        .done_o(done_o)
    );
    
    pu #(
        .COEFF(17'b0_0000_0000_0010_0110),
        .DATA_WIDTH(8),
        .MAC_CNT(128)
    ) PU_1 (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .mac_en_i(pu_en1),
        .relu_en_i(relu_en_i),    
        
        .din_i(din), // ù 32-bit�� ���
        .win_i(w1_buf_data),
        
        .done_o(temp_wr_en),
        .matmul_o(do_layer1)       // ��� ���� ���
    );
   
       
    single_port_bram  #(
        .WIDTH(8),
        .DEPTH(7840),
        .INIT_FILE("C:/try2/imgrom10out.txt")
    ) x_buf (
        .clk(clk_i),
        .en(x_buf_en),
        .wen(),
        .addr(x_buf_addr),
        .din(),
        .dout(x_buf_data)
    );

    single_port_bram  #(
        .WIDTH(1024),       // 8*128
        .DEPTH(784),
        .INIT_FILE("C:/try2/int8_layer1_hex_re.txt")
    ) w1_buf (
        .clk(clk_i),
        .en(w1_buf_en),
        .wen(),
        .addr(w1_buf_addr),
        .din(),
        .dout(w1_buf_data)
    );
    
endmodule

module temp_bram_half #(
    parameter MAC_CNT = 32,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(MAC_CNT*2)
)(
    input wire clk_i,
    input wire rstn_i ,
    input wire rd_temp_en,              // Read_enable
    input wire [DATA_WIDTH * MAC_CNT-1:0] data_in,  // Data input (concated data)
    input wire wr_temp_en,
    input wire wr_temp_en_1,
    input wire clear,
    
    input wire [ADDR_WIDTH-1:0] temp_bram_index,
    output reg [DATA_WIDTH-1:0] data_out  // Data output
);
    // Internal BRAM storage
    reg [DATA_WIDTH-1:0] bram [0:MAC_CNT*2-1];
    integer i;
    
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            for (i = 0; i < MAC_CNT*2; i = i + 1) begin
                bram[i] <= {DATA_WIDTH{1'b0}};
            end
            data_out <= {DATA_WIDTH{1'b0}};
        end 
        else if (wr_temp_en) begin
            for (i = 0; i < MAC_CNT; i = i + 1) begin
                bram[i] <= data_in[DATA_WIDTH * (MAC_CNT - 1 - i + 1) - 1 -: DATA_WIDTH];
            end
        end
        else if (wr_temp_en_1) begin
            for (i = 0; i < MAC_CNT; i = i + 1) begin
                bram[i + MAC_CNT] <= data_in[DATA_WIDTH*(MAC_CNT - 1 - i + 1) -1 -: DATA_WIDTH];
            end
        end else if (clear) begin
            for (i = 0; i < MAC_CNT; i = i + 1) begin
                bram[i] <= {DATA_WIDTH{1'b0}};
            end
        end 
        else if (rd_temp_en) begin 
            data_out <= bram[temp_bram_index]; 
        end else begin
            data_out <= 0;
        end
    end

endmodule

module temp_bram #(
    parameter MAC_CNT = 128,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(MAC_CNT)
)(
    input wire clk_i,
    input wire rstn_i ,
    input wire rd_temp_en,              // Read_enable
    input wire wr_temp_en,
    input wire [ADDR_WIDTH-1:0] temp_wr_addr,
    input wire [ADDR_WIDTH-1:0] temp_rd_addr,
    input wire clear,    
    
    input wire [DATA_WIDTH-1:0] data_in,  // Data input (concated data)

    output reg [DATA_WIDTH-1:0] data_out  // Data output
);
    // Internal BRAM storage
    reg [DATA_WIDTH-1:0] bram [0:MAC_CNT-1];
    integer i;

    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            for (i = 0; i < MAC_CNT; i = i + 1) begin
                bram[i] <= {DATA_WIDTH{1'b0}};
            end
            data_out <= {DATA_WIDTH{1'b0}};
        end 
        else if (wr_temp_en) begin
            bram[temp_wr_addr] <= data_in;
        end
        else if (rd_temp_en) begin 
            data_out <= bram[temp_rd_addr]; 
        end else if (clear) begin
            for (i = 0; i < MAC_CNT; i = i + 1) begin
                bram[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            data_out <= 0;
        end
    end

endmodule

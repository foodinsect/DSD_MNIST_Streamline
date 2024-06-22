
module temp_buf #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input   wire clk,
    input   wire rst_n,
    input   wire buf_wr_start,
    input   wire [32*10-1:0] data_in, 

    output  wire [ADDR_WIDTH-1:0] temp_buf_addr,
    output  wire [DATA_WIDTH-1:0] temp_buf_data,
    output  wire temp_buf_en,
    output  wire temp_buf_done
);


wire [31:0] acc_data[0:9]; 

assign acc_data[9] = data_in[31:0];
assign acc_data[8] = data_in[63:32];
assign acc_data[7] = data_in[95:64];
assign acc_data[6] = data_in[127:96];
assign acc_data[5] = data_in[159:128];
assign acc_data[4] = data_in[191:160];
assign acc_data[3] = data_in[223:192];
assign acc_data[2] = data_in[255:224];
assign acc_data[1] = data_in[287:256];
assign acc_data[0] = data_in[319:288];

integer i;
reg [9:0] en_pipeline;
reg [31:0] y_data_buffer[0:9];
assign temp_buf_data = y_data_buffer[0];
assign temp_buf_done = en_pipeline[9];

always @(posedge clk) begin
    if (!rst_n) begin
        en_pipeline <= 10'b0;
    end else begin
        en_pipeline[0] <= buf_wr_start;
        en_pipeline[9:1] <= en_pipeline[8:0];
    end

    if (buf_wr_start) begin
        for (i = 0; i < 10; i = i + 1) begin
            y_data_buffer[i] <= acc_data[i];
        end
    end else begin
        for (i = 0; i < 9; i = i + 1) begin
            y_data_buffer[i] <= y_data_buffer[i + 1];
        end
        y_data_buffer[9] <= 32'd0;
    end
end

reg buf_addr_cnt;
reg [ADDR_WIDTH-1:0] buf_addr;

assign temp_buf_en = buf_addr_cnt;
assign temp_buf_addr = buf_addr;

always @(posedge clk) begin
    if(!rst_n) begin
        buf_addr_cnt <= 1'b0;
        buf_addr <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        if(buf_wr_start) buf_addr_cnt <=  1'b1;
        else begin
            if(en_pipeline[9]) buf_addr_cnt <= 1'b0;
        end

        if(buf_addr_cnt) begin
            buf_addr <= buf_addr + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
        end
    end
end

endmodule

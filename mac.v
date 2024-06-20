
module mac #(
    parameter COEFF = 17'b0_0000_0000_0010_0101
)(
    input   wire                clk_i,
    input   wire                rstn_i,
    
    input   wire                mac_en,
    input   wire                acc_en,        //2 pipeline delay
    input   wire                relu_en,        //0 pipeline delay
    input   wire                qdq_en,        //0 pipeline delay
    input   wire                round_en,        //0 pipeline delay
    input   wire                sat_en,        //0 pipeline delay

    input   wire                mac_clear,
    input   wire signed [7:0]   image_data,     //image data 8bit
    input   wire signed [7:0]   weight_data,    //weights data 8bit

    output  wire signed [7:0]   dsp_output_o 
);


reg signed  [7:0]   result;
reg signed  [16:0]  op1;
reg signed  [23:0]  op2;
(* use_dsp = "yes" *) reg signed  [40:0]  mul;
(* use_dsp = "yes" *) reg signed  [40:0]  acc;

assign  dsp_output_o = result;

always @(posedge clk_i) begin
    if(!rstn_i) begin
        op1 <= 17'sd0;
        op2 <= 24'sd0;
        acc <= 41'sd0;
        result <= 8'sd0;
    end
    else begin
        if (mac_en) begin 
            op1 <= weight_data;
            op2 <= image_data;
        end else if (qdq_en) begin
            op1 <= COEFF; 
            op2 <= acc;
        end
        
        mul <= op1 * op2; 
        
        if (acc_en) begin
            acc <= acc + mul;
        end else if (relu_en) begin
            acc <= acc[40] ? 41'sd0 : acc; // 음수일 경우 0으로 설정
        end else if (round_en) begin
            acc <= mul[23:16] + mul[15];
        end else if (mac_clear) begin
            acc <= 41'sd0;
        end
        
        // Saturation
        if (sat_en) begin
            if (acc[7:0] > 8'h7F) result <= 8'h7F;
            else result <= acc[7:0];
        end
    end
end

endmodule

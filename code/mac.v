
module mac (
    input   wire                clk_i,
    input   wire                rstn_i,
    
    input   wire                acc_en,        
    input   wire                relu_en,        
    input   wire                mac_clear,
    
    input   wire signed [7:0]   image_data,     //image data 8bit
    input   wire signed [7:0]   weight_data,    //weights data 8bit

    output  wire signed [31:0]   dsp_output_o 
);

reg signed  [7:0]  op1;
reg signed  [7:0]  op2;
(* use_dsp = "yes" *) reg signed  [40:0]  mul;
(* use_dsp = "yes" *) reg signed  [40:0]  acc;

assign  dsp_output_o = acc;

always @(posedge clk_i) begin
    if(!rstn_i) begin
        op1 <= 8'h0;
        op2 <= 8'h0;
        acc <= 41'h0;
    end
    else begin
        op1 <= weight_data;
        op2 <= image_data;
        
        mul <= op1 * op2; 
        
        if (acc_en) begin
            acc <= acc + mul;
        end else if(relu_en) begin
            acc <= acc[40] ? 41'sd0 : acc;
        end else if (mac_clear) begin
            acc <= 0; 
        end 
    end
end

endmodule

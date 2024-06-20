module mac2 (
    input   wire                clk_i,
    input   wire                rstn_i,
    
    input   wire                mac_en,
    input   wire                valid_i,        //0 pipeline delay
    input   wire                mac_clear,
    input   wire signed [7:0]   image_data,     //image data 8bit
    input   wire signed [7:0]   weight_data,    //weights data 8bit

    output  wire signed [31:0]   dsp_output_o 
);

reg     [1:0] acc_en_delay;
reg     [1:0] valid_delay;

reg     [31:0]       result;
reg signed  [16:0]  op1;
reg signed  [23:0]  op2;

(* use_dsp = "yes" *) reg signed  [40:0]  mul;
(* use_dsp = "yes" *) reg signed  [40:0]  acc;

assign  dsp_output_o = result;

//  control_delay[0]    => q/dq en signal
//  control_delay[1];   => round en signal
//  control_delay[2];   => saturation en signal

always @(posedge clk_i) begin
    if (!rstn_i) begin
        acc_en_delay <= 2'b0;
        valid_delay <= 2'b0;
    end else begin
        acc_en_delay[0] <= mac_en;
        acc_en_delay[1] <= acc_en_delay[0];
        valid_delay[0] <= valid_i;
        valid_delay[1] <= valid_delay[0];
    end
end

always @(posedge clk_i) begin
    if(!rstn_i) begin
        op1 <= 17'sd0;
        op2 <= 24'sd0;
        acc <= 41'sd0;
        result <= 32'sd0;
    end
    else begin
        if (mac_en) begin 
            op1 <= weight_data;
            op2 <= image_data;
        end else begin
            op1 <= 0; 
            op2 <= 0;
        end
        
        mul <= op1 * op2; 
        
        if (acc_en_delay[1]) begin
            acc <= acc + mul;
        end else if (valid_delay[1]) begin
            result <= acc; // 음수일 경우 0으로 설정
        end else if (mac_clear) begin
            acc <= 41'sd0;
            result <= 32'sd0;
        end else begin
            result <= 32'sd0;
        end
        
    end
end

endmodule

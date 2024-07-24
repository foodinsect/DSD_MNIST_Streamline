`timescale 1ns / 1ps
module local_ctrl_layer1(
input wire              clk_i,
input wire              rstn_i,
input wire              start_i,
input wire              temp_start_i,

output wire     [9:0]   w_addr_o,
output wire             w_en_o,
output wire     [12:0]  x_addr_o,
output wire             x_en_o,
output wire             mac_en_o,
output wire             relu_en_o,
output wire     [12:0]  cnt_o,

output wire     [9:0]   temp_addr_o,
output wire             temp_wr_en_o,
output wire             done_o
);

reg     [2:0]   present_state;
reg     [2:0]   next_state;

reg     [9:0]   cnt_mac;
reg     [12:0]  cnt;
reg             done;

reg     [9:0]   w_addr;
reg             w_en;

reg     [12:0]   x_addr;
reg             x_en;

reg             mac_en;
reg             relu;
reg     [1:0]   relu_delay;

reg     [9:0]   temp_addr; 
reg             temp_wr_en;

localparam   IDLE    =   3'b000;
localparam   RUN     =   3'b001;
localparam   SAVE    =   3'b011;
localparam   RE      =   3'b100;
localparam   DONE    =   3'b101;

assign  done_o = done;

assign  w_addr_o    =   w_addr;
assign  w_en_o      =   w_en;

assign  x_addr_o    =   x_addr;
assign  x_en_o      =   x_en;

assign  mac_en_o    =   mac_en;
assign  relu_en_o   =   relu_delay[1];
assign  cnt_o       =   cnt;
assign  temp_wr_en_o   =   temp_wr_en;
assign  temp_addr_o    =   temp_addr;

//present_state
always @(posedge clk_i) begin
    if (!rstn_i) begin
        present_state   <=  IDLE;
    end
    else begin
        present_state   <=  next_state;
    end
end


//next_state
always @(*) begin
    case (present_state)
        IDLE : begin
            if (start_i) begin
                next_state = RUN;
            end
            else begin
                next_state = IDLE;
            end
        end
        RUN :   begin
            if (cnt_mac == 784) begin
                next_state  =   SAVE;
            end
            else begin
                next_state  =   RUN;
            end
        end
        SAVE :   begin
            if (cnt_mac == 4) begin
                next_state  =   RE;
            end
            else begin
                next_state  =   SAVE;
            end
        end
        RE :   begin
            if (cnt == 7879) begin
                next_state  =   DONE;
            end
            else begin
                next_state  =   RUN;
            end
        end
        DONE : begin
            next_state  =   DONE;
        end
        default : begin
            next_state  =   IDLE;
        end
    endcase
end


//
always @(posedge clk_i) begin
    if (!rstn_i) begin
        cnt_mac <=  0;
        cnt     <=  0;
        done    <=  0;
        w_addr  <=  0;
        w_en    <=  0;
        x_addr  <=  0;
        x_en    <=  0;
        mac_en  <=  0;
        relu   <=  0;
    end
    else begin
        case (present_state)
        IDLE    :   begin
            cnt_mac <=  0;
            cnt     <=  0;
            done    <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            relu   <=  0;
        end
        RUN     :   begin
            if (cnt_mac == 784) begin
                done    <=  0;
                cnt_mac <=  0;
                cnt     <=  cnt;
                w_addr  <=  w_addr;
                w_en    <=  0;
                x_addr  <=  x_addr;
                x_en    <=  0;
                mac_en  <=  0;
                relu   <=  1;
            end
            else begin
                done    <=  0;
                
                if (x_en && w_en) begin
                    mac_en  <=  1;
                    cnt_mac <=  cnt_mac + 1; 
                    if (cnt_mac == 783) begin
                        cnt     <=  cnt;
                        x_addr  <=  x_addr;
                        w_addr  <=  w_addr;
                    end
                    else begin
                        cnt   <=  cnt + 1;
                        x_addr <= x_addr + 1;
                        w_addr <= w_addr + 1;
                    end
                end
                else begin
                    x_addr  <=  x_addr;
                    w_addr  <=  0;
                    mac_en  <=  0;
                    cnt_mac <=  0;
                end

                if (cnt_mac == 783) begin
                    x_en <= 0;
                    w_en <= 0;
                end
                else begin
                    x_en <= 1;
                    w_en <= 1;
                end


            end
        end
        SAVE    :   begin
            if (cnt_mac == 4) begin
                done    <=  0;
                cnt_mac <=  0;
                cnt     <=  cnt;
                w_addr  <=  0;
                w_en    <=  0;
                x_addr  <=  x_addr;
                x_en    <=  0;
                mac_en  <=  0;
                relu   <=  0;
            end 
            else begin
                done    <=  0;
                relu   <=  0;
                cnt    <=  cnt + 1;
                cnt_mac <=  cnt_mac + 1;
                
            end
        end
        RE      :   begin
            cnt_mac <=  0;
            done    <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  x_addr + 1;
            x_en    <=  0;
            mac_en  <=  0;
            relu   <=  0;
    
            if (cnt == 7879) begin
                done    <=  1;  
                cnt <= cnt;
            end else begin
                cnt <= cnt + 1;
            end
        end
        DONE    :   begin
            done    <=  0;
            cnt     <=  0;
            cnt_mac <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            relu   <=  0;
        end
        default :   begin
            cnt_mac <=  0;
            done    <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            cnt     <=  0;
            relu   <=  0;
        end
        endcase
    end
end

always @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
        relu_delay <= 2'b0;
    end
    else begin
        relu_delay[0] <= relu;
        relu_delay[1] <= relu_delay[0];
    end
end

always @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
        temp_wr_en <= 0;
        temp_addr <= 0;
    end
    else begin
        if(temp_start_i) begin
            temp_wr_en <= 1;
        end
        if (temp_wr_en) begin
            temp_addr <= temp_addr + 1;
        end
        if (temp_addr == 127) begin
            temp_wr_en <= 0;
            temp_addr <= 0;
        end
    end
end

endmodule
`timescale 1ns / 1ps
module local_ctrl_layer5(
input wire              clk_i,
input wire              rstn_i,
input wire              start_i,
input wire      [12:0]  cnt,

output wire     [5:0]   w_addr_o,
output wire             w_en_o,
output wire     [4:0]   x_addr_o,
output wire             x_en_o,
output wire             mac_en_o,
output wire             mac_valid,
output wire             mac_clear,

output wire             temp_wr_o,
output wire             done_o
);

reg     [2:0]   present_state;
reg     [2:0]   next_state;

reg     [9:0]   cnt_mac;
reg             done;

reg     [5:0]   w_addr;
reg             w_en;

reg     [4:0]   x_addr;
reg             x_en;

reg             temp_wr;
reg             mac_en;
reg             valid;
reg             clear;

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
assign  mac_valid   =   valid;
assign  mac_clear = clear;

assign  temp_wr_o = temp_wr;

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
            if (cnt_mac == 32) begin
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
                next_state  =   IDLE;
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
        done    <=  0;
        w_addr  <=  0;
        w_en    <=  0;
        x_addr  <=  0;
        temp_wr <=  0;
        x_en    <=  0;
        mac_en  <=  0;
        clear   <=  0;
        valid   <=  0;
    end
    else begin
        case (present_state)
        IDLE    :   begin
            cnt_mac <=  0;
            done    <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            clear   <=  0;
            temp_wr <=  0;
            x_addr  <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            valid   <=  0;
        end
        RUN     :   begin
            if (cnt_mac == 32) begin
                done    <=  1;
                cnt_mac <=  0;
                w_addr  <=  0;
                temp_wr <=  0;
                w_en    <=  0;
                x_addr  <=  0;
                x_en    <=  0;
                mac_en  <=  0;
                valid   <=  1;
            end
            else begin
                done    <=  0;

                if (x_en && w_en) begin
                    mac_en  <=  1;
                    cnt_mac <=  cnt_mac + 1;
                    if (cnt_mac == 0) begin
                        clear   <=  1;
                    end
                    else if (cnt_mac == 31) begin
                        x_addr  <=  x_addr;
                        w_addr  <=  w_addr;
                    end
                    else begin
                        clear   <=  0;
                        x_addr <= x_addr + 1;
                        w_addr <= w_addr + 1;
                    end
                end
                else begin
                    clear   <=  0;
                    x_addr  <=  0;
                    w_addr  <=  0;
                    mac_en  <=  0;
                    cnt_mac <=  0;
                end

                if (cnt_mac == 31) begin
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
                w_addr  <=  0;
                w_en    <=  0;
                x_addr  <=  0;
                x_en    <=  0;
                temp_wr <=  0;
                mac_en  <=  0;
                valid   <=  0;
            end
            else begin
                done    <=  0;
                valid   <=  0;
                cnt_mac <=  cnt_mac + 1;
                if (cnt_mac == 2) begin
                    temp_wr <=  1;
                end else begin
                    temp_wr <=  0;
                end
            end
        end
        RE      :   begin
            cnt_mac <=  0;
            done    <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  0;
            temp_wr <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            valid   <=  0;
    
            if (cnt == 7879) begin
                done    <=  1;  
            end else begin
                done    <=  0;  
            end
        end
        DONE    :   begin
            done    <=  0;
            cnt_mac <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            valid   <=  0;
        end
        default :   begin
            cnt_mac <=  0;
            done    <=  0;
            w_addr  <=  0;
            w_en    <=  0;
            x_addr  <=  0;
            x_en    <=  0;
            mac_en  <=  0;
            valid   <=  0;
        end
        endcase
    end
end
endmodule
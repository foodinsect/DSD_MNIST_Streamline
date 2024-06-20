module clock_divider(
    input wire clk_i,   // 125 MHz 입력 클럭
    input wire rstn_i,    // 리셋 신호
    output reg clk_out   // 100 MHz 출력 클럭
);

reg [2:0] counter; // 3비트 카운터 (0~4까지 카운트)

always @(posedge clk_i or posedge rstn_i) begin
    if (rstn_i) begin
        counter <= 3'b0; // 카운터를 0으로 초기화
        clk_out <= 1'b0; // 출력 클럭도 0으로 초기화
    end else begin
        if (counter == 3'd4) begin
            counter <= 3'b0; // 카운터가 4에 도달하면 0으로 초기화
            clk_out <= ~clk_out; // 출력 클럭 반전
        end else begin
            counter <= counter + 1; // 카운터 증가
        end
    end
end

endmodule

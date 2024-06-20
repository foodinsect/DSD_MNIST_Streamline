module clock_divider(
    input wire clk_i,   // 125 MHz �Է� Ŭ��
    input wire rstn_i,    // ���� ��ȣ
    output reg clk_out   // 100 MHz ��� Ŭ��
);

reg [2:0] counter; // 3��Ʈ ī���� (0~4���� ī��Ʈ)

always @(posedge clk_i or posedge rstn_i) begin
    if (rstn_i) begin
        counter <= 3'b0; // ī���͸� 0���� �ʱ�ȭ
        clk_out <= 1'b0; // ��� Ŭ���� 0���� �ʱ�ȭ
    end else begin
        if (counter == 3'd4) begin
            counter <= 3'b0; // ī���Ͱ� 4�� �����ϸ� 0���� �ʱ�ȭ
            clk_out <= ~clk_out; // ��� Ŭ�� ����
        end else begin
            counter <= counter + 1; // ī���� ����
        end
    end
end

endmodule

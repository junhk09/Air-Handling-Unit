module tick_gen #(
    parameter Tick_Hz = 1  // 외부에서 변경 가능한 파라미터
)(
    input clk,
    input reset,
    output reg tick
);

    // 내부에서만 사용하는 값은 localparam으로 선언
    localparam CLK_FREQ = 100_000_000;
    localparam MAX_COUNT = CLK_FREQ / Tick_Hz;

    reg [31:0] count;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count <= 0;
            tick <= 0;
        end else begin
            if(count >= (MAX_COUNT - 1)) begin
                count <= 0;
                tick <= 1;
            end else begin
                count <= count + 1;
                tick <= 0;
            end
        end
    end
endmodule
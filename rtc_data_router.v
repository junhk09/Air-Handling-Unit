module rtc_data_router(
    input clk, reset,
    input rtc_load_uart, rtc_load_manual,
    input [63:0] rtc_set_data_uart,
    input [7:0] y, m, d, s,
    input [7:0] h_selected, min_selected,
    output reg [63:0] r_rtc_final_data,
    output o_rtc_load_final
);
    // 수동 설정 데이터 팩킹
    wire [63:0] w_manual_pack = {y, 8'h00, m, d, h_selected, min_selected, s};

    always @(posedge clk or posedge reset) begin
        if(reset) r_rtc_final_data <= 64'd0;
        else if (rtc_load_uart)   r_rtc_final_data <= rtc_set_data_uart;
        else if (rtc_load_manual) r_rtc_final_data <= w_manual_pack;
    end

    // 타이밍 지연 로드 신호
    reg r_load_uart_d, r_load_manual_d;
    always @(posedge clk) begin
        r_load_uart_d   <= rtc_load_uart;
        r_load_manual_d <= rtc_load_manual;
    end
    assign o_rtc_load_final = r_load_uart_d | r_load_manual_d;
endmodule
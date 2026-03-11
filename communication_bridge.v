module communication_bridge(
    input clk,
    input reset,
    
    // 외부 하드웨어 핀
    input RsRx,
    output RsTx,
    
    // 시스템 데이터 입력 (PC로 전송할 데이터)
    input [7:0] y, m, d, h, min, s, temp, humi,
    
    // RTC 설정 출력 (PC로부터 수신한 데이터)
    output [63:0] rtc_uart_data,
    output rtc_load_uart
);

    // 내부 신호망 (Internal Wires)
    wire [7:0] rx_data;
    wire rx_done;
    wire [7:0] tx_data;
    wire tx_start;
    wire tx_busy;
    wire w_1Hz;

    // 1. UART 수신부 (PC -> FPGA)
    uart_rx #(.BPS(9600)) u_rx (
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .data_out(rx_data),
        .rx_done(rx_done)
    );

    // 2. 수신 데이터 파서 (문자열 분석 -> RTC 데이터 생성)
    rtc_parser u_rtc_parser (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .set_data(rtc_uart_data),
        .load_en(rtc_load_uart)
    );

    // 3. 1초 주기 타이머 (전송 타이밍용)
    tick_gen #(.Tick_Hz(1)) u_trig_1Hz (
        .clk(clk),
        .reset(reset),
        .tick(w_1Hz)
    );

    // 4. 데이터 송신 제어부 (시스템 데이터 -> 문자열 변환)
    data_sender u_sender (
        .clk(clk),
        .reset(reset),
        .start_trigger(w_1Hz),
        .r_year(y), .r_month(m), .r_day(d),
        .r_hour(h), .r_min(min), .r_sec(s),
        .r_humi(humi), .r_temp(temp),
        .tx_busy(tx_busy),
        .tx_start(tx_start),
        .tx_data(tx_data)
    );

    // 5. UART 송신부 (FPGA -> PC)
    uart_tx #(.BPS(9600)) u_tx (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(RsTx),
        .tx_busy(tx_busy)
    );

endmodule
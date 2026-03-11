module rtc_management_unit(
    input clk,
    input reset,
    input btnL_final,           // 허가된 시간 설정 버튼 tick
    input btnR_final,           // 허가된 분 설정 버튼 tick
    input enc_btn_tick,         // 엔코더 푸시 tick
    input phase_A,              // 엔코더 A상
    input phase_B,              // 엔코더 B상
    input [7:0] h,              // 현재 RTC 시간 (BCD)
    input [7:0] min,            // 현재 RTC 분 (BCD)
    input [7:0] y, m, d, s,     // 현재 RTC 날짜 및 초
    input rtc_load_uart,        // UART 로드 신호
    input [63:0] rtc_uart_data, // UART 설정 데이터
    output [7:0] h_sel,         // 설정 중인 시간 (BCD)
    output [7:0] m_sel,         // 설정 중인 분 (BCD)
    output [63:0] rtc_final_data, // RTC로 보낼 최종 64비트 데이터
    output o_rtc_load_final,    // RTC 최종 로드 실행 신호
    output [1:0] r_set_mode     // 현재 설정 모드 (FND 깜빡임 제어용)
);

    // 내부 와이어: 수동 설정 완료 신호
    wire rtc_load_manual;

    // 1. 시간 설정 컨트롤러 인스턴스
    time_setting_controller u_time_ctrl(
        .clk(clk),
        .reset(reset),
        .btnL_tick(btnL_final),
        .btnR_tick(btnR_final),
        .phase_A(phase_A),
        .phase_B(phase_B),
        .enc_btn_tick(enc_btn_tick),
        .curr_hour(h),
        .curr_min(min),
        .r_set_mode(r_set_mode),
        .final_hour(h_sel),
        .final_min(m_sel),
        .load_en(rtc_load_manual)
    );

    // 2. RTC 데이터 라우터 인스턴스
    rtc_data_router u_router (
        .clk(clk),
        .reset(reset),
        .rtc_load_uart(rtc_load_uart),
        .rtc_load_manual(rtc_load_manual),
        .rtc_set_data_uart(rtc_uart_data),
        .y(y),
        .m(m),
        .d(d),
        .s(s),
        .h_selected(h_sel),
        .min_selected(m_sel),
        .r_rtc_final_data(rtc_final_data),
        .o_rtc_load_final(o_rtc_load_final)
    );

endmodule
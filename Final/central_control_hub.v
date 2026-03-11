module central_control_hub(
    input clk,
    input reset,
    // 입력 장치 신호
    input btn_mode,
    input btnL,
    input btnR,
    input encoder_btn,
    input phase_A,
    input phase_B,
    // 현재 시스템 상태 (트리거 생성 및 초기값 복사용)
    input [7:0] h,
    input [7:0] min,
    input [7:0] s,
    input [7:0] y,
    input [7:0] m,
    input [7:0] d,
    input [7:0] temp,
    // UART 경로 신호
    input rtc_load_uart,
    input [63:0] rtc_uart_data,
    // 출력 제어 신호
    output w_fnd_mode,          // 0:시계, 1:온습도
    output w_blink,             // FND 깜빡임 클럭
    output [7:0] h_sel,         // 설정 중인 시간
    output [7:0] m_sel,         // 설정 중인 분
    output [63:0] rtc_final_data, // RTC로 보낼 최종 데이터
    output o_rtc_load_final,    // RTC 최종 로드 신호
    output [1:0] r_set_mode,    // 현재 설정 상태 (0, 1, 2)
    output o_trig_hourly,       // 정각 트리거
    output o_trig_motor,        // 모터 트리거
    output o_trig_buzzer_mode,  // 부저 트리거
    output w_enc_btn_tick       // 엔코더 버튼 틱 (필요 시 외부 사용)
);

    // 내부 전용 신호망 (Internal Wires)
    wire w_mode_tick;
    wire btnL_final;
    wire btnR_final;

    // 1. 시스템 제어 유닛 (입력 처리 및 트리거 생성)
    system_control_unit u_sys_ctrl (
        .clk(clk),
        .reset(reset),
        .btn_mode(btn_mode),
        .btnL(btnL),
        .btnR(btnR),
        .encoder_btn(encoder_btn),
        .min(min),
        .s(s),
        .temp(temp),
        .w_fnd_mode(w_fnd_mode),
        .o_btnL_allowed(btnL_final),
        .o_btnR_allowed(btnR_final),
        .o_trig_hourly(o_trig_hourly),
        .o_trig_motor(o_trig_motor),
        .o_trig_buzzer_mode(o_trig_buzzer_mode),
        .w_mode_tick(w_mode_tick),
        .w_enc_btn_tick(w_enc_btn_tick)
    );

    // 2. RTC 관리 유닛 (데이터 경로 및 설정 로직)
    rtc_management_unit u_rtc_mgr (
        .clk(clk),
        .reset(reset),
        .btnL_final(btnL_final),
        .btnR_final(btnR_final),
        .enc_btn_tick(w_enc_btn_tick),
        .phase_A(phase_A),
        .phase_B(phase_B),
        .h(h),
        .min(min),
        .y(y), .m(m), .d(d), .s(s),
        .rtc_load_uart(rtc_load_uart),
        .rtc_uart_data(rtc_uart_data),
        .h_sel(h_sel),
        .m_sel(m_sel),
        .rtc_final_data(rtc_final_data),
        .o_rtc_load_final(o_rtc_load_final),
        .r_set_mode(r_set_mode)
    );

    // 3. 공통 유틸리티 (모드 전환 및 깜빡임 생성)
    mode_switch_controller u_mode_sw (
        .clk(clk),
        .reset(reset),
        .tick(w_mode_tick),
        .mode_out(w_fnd_mode)
    );

    blink_gen u_blink_gen (
        .clk(clk),
        .reset(reset),
        .blink_out(w_blink)
    );

endmodule
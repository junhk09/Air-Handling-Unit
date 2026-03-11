`timescale 1ns / 1ps

module top(
    input clk, reset,
    inout dht11_data,
    output RsTx, input RsRx,
    input btn_mode, btnL, btnR, encoder_btn,
    input phase_A, phase_B,
    output PWM_OUT, [1:0] in1_in2,
    output buzzer, [7:0] seg, [3:0] an,
    output servo_pwm,
    output ds1302_sclk, ds1302_ce, inout ds1302_io
);

//---------------------------------------------------------
// 1. 시스템 내부 신호망 (Internal Interconnects)
//---------------------------------------------------------
    // 공통 데이터 버스 (센서 및 RTC 정보)
    wire [7:0] y, m, d, h, min, s, temp, humi;
    
    // 중앙 허브 -> 각 유닛 제어 신호
    wire [63:0] rtc_final_data;
    wire rtc_load_final, w_fnd_mode, w_blink;
    wire [1:0] r_set_mode;
    wire [7:0] h_sel, m_sel;
    wire trig_hourly, trig_motor, trig_buzzer_mode;
    wire w_enc_btn_tick;

    // 통신 브릿지 -> 중앙 허브 데이터
    wire [63:0] rtc_uart_data;
    wire rtc_load_uart;

    // 디스플레이용 가공 데이터
    wire [7:0] w_fnd_temp, w_fnd_humi;

//---------------------------------------------------------
// 2. [슈퍼 블록 1] 중앙 제어 허브 (두뇌 및 논리 판단)
//---------------------------------------------------------
    central_control_hub u_hub (
        .clk                (clk),
        .reset              (reset),
        .btn_mode           (btn_mode),
        .btnL               (btnL),
        .btnR               (btnR),
        .encoder_btn        (encoder_btn),
        .phase_A            (phase_A),
        .phase_B            (phase_B),
        .h                  (h),
        .min                (min),
        .s                  (s),
        .y                  (y),
        .m                  (m),
        .d                  (d),
        .temp               (temp),
        .rtc_load_uart      (rtc_load_uart),
        .rtc_uart_data      (rtc_uart_data),
        .w_fnd_mode         (w_fnd_mode),
        .w_blink            (w_blink),
        .h_sel              (h_sel),
        .m_sel              (m_sel),
        .rtc_final_data     (rtc_final_data),
        .o_rtc_load_final   (rtc_load_final),
        .r_set_mode         (r_set_mode),
        .o_trig_hourly      (trig_hourly),
        .o_trig_motor       (trig_motor),
        .o_trig_buzzer_mode (trig_buzzer_mode),
        .w_enc_btn_tick     (w_enc_btn_tick)
    );

//---------------------------------------------------------
// 3. [슈퍼 블록 2] 주변 장치 클러스터 (센서 및 액추에이터 실행)
//---------------------------------------------------------
    peripheral_io_cluster u_io (
        .clk                (clk),
        .reset              (reset),
        .rtc_load_final     (rtc_load_final),
        .rtc_set_data       (rtc_final_data),
        .y(y), .m(m), .d(d),
        .h(h), .min(min), .s(s),
        .temp(temp),
        .humi(humi),
        .trig_hourly        (trig_hourly),
        .trig_motor         (trig_motor),
        .trig_buzzer_mode   (trig_buzzer_mode),
        .dht11_data         (dht11_data),
        .ds1302_sclk        (ds1302_sclk),
        .ds1302_ce          (ds1302_ce),
        .ds1302_io          (ds1302_io),
        .PWM_OUT            (PWM_OUT),
        .in1_in2            (in1_in2),
        .buzzer             (buzzer),
        .servo_pwm(servo_pwm)
    );

//---------------------------------------------------------
// 4. [슈퍼 블록 3] 통신 브릿지 (PC 데이터 송수신 통로)
//---------------------------------------------------------
    communication_bridge u_comm (
        .clk                (clk),
        .reset              (reset),
        .RsRx               (RsRx),
        .RsTx               (RsTx),
        .y(y), .m(m), .d(d),
        .h(h), .min(min), .s(s),
        .temp(temp),
        .humi(humi),
        .rtc_uart_data      (rtc_uart_data),
        .rtc_load_uart      (rtc_load_uart)
    );

//---------------------------------------------------------
// 5. [슈퍼 블록 4] 디스플레이 타워 (정보 시각화)
//---------------------------------------------------------


    controll_tower u_fnd (
        .clk                (clk),
        .reset              (reset),
        .mode               (w_fnd_mode),
        .rtc_hour           (h_sel),
        .rtc_min            (m_sel),
        .temp               (temp),
        .humi               (humi),
        .i_set_mode         (r_set_mode),
        .i_blink            (w_blink),
        .seg                (seg),
        .an                 (an)
    );

endmodule
module trigger_generator(
    input [7:0] min, temp,
    input w_mode_tick, w_btnL_tick, w_btnR_tick, w_enc_btn_tick,
    input w_fnd_mode,
    output o_trig_hourly,
    output o_trig_motor,
    output o_trig_buzzer_mode
);
    // 1. 정각 알림 트리거 (00분)
    assign o_trig_hourly = (min == 8'h00);

    // 2. 온도 경고 레벨 (28도 이상)
    assign o_trig_motor = (temp >= 28);

    // 3. 부저용 모드 버튼 트리거 (온습도 모드 시 필터링 포함)
    // 버튼 입력들을 하나로 묶어 부저 박스로 보냅니다.
    assign o_trig_buzzer_mode = w_mode_tick | 
                               (w_btnL_tick && !w_fnd_mode) | 
                               (w_btnR_tick && !w_fnd_mode) | 
                                w_enc_btn_tick;
endmodule
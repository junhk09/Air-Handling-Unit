module system_control_unit(
    input clk, reset,
    input btn_mode, btnL, btnR, encoder_btn,
    input [7:0] min, s, temp,
    output w_fnd_mode, o_btnL_allowed, o_btnR_allowed,
    output o_trig_hourly, o_trig_motor, o_trig_buzzer_mode,
    output w_mode_tick, w_enc_btn_tick // 외부 사용 신호
);
    // 내부 와이어들 (기존의 tick 신호들)
    wire w_btnL_tick, w_btnR_tick;

    input_processor u_ip (
        .clk(clk),
        .reset(reset),
        .btn_mode(btn_mode),
        .btnL(btnL),
        .btnR(btnR),
        .encoder_btn(encoder_btn),
        .w_mode_tick(w_mode_tick),
        .w_btnL_tick(w_btnL_tick),
        .w_btnR_tick(w_btnR_tick),
        .w_enc_btn_tick(w_enc_btn_tick)
    );

    mode_switch_controller u_mode_sw (
        .clk(clk), 
        .reset(reset), 
        .tick(w_mode_tick), 
        .mode_out(w_fnd_mode)
    );

    system_control_logic u_sys_logic (
        .w_btnL_tick(w_btnL_tick), 
        .w_btnR_tick(w_btnR_tick), 
        .w_fnd_mode(w_fnd_mode),
        .o_btnL_allowed(o_btnL_allowed), 
        .o_btnR_allowed(o_btnR_allowed)
    );

    trigger_generator u_trig_gen (
        .min(min), .temp(temp),
        .w_mode_tick(w_mode_tick), .w_btnL_tick(w_btnL_tick), .w_btnR_tick(w_btnR_tick), 
        .w_enc_btn_tick(w_enc_btn_tick), .w_fnd_mode(w_fnd_mode),
        .o_trig_hourly(o_trig_hourly), .o_trig_motor(o_trig_motor), .o_trig_buzzer_mode(o_trig_buzzer_mode)
    );
endmodule
module system_control_logic(
    input w_btnL_tick, w_btnR_tick, w_fnd_mode,
    output o_btnL_allowed,
    output o_btnR_allowed
);
    // 시계 모드(w_fnd_mode=0)일 때만 설정 진입 허용
    assign o_btnL_allowed = w_btnL_tick && !w_fnd_mode;
    assign o_btnR_allowed = w_btnR_tick && !w_fnd_mode;
endmodule
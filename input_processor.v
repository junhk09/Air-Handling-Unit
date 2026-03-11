module input_processor(
    input clk, reset,
    input btn_mode, btnL, btnR, encoder_btn,
    output w_mode_tick, w_btnL_tick, w_btnR_tick, w_enc_btn_tick
);
    // 각 버튼별 디바운서 & 에지 검출기 내부 선언
    wire db_mode, db_L, db_R, db_enc;

    debouncer u_db_mode (.clk(clk), .reset(reset), .noisy_btn(btn_mode), .clean_btn(db_mode));
    edge_detector_n u_ed_mode (.clk(clk), .reset(reset), .cp(db_mode), .p_edge(w_mode_tick));

    debouncer u_db_L (.clk(clk), .reset(reset), .noisy_btn(btnL), .clean_btn(db_L));
    edge_detector_n u_ed_L (.clk(clk), .reset(reset), .cp(db_L), .p_edge(w_btnL_tick));

    debouncer u_db_R (.clk(clk), .reset(reset), .noisy_btn(btnR), .clean_btn(db_R));
    edge_detector_n u_ed_R (.clk(clk), .reset(reset), .cp(db_R), .p_edge(w_btnR_tick));

    debouncer u_db_enc (.clk(clk), .reset(reset), .noisy_btn(encoder_btn), .clean_btn(db_enc));
    edge_detector_n u_ed_enc (.clk(clk), .reset(reset), .cp(db_enc), .p_edge(w_enc_btn_tick));
endmodule
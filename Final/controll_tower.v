`timescale 1ns / 1ps

module controll_tower(
    input clk,
    input reset,
    input mode,                // 0: 시계(H:M), 1: 온습도(H:T)
    input [7:0] rtc_hour,
    input [7:0] rtc_min,
    input [7:0] temp,
    input [7:0] humi,
    input [1:0] i_set_mode,    // [수정] 1비트 -> 2비트로 확장 (0:없음, 1:시간, 2:분)
    input i_blink,             
    output [7:0] seg,
    output [3:0] an
);
// [로직 이동] 내부에서 BCD 변환 수행
    wire [3:0] t_10 = temp / 10;
    wire [3:0] t_1  = temp % 10;
    wire [3:0] h_10 = humi / 10;
    wire [3:0] h_1  = humi % 10;

    wire [7:0] w_fnd_temp = {t_10, t_1};
    wire [7:0] w_fnd_humi = {h_10, h_1};
    reg [7:0] disp_high, disp_low;
    reg [3:0] r_digit;
    wire w_fnd_tick;
    reg [1:0] r_fnd_select;

    // 1. 모드에 따른 표시 데이터 선택
    always @(*) begin
        if (mode) begin
            disp_high = w_fnd_humi; 
            disp_low  = w_fnd_temp;
        end else begin
            disp_high = rtc_hour;
            disp_low  = rtc_min;
        end
    end

    // 2. FND 스캐닝 주기를 위한 1kHz 티커
    tick_gen #(.Tick_Hz(1000)) u_fnd_tick (
        .clk(clk), .reset(reset), .tick(w_fnd_tick)
    );

    always @(posedge clk or posedge reset) begin
        if(reset) r_fnd_select <= 0;
        else if(w_fnd_tick) r_fnd_select <= r_fnd_select + 1;
    end

    // 3. 현재 켤 자리수의 데이터 추출
    always @(*) begin
        r_digit = 4'h0;
        case(r_fnd_select)
            2'b00: r_digit = disp_high[7:4];
            2'b01: r_digit = disp_high[3:0];
            2'b10: r_digit = disp_low[7:4]; 
            2'b11: r_digit = disp_low[3:0]; 
            default: r_digit = 4'h0;
        endcase
    end

    // 4. 공통 애노드(Common Anode) 제어 + 깜빡임 조건 세분화
    // blink_h: 시계모드 && 시간설정모드(1) && 깜빡이 타이밍 && 왼쪽 두 자리(00,01)
    wire blink_h = (!mode && i_set_mode == 2'b01 && i_blink && r_fnd_select[1] == 0);
    // blink_m: 시계모드 && 분설정모드(2) && 깜빡이 타이밍 && 오른쪽 두 자리(10,11)
    wire blink_m = (!mode && i_set_mode == 2'b10 && i_blink && r_fnd_select[1] == 1);

    assign an = (blink_h || blink_m) ? 4'b1111 : // 깜빡일 때 해당 자리 끔
                (r_fnd_select == 2'b00) ? 4'b0111 : 
                (r_fnd_select == 2'b01) ? 4'b1011 :
                (r_fnd_select == 2'b10) ? 4'b1101 : 4'b1110;

    // 5. 7세그먼트 디코더
    assign seg = (r_digit == 4'h0) ? 8'hc0 :
                 (r_digit == 4'h1) ? 8'hf9 :
                 (r_digit == 4'h2) ? 8'ha4 :
                 (r_digit == 4'h3) ? 8'hb0 :
                 (r_digit == 4'h4) ? 8'h99 :
                 (r_digit == 4'h5) ? 8'h92 :
                 (r_digit == 4'h6) ? 8'h82 :
                 (r_digit == 4'h7) ? 8'hf8 :
                 (r_digit == 4'h8) ? 8'h80 :
                 (r_digit == 4'h9) ? 8'h90 : 8'hff;

endmodule
`timescale 1ns / 1ps

// 1. 하위 모듈: 실제 서보 PWM 생성
module servo_control (
    input clk, 
    input reset, 
    input i_open,         // 1: 열림(90도), 0: 닫힘(0도) - btnD에서 이름 변경
    output reg pwm_out
);
    // 100MHz 기준 상수 설정
    localparam PERIOD_20MS = 21'd2_000_000; 
    localparam POS_0       = 21'd100_000;   // 1.0ms (0도)
    localparam POS_90      = 21'd200_000;   // 2.0ms (90도)
    
    reg [20:0] cnt;

    // 20ms 주기 카운터
    always @(posedge clk or posedge reset) begin
        if (reset) cnt <= 0;
        else if (cnt >= PERIOD_20MS - 1) cnt <= 0;
        else cnt <= cnt + 1;
    end

    // 상태에 따른 PWM 출력 결정
    always @(posedge clk or posedge reset) begin
        if (reset) pwm_out <= 0;
        else pwm_out <= (i_open) ? (cnt < POS_90) : (cnt < POS_0);
    end
endmodule
// 2. 상위 모듈: 습도 판단 및 서보 인터페이스
module auto_window_control(
    input clk, 
    input reset, 
    input [7:0] humidity,   // DHT11에서 오는 10진수 습도 데이터
    output servo_pwm, 
    output reg window_open  // 현재 창문 상태
);
    always @(posedge clk or posedge reset) begin
        if (reset) window_open <= 1'b0;
        else begin
            // 10진수(d) 비교 방식 유지
            if (humidity >= 8'd70)      window_open <= 1'b1; 
            else if (humidity <= 8'd65) window_open <= 1'b0; 
        end
    end

    servo_control u_servo (
        .clk(clk), .reset(reset), .i_open(window_open), .pwm_out(servo_pwm)
    );
endmodule
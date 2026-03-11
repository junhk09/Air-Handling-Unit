module motor_controller(
    input clk,
    input reset,
    input [7:0] temp,        // DHT11에서 읽어온 온도 값
    output PWM_OUT,          // 모터 드라이버 EN/PWM 핀 연결
    output [1:0] in1_in2     // 모터 드라이버 IN1, IN2 핀 연결
);

    reg [3:0] r_counter_PWM;
    wire [3:0] target_duty;

    // 1. 온도 조건 판별: 28도 이상이면 Duty 7(70%), 미만이면 0(정지)
    assign target_duty = (temp >= 28) ? 4'd7 : 4'd0;
    assign in1_in2 = 2'b10;

    // 3. 10MHz PWM 신호 생성 (100MHz / 10)
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_counter_PWM <= 0;
        end else begin
            if(r_counter_PWM >= 4'd9)
                r_counter_PWM <= 0;
            else 
                r_counter_PWM <= r_counter_PWM + 1;
        end
    end

    // 4. 비교기를 통한 최종 PWM 출력
    assign PWM_OUT = (r_counter_PWM < target_duty) ? 1'b1 : 1'b0;

endmodule
module buzzer_control(
    input clk, reset,
    input trig_hourly,      // 정각 알림
    input trig_motor,       // 온도 28도 이상 신호 (temp >= 28)
    input trig_mode,        // 버튼 조작 신호
    output reg buzzer
);
    reg [23:0] buzzer_cnt;
    reg r_trig_motor_prev;  // 온도의 이전 상태 저장용
    reg r_trig_hourly_prev;  // 정각 신호의 이전 상태 저장용

    wire w_motor_edge;      // 온도가 딱 28도가 되는 순간의 펄스
    wire w_hourly_edge;     // 정각 순간을 가리키는 신호 선
    // 1. 온도가 28도 이상이 되는 '순간'을 포착 (Rising Edge)
    always @(posedge clk or posedge reset) begin
        if(reset) begin
             r_trig_motor_prev <= 0;
                r_trig_hourly_prev <= 0;
        end
        else  begin    
            r_trig_motor_prev <= trig_motor;
                r_trig_hourly_prev <= trig_hourly;
        end
    end
    
    // 이전엔 0이었는데 지금 1이라면? 딱 28도가 된 시점!
    assign w_motor_edge = (trig_motor && !r_trig_motor_prev);
    assign w_hourly_edge = (trig_hourly && !r_trig_hourly_prev);
    // 2. 부저 소리 지속 시간 제어
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            buzzer <= 0;
            buzzer_cnt <= 0;
        end 
        else begin
            // 알람 트리거 조건들 (정각, 온도 에지, 버튼 조작)
            if(w_hourly_edge || w_motor_edge || trig_mode) begin
                buzzer <= 1;
                buzzer_cnt <= 1; // 카운트 시작
            end
            
            // 일정 시간(예: 0.1초) 동안만 소리 내고 끄기
            if(buzzer_cnt > 0) begin
                if(buzzer_cnt < 24'd5_000_000) begin // 100MHz 기준 0.05초
                    buzzer_cnt <= buzzer_cnt + 1;
                    buzzer <= 1;
                end else begin
                    buzzer_cnt <= 0;
                    buzzer <= 0;
                end
            end
        end
    end
endmodule
module peripheral_io_cluster(
    input clk,
    input reset,
    
    // RTC 제어 및 데이터
    input rtc_load_final,       // RTC 쓰기 활성화 신호
    input [63:0] rtc_set_data,  // RTC에 쓸 64비트 데이터
    output [7:0] y, m, d,       // 년, 월, 일 출력
    output [7:0] h, min, s,     // 시, 분, 초 출력
    
    // 센서 데이터
    output [7:0] temp,          // 온도 데이터
    output [7:0] humi,          // 습도 데이터
    
    // 시스템 트리거 신호 (외부 hub에서 가공된 신호)
    input trig_hourly,          // 정각 트리거
    input trig_motor,           // 모터 동작 트리거 (온도 기준)
    input trig_buzzer_mode,     // 부저 모드 전환 트리거
    
    // 하드웨어 실제 핀 (Hardware Pins)
    output servo_pwm,
    inout dht11_data,           // DHT11 센서 핀
    output ds1302_sclk,         // DS1302 클럭
    output ds1302_ce,           // DS1302 활성화
    inout ds1302_io,            // DS1302 데이터 핀
    output PWM_OUT,             // 팬 모터 속도 제어
    output [1:0] in1_in2,       // 팬 모터 방향 제어
    output buzzer               // 부저 출력
);

// 2. [추가] 자동 창문 제어 (판단 로직 + 서보 드라이버)
    auto_window_control u_window (
        .clk(clk),
        .reset(reset),
        .humidity(humi),      // u_dht11에서 나온 습도 직접 연결
        .servo_pwm(servo_pwm),
        .window_open()        // 상태 모니터링이 필요 없으면 비워둠
    );
    // 1. DHT11 온습도 센서 컨트롤러
    dht11_controller u_dht11 (
        .clk(clk),
        .reset(reset),
        .dht11_data(dht11_data),
        .temperature(temp),
        .humidity(humi),
        .done() // 완료 신호는 현재 미사용
    );

    // 2. DS1302 RTC 컨트롤러
    ds1302_controller u_ds1302 (
        .clk(clk),
        .reset(reset),
        .load_en(rtc_load_final),
        .set_data(rtc_set_data),
        .ds1302_sclk(ds1302_sclk),
        .ds1302_ce(ds1302_ce),
        .ds1302_io(ds1302_io),
        .out_year(y),
        .out_month(m),
        .out_day(d),
        .out_hour(h),
        .out_min(min),
        .out_sec(s)
    );

    // 3. DC 모터 컨트롤러 (팬 제어)
    motor_controller u_motor (
        .clk(clk),
        .reset(reset),
        .temp(temp),            // 내부에서 측정한 온도 바로 연결
        .PWM_OUT(PWM_OUT),
        .in1_in2(in1_in2)
    );

    // 4. 부저 컨트롤러
    buzzer_control u_buzzer (
        .clk(clk),
        .reset(reset),
        .trig_hourly(trig_hourly),
        .trig_motor(trig_motor),
        .trig_mode(trig_buzzer_mode),
        .buzzer(buzzer)
    );

endmodule
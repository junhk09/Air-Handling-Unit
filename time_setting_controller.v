module time_setting_controller(
    input clk, reset,
    input btnL_tick, btnR_tick,
    input phase_A, phase_B,
    input enc_btn_tick,
    input [7:0] curr_hour, curr_min,
    output reg [1:0] r_set_mode, 
    output [7:0] final_hour, final_min,
    output reg load_en
);
    reg [7:0] b_hour, b_min; // 8비트로 확장
    reg [1:0] shift_A, shift_B;

    always @(posedge clk) begin
        shift_A <= {shift_A[0], phase_A};
        shift_B <= {shift_B[0], phase_B};
    end

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_set_mode <= 0; b_hour <= 0; b_min <= 0; load_en <= 0;
        end else begin
            // 모드 진입 및 현재 시간 복사 (BCD -> Binary 변환 중요)
           if(btnL_tick) begin
                if(r_set_mode != 2'b01) begin 
                    // 진입하는 순간 '시'와 '분'을 모두 현재 값으로 복사
                    b_hour <= (curr_hour[7:4] * 10) + curr_hour[3:0];
                    b_min  <= (curr_min[7:4] * 10) + curr_min[3:0]; // 이 줄 추가!
                end
                r_set_mode <= (r_set_mode == 2'b01) ? 2'b00 : 2'b01;
            end
           // [수정] 분 설정 모드 진입 시
            else if(btnR_tick) begin
                if(r_set_mode != 2'b10) begin
                    // 진입하는 순간 '시'와 '분'을 모두 현재 값으로 복사
                    b_hour <= (curr_hour[7:4] * 10) + curr_hour[3:0]; // 이 줄 추가!
                    b_min  <= (curr_min[7:4] * 10) + curr_min[3:0];
                end
                r_set_mode <= (r_set_mode == 2'b10) ? 2'b00 : 2'b10;
            end
            
            // 저장 로직
            if(r_set_mode != 0 && enc_btn_tick) begin
                load_en <= 1;
            end else if (load_en) begin
                load_en <= 0;
                r_set_mode <= 0;
            end

            // 로터리 엔코더 조절 (0~23, 0~59 범위 보장)
            if(shift_A == 2'b10 && !load_en) begin
                if(r_set_mode == 2'b01) begin // 시 조절
                    if(shift_B[1] == 0) b_hour <= (b_hour >= 23) ? 0 : b_hour + 1;
                    else                b_hour <= (b_hour == 0) ? 23 : b_hour - 1;
                end
                else if(r_set_mode == 2'b10) begin // 분 조절
                    if(shift_B[1] == 0) b_min <= (b_min >= 59) ? 0 : b_min + 1;
                    else                b_min <= (b_min == 0) ? 59 : b_min - 1;
                end
            end
        end
    end

  // 3. Binary -> BCD 변환 (중간 wire 선언으로 오류 방지)
    wire [3:0] b_hour_ten = (b_hour / 10);
    wire [3:0] b_hour_one = (b_hour % 10);
    wire [3:0] b_min_ten  = (b_min / 10);
    wire [3:0] b_min_one  = (b_min % 10);

    // 최종 출력 선택
    assign final_hour = (r_set_mode == 2'b01 || load_en) ? {b_hour_ten, b_hour_one} : curr_hour;
    assign final_min  = (r_set_mode == 2'b10 || load_en) ? {b_min_ten, b_min_one} : curr_min;
endmodule
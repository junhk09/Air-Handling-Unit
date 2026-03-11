`timescale 1ns / 1ps

module data_sender(
    input clk, input reset, input start_trigger,
    input [7:0] r_year, r_month, r_day, r_hour, r_min, r_sec,
    input [7:0] r_humi, r_temp, // DHT11 데이터 입력 추가
    input tx_busy, output reg tx_start, output reg [7:0] tx_data
);
    reg [5:0] step = 0;
    reg r_start_prev = 0;

    // Binary를 10진수 문자로 변환하기 위한 계산
    wire [7:0] h_ten = (r_humi / 10) + 8'h30;
    wire [7:0] h_one = (r_humi % 10) + 8'h30;
    wire [7:0] t_ten = (r_temp / 10) + 8'h30;
    wire [7:0] t_one = (r_temp % 10) + 8'h30;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            step <= 0; tx_start <= 0; r_start_prev <= 0;
        end else begin
            if(start_trigger && !r_start_prev && step == 0) step <= 1;
            r_start_prev <= start_trigger;

            if(step > 0 && !tx_busy && !tx_start) begin
                tx_start <= 1;
                case(step)
                    // 1-8: Year ("Year:26 ")
                    1: tx_data <= "Y"; 2: tx_data <= "e"; 3: tx_data <= "a"; 4: tx_data <= "r"; 5: tx_data <= ":";
                    6: tx_data <= (r_year[7:4] + 8'h30); 7: tx_data <= (r_year[3:0] + 8'h30); 8: tx_data <= " ";
                    
                    // 9-17: Month ("Month:03 ")
                    9: tx_data <= "M"; 10: tx_data <= "o"; 11: tx_data <= "n"; 12: tx_data <= "t"; 13: tx_data <= "h"; 14: tx_data <= ":";
                    15: tx_data <= (r_month[7:4] + 8'h30); 16: tx_data <= (r_month[3:0] + 8'h30); 17: tx_data <= " ";
                    
                    // 18-24: Day ("Day:06 ")
                    18: tx_data <= "D"; 19: tx_data <= "a"; 20: tx_data <= "y"; 21: tx_data <= ":";
                    22: tx_data <= (r_day[7:4] + 8'h30); 23: tx_data <= (r_day[3:0] + 8'h30); 24: tx_data <= " ";
                    
                    // 25-37: Time ("Time:15:20:44 ")
                    25: tx_data <= "T"; 26: tx_data <= "i"; 27: tx_data <= "m"; 28: tx_data <= "e"; 29: tx_data <= ":";
                    30: tx_data <= (r_hour[7:4] + 8'h30); 31: tx_data <= (r_hour[3:0] + 8'h30); 32: tx_data <= ":";
                    33: tx_data <= (r_min[7:4] + 8'h30); 34: tx_data <= (r_min[3:0] + 8'h30); 35: tx_data <= ":";
                    36: tx_data <= (r_sec[7:4] + 8'h30); 37: tx_data <= (r_sec[3:0] + 8'h30); 38: tx_data <= " ";

                    // 39-44: Humidity ("H:50% ")
                    39: tx_data <= "H"; 40: tx_data <= ":"; 
                    41: tx_data <= h_ten; 42: tx_data <= h_one; 
                    43: tx_data <= "%"; 44: tx_data <= " ";

                    // 45-50: Temp ("T:25C ")
                    45: tx_data <= "T"; 46: tx_data <= ":";
                    47: tx_data <= t_ten; 48: tx_data <= t_one;
                    49: tx_data <= "C"; 50: tx_data <= " ";

                    // 51-52: 줄바꿈
                    51: tx_data <= 8'h0D; 52: tx_data <= 8'h0A; 
                    default: begin tx_start <= 0; step <= 0; end
                endcase
                
                if(step != 0) step <= step + 1;
            end else begin
                tx_start <= 0;
            end
        end
    end
endmodule
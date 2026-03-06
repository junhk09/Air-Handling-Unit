`timescale 1ns / 1ps

module data_sender(
    input clk, input reset, input start_trigger,
    input [7:0] r_year, r_month, r_day, r_hour, r_min, r_sec,
    input tx_busy, output reg tx_start, output reg [7:0] tx_data
);
    reg [5:0] step = 0;
    reg r_start_prev = 0;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            step <= 0; tx_start <= 0; r_start_prev <= 0;
        end else begin
            // 상승 에지 감지로 1초에 한 번만 시작
            if(start_trigger && !r_start_prev && step == 0) step <= 1;
            r_start_prev <= start_trigger;

            if(step > 0 && !tx_busy && !tx_start) begin
                tx_start <= 1;
                case(step)
                    // 1-8: Year 전송 ("Year:26 ")
                    1: tx_data <= "Y"; 2: tx_data <= "e"; 3: tx_data <= "a"; 4: tx_data <= "r"; 5: tx_data <= ":";
                    6: tx_data <= (r_year[7:4] + 8'h30); 7: tx_data <= (r_year[3:0] + 8'h30); 8: tx_data <= " ";
                    
                    // 9-16: Month 전송 ("Month:03 ")
                    9: tx_data <= "M"; 10: tx_data <= "o"; 11: tx_data <= "n"; 12: tx_data <= "t"; 13: tx_data <= "h"; 14: tx_data <= ":";
                    15: tx_data <= (r_month[7:4] + 8'h30); 16: tx_data <= (r_month[3:0] + 8'h30); 17: tx_data <= " ";
                    
                    // 18-23: Day 전송 ("Day:06 ")
                    18: tx_data <= "D"; 19: tx_data <= "a"; 20: tx_data <= "y"; 21: tx_data <= ":";
                    22: tx_data <= (r_day[7:4] + 8'h30); 23: tx_data <= (r_day[3:0] + 8'h30); 24: tx_data <= " ";
                    
                    // 25-34: Time 전송 ("Time:15:20:44")
                    25: tx_data <= "T"; 26: tx_data <= "i"; 27: tx_data <= "m"; 28: tx_data <= "e"; 29: tx_data <= ":";
                    30: tx_data <= (r_hour[7:4] + 8'h30); 31: tx_data <= (r_hour[3:0] + 8'h30); 32: tx_data <= ":";
                    33: tx_data <= (r_min[7:4] + 8'h30); 34: tx_data <= (r_min[3:0] + 8'h30); 35: tx_data <= ":";
                    36: tx_data <= (r_sec[7:4] + 8'h30); 37: tx_data <= (r_sec[3:0] + 8'h30);
                    
                    // 38-39: 줄바꿈
                    38: tx_data <= 8'h0D; 39: tx_data <= 8'h0A; // CRLF
                    default: begin tx_start <= 0; step <= 0; end
                endcase
                
                if(step != 0) step <= step + 1;
            end else begin
                tx_start <= 0;
            end
        end
    end
endmodule
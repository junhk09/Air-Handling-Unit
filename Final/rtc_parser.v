module rtc_parser(
    input clk, input reset,
    input [7:0] rx_data, input rx_done,
    output reg [63:0] set_data,
    output reg load_en
);
    reg [4:0] byte_cnt;
    
    // ASCII 숫자를 BCD로 변환 ('2' -> 4'h2)
    function [3:0] ascii2bcd(input [7:0] ascii);
        ascii2bcd = ascii[3:0];
    endfunction

  always @(posedge clk or posedge reset) begin
    if(reset) begin
        byte_cnt <= 0; load_en <= 0; set_data <= 0;
    end else if(rx_done) begin
        // 1. 엔터(CR/LF)가 들어오면 카운트를 리셋하여 다음 전송을 준비
        if(rx_data == 8'h0D || rx_data == 8'h0A) begin
            byte_cnt <= 0;
        end 
        else begin
            case(byte_cnt)
                0:  set_data[55:52] <= ascii2bcd(rx_data); // Year 10
                1:  set_data[51:48] <= ascii2bcd(rx_data); // Year 1
                2:  set_data[39:36] <= ascii2bcd(rx_data); // Month 10
                3:  set_data[35:32] <= ascii2bcd(rx_data); // Month 1
                4:  set_data[31:28] <= ascii2bcd(rx_data); // Day 10
                5:  set_data[27:24] <= ascii2bcd(rx_data); // Day 1
                6:  set_data[23:20] <= ascii2bcd(rx_data); // Hour 10
                7:  set_data[19:16] <= ascii2bcd(rx_data); // Hour 1
                8:  set_data[15:12] <= ascii2bcd(rx_data); // Min 10
                9:  set_data[11:8]  <= ascii2bcd(rx_data); // Min 1
                10: set_data[7:4]   <= ascii2bcd(rx_data); // Sec 10
                11: begin 
                    set_data[3:0]   <= ascii2bcd(rx_data); // Sec 1
                    load_en <= 1; // 12자리 다 받으면 즉시 반영
                end
            endcase
            
            // 12자리를 다 채웠으면 0으로, 아니면 증가
            if(byte_cnt == 11) byte_cnt <= 0;
            else byte_cnt <= byte_cnt + 1;
        end
    end else begin
        load_en <= 0; // rx_done이 아닐 때는 load_en을 0으로 유지
    end
  end
endmodule
`timescale 1ns / 1ps

module ds1302_controller(
    input clk,
    input reset,
    output reg ds1302_sclk,
    output reg ds1302_ce,
    inout  ds1302_io,
    output [7:0] out_sec,
    output [7:0] out_min,
    output [7:0] out_hour,
    output [7:0] out_day,
    output [7:0] out_month,
    output [7:0] out_year
);
    // 100MHz -> 1MHz 분주 (DS1302 통신용 저속 클럭)
    reg [6:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;
    wire clk_1mhz = (clk_div == 0);

    reg [7:0] state = 0;
    reg [6:0] bit_cnt = 0;
    reg [63:0] read_buffer;

    // 명령어 변수화 (상수 인덱싱 오류 방지)
    wire [7:0] write_cmd = 8'hBE; // Burst Write
    wire [7:0] read_cmd  = 8'hBF; // Burst Read

    // [설정 1] 시간 수정 시 아래 값을 BCD 형식으로 변경하세요.
    // WP(00)_Year_DayOfWeek_Month_Day_Hour_Min_Sec
    wire [63:0] init_data = 64'h00_26_00_03_06_17_00_00; 

    reg io_dir = 1; // 1: Output, 0: Input
    reg io_out = 0;
    assign ds1302_io = (io_dir) ? io_out : 1'bz;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= 0; ds1302_ce <= 0; ds1302_sclk <= 0; bit_cnt <= 0;
        end else if(clk_1mhz) begin
            case(state)
                0: begin 
                    ds1302_ce <= 1; 
                    bit_cnt <= 0;
                    
                    // [설정 2] 모드 선택
                    state <= 4; // 평상시: 4 (Read 모드, 배터리 시간 유지)
                     //state <= 1; // 시간 수정 시: 1 (Write 모드)
                end

                // --- Burst Write (시간 설정) ---
                1: begin 
                    if(bit_cnt < 8) begin
                        io_dir <= 1;
                        io_out <= write_cmd[bit_cnt[2:0]]; // 수정됨: 변수 인덱싱
                        ds1302_sclk <= 0; 
                        state <= 2;
                    end else begin bit_cnt <= 0; state <= 3; end
                end
                2: begin ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 1; end
                3: begin 
                    if(bit_cnt < 64) begin
                        io_out <= init_data[bit_cnt]; ds1302_sclk <= 0; state <= 10;
                    end else begin 
                        ds1302_ce <= 0; state <= 0; 
                    end
                end
                10: begin ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 3; end

                // --- Burst Read (시간 읽기) ---
                4: begin 
                    if(bit_cnt < 8) begin
                        io_dir <= 1;
                        io_out <= read_cmd[bit_cnt[2:0]]; // 수정됨: 변수 인덱싱
                        ds1302_sclk <= 0; 
                        state <= 5;
                    end else begin bit_cnt <= 0; io_dir <= 0; state <= 6; end
                end
                5: begin ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 4; end
                6: begin 
                    if(bit_cnt < 64) begin
                        ds1302_sclk <= 0; 
                        state <= 7;
                    end else begin state <= 8; end
                end
                7: begin
                    read_buffer[bit_cnt] <= ds1302_io;
                    ds1302_sclk <= 1; 
                    bit_cnt <= bit_cnt + 1; 
                    state <= 6;
                end
                8: begin ds1302_ce <= 0; ds1302_sclk <= 0; state <= 0; end
            endcase
        end
    end
// 무슨요일인지 나타내는 [47:40] 은 미구현
    assign out_sec   = read_buffer[7:0];
    assign out_min   = read_buffer[15:8];
    assign out_hour  = read_buffer[23:16];
    assign out_day   = read_buffer[31:24];
    assign out_month = read_buffer[39:32];
    assign out_year  = read_buffer[55:48];
endmodule
`timescale 1ns / 1ps

module ds1302_controller(
    input clk, input reset,
    output reg ds1302_sclk, output reg ds1302_ce, inout ds1302_io,
    output [7:0] out_sec, out_min, out_hour, out_day, out_month, out_year
);
    reg [6:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;
    wire clk_1mhz = (clk_div == 0);

    reg [7:0] state = 0;
    reg [6:0] bit_cnt = 0;
    reg [63:0] read_buffer;
    reg [7:0] write_step = 0;

    // 초기 설정값: 26년 03월 06일 15시 20분 00초 (BCD 방식)
    // [0]초:00, [1]분:20, [2]시:15, [3]일:06, [4]월:03, [5]요일:06, [6]년:26, [7]WP해제:00
    wire [63:0] init_data = 64'h00_26_06_06_03_15_20_00; 
    wire [7:0] write_cmd = 8'hBE; // Burst Write Command
    wire [7:0] read_cmd  = 8'hBF; // Burst Read Command

    reg io_dir = 1; reg io_out = 0;
    assign ds1302_io = (io_dir) ? io_out : 1'bz;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= 0; ds1302_ce <= 0; ds1302_sclk <= 0; bit_cnt <= 0; write_step <= 0;
        end else if(clk_1mhz) begin
            case(state)
                0: begin // 0단계: Write (최초 1회) 또는 Read 시작
                    ds1302_ce <= 1; bit_cnt <= 0;
                    state <= (write_step == 0) ? 1 : 4; // 처음엔 쓰기(1), 이후엔 읽기(4)
                end
                // --- Burst Write (시계 가동) ---
                1: begin // 명령(0xBE) 전송
                    if(bit_cnt < 8) begin
                        io_dir <= 1; io_out <= write_cmd[bit_cnt];
                        ds1302_sclk <= 0; state <= 2;
                    end else begin state <= 3; bit_cnt <= 0; end
                end
                2: begin ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 1; end
                3: begin // 데이터(init_data) 전송
                    if(bit_cnt < 64) begin
                        io_out <= init_data[bit_cnt]; ds1302_sclk <= 0; state <= 10;
                    end else begin 
                        ds1302_ce <= 0; ds1302_sclk <= 0; write_step <= 1; state <= 0; 
                    end
                end
                10: begin ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 3; end

                // --- Burst Read (시간 읽기) ---
                4: begin // 명령(0xBF) 전송
                    if(bit_cnt < 8) begin
                        io_dir <= 1; io_out <= read_cmd[bit_cnt];
                        ds1302_sclk <= 0; state <= 5;
                    end else begin state <= 6; bit_cnt <= 0; io_dir <= 0; end
                end
                5: begin ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 4; end
                6: begin // 64비트 읽기
                    if(bit_cnt < 64) begin
                        ds1302_sclk <= 0; state <= 7;
                    end else begin state <= 8; end
                end
                7: begin
                    read_buffer[bit_cnt] <= ds1302_io;
                    ds1302_sclk <= 1; bit_cnt <= bit_cnt + 1; state <= 6;
                end
                8: begin ds1302_ce <= 0; ds1302_sclk <= 0; state <= 0; end
            endcase
        end
    end

    assign {out_year, out_month, out_day, out_hour, out_min, out_sec} = 
           {read_buffer[55:48], read_buffer[39:32], read_buffer[31:24], read_buffer[23:16], read_buffer[15:8], read_buffer[7:0]};
endmodule
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
    // 100MHz -> 1MHz 분주
    reg [6:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;
    wire clk_1mhz = (clk_div == 0);

    reg [7:0] state = 0;
    reg [6:0] bit_cnt = 0;
    reg [63:0] read_buffer;
    
    // Read Burst Command (0xBF)
    wire [7:0] read_cmd = 8'hBF;

    reg io_dir = 0; // 읽기 모드이므로 기본 High-Z(입력)
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
                    state <= 1; 
                end

                // --- Burst Read 시작 ---
                1: begin // 명령 전송 (0xBF)
                    if(bit_cnt < 8) begin
                        io_dir <= 1; // 명령 보낼 때는 출력 모드
                        io_out <= read_cmd[bit_cnt[2:0]];
                        ds1302_sclk <= 0; 
                        state <= 2;
                    end else begin 
                        bit_cnt <= 0; 
                        io_dir <= 0; // 명령 전송 후 입력 모드로 전환
                        state <= 3; 
                    end
                end
                
                2: begin 
                    ds1302_sclk <= 1; 
                    bit_cnt <= bit_cnt + 1; 
                    state <= 1; 
                end

                3: begin // 64비트 데이터 읽기 루프
                    if(bit_cnt < 64) begin
                        ds1302_sclk <= 0; 
                        state <= 4;
                    end else begin 
                        state <= 5; 
                    end
                end
                
                4: begin
                    read_buffer[bit_cnt] <= ds1302_io; // 데이터 샘플링
                    ds1302_sclk <= 1; 
                    bit_cnt <= bit_cnt + 1; 
                    state <= 3;
                end

                5: begin 
                    ds1302_ce <= 0; 
                    ds1302_sclk <= 0; 
                    state <= 0; // 무한 반복 (1초 주기는 top의 tick_gen이 관리)
                end
            endcase
        end
    end

    // 결과 출력 (BCD)
    assign out_sec   = read_buffer[7:0];
    assign out_min   = read_buffer[15:8];
    assign out_hour  = read_buffer[23:16];
    assign out_day   = read_buffer[31:24];
    assign out_month = read_buffer[39:32];
    assign out_year  = read_buffer[55:48];
endmodule
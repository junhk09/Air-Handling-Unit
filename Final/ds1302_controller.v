module ds1302_controller(
    input clk,
    input reset,

    input load_en,              // 시간 설정 시작 신호
    input [63:0] set_data,      // 설정할 시간 데이터

    output reg ds1302_sclk,
    output reg ds1302_ce,
    inout ds1302_io,

    output [7:0] out_sec,
    output [7:0] out_min,
    output [7:0] out_hour,
    output [7:0] out_day,
    output [7:0] out_month,
    output [7:0] out_year
);

    // --- 1MHz 클럭 생성 ---
    reg [6:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;
    wire clk_1mhz = (clk_div == 0);

    // --- FSM 상태 정의 (localparam) ---
    localparam S_IDLE          = 4'd0,
               S_WRITE_CMD_L   = 4'd1, S_WRITE_CMD_H   = 4'd2,
               S_WRITE_DATA_L  = 4'd3, S_WRITE_DATA_H  = 4'd4,
               S_READ_CMD_L    = 4'd5, S_READ_CMD_H    = 4'd6,
               S_READ_DATA_L   = 4'd7, S_READ_DATA_H   = 4'd8,
               S_FINISH        = 4'd9;

    reg [3:0] state;
    reg [6:0] bit_cnt;

    reg [63:0] read_buffer;
    reg [63:0] write_buffer;
    reg load_req;

    wire [7:0] write_cmd = 8'hBE; // Burst Write Command
    wire [7:0] read_cmd  = 8'hBF; // Burst Read Command

    reg io_dir; // 1: Output, 0: Input (Z)
    reg io_out;

    assign ds1302_io = io_dir ? io_out : 1'bz;

    // --- 시간 설정 요청(load_en) 래치 로직 ---
    always @(posedge clk or posedge reset) begin
        if(reset)
            load_req <= 0;
        else if(load_en)
            load_req <= 1;
        else if(state == S_WRITE_DATA_L && bit_cnt == 64)
            load_req <= 0;
    end

    // --- 메인 제어 FSM ---
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= S_IDLE;
            bit_cnt <= 0;
            ds1302_ce <= 0;
            ds1302_sclk <= 0;
            io_dir <= 1;
        end
        else if(clk_1mhz) begin
            case(state)
                // 대기 및 시작 판단
                S_IDLE: begin
                    bit_cnt <= 0;
                    if(load_req) begin
                        ds1302_ce <= 1;
                        write_buffer <= {
                            8'h00,               // Write Protect 해제
                            set_data[55:48],     // year
                            8'h00,               // day of week
                            set_data[39:32],     // month
                            set_data[31:24],     // date
                            set_data[23:16],     // hour
                            set_data[15:8],      // min
                            {1'b0,set_data[6:0]} // sec (CH=0)
                        };
                        state <= S_WRITE_CMD_L;
                    end
                    else begin
                        ds1302_ce <= 1;
                        state <= S_READ_CMD_L;
                    end
                end

                // --- 쓰기 명령어 전송 단계 ---
                S_WRITE_CMD_L: begin
                    if(bit_cnt < 8) begin
                        io_dir <= 1;
                        io_out <= write_cmd[bit_cnt];
                        ds1302_sclk <= 0;
                        state <= S_WRITE_CMD_H;
                    end else begin
                        bit_cnt <= 0;
                        state <= S_WRITE_DATA_L;
                    end
                end
                S_WRITE_CMD_H: begin
                    ds1302_sclk <= 1;
                    bit_cnt <= bit_cnt + 1;
                    state <= S_WRITE_CMD_L;
                end

                // --- 실제 데이터 쓰기 단계 ---
                S_WRITE_DATA_L: begin
                    if(bit_cnt < 64) begin
                        io_out <= write_buffer[bit_cnt];
                        ds1302_sclk <= 0;
                        state <= S_WRITE_DATA_H;
                    end else begin
                        ds1302_ce <= 0;
                        state <= S_IDLE;
                    end
                end
                S_WRITE_DATA_H: begin
                    ds1302_sclk <= 1;
                    bit_cnt <= bit_cnt + 1;
                    state <= S_WRITE_DATA_L;
                end

                // --- 읽기 명령어 전송 단계 ---
                S_READ_CMD_L: begin
                    if(bit_cnt < 8) begin
                        io_dir <= 1;
                        io_out <= read_cmd[bit_cnt];
                        ds1302_sclk <= 0;
                        state <= S_READ_CMD_H;
                    end else begin
                        bit_cnt <= 0;
                        io_dir <= 0; // 명령어 전송 후 입력 모드로 전환
                        state <= S_READ_DATA_L;
                    end
                end
                S_READ_CMD_H: begin
                    ds1302_sclk <= 1;
                    bit_cnt <= bit_cnt + 1;
                    state <= S_READ_CMD_L;
                end

                // --- 실제 데이터 읽기 단계 ---
                S_READ_DATA_L: begin
                    if(bit_cnt < 64) begin
                        ds1302_sclk <= 0;
                        state <= S_READ_DATA_H;
                    end else begin
                        state <= S_FINISH;
                    end
                end
                S_READ_DATA_H: begin
                    read_buffer[bit_cnt] <= ds1302_io; // SCLK 상승 에지에서 샘플링
                    ds1302_sclk <= 1;
                    bit_cnt <= bit_cnt + 1;
                    state <= S_READ_DATA_L;
                end

                // 통신 종료
                S_FINISH: begin
                    ds1302_ce <= 0;
                    ds1302_sclk <= 0;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // --- 최종 출력 할당 (BCD 데이터) ---
    assign out_sec   = read_buffer[7:0];
    assign out_min   = read_buffer[15:8];
    assign out_hour  = read_buffer[23:16];
    assign out_day   = read_buffer[31:24];
    assign out_month = read_buffer[39:32];
    assign out_year  = read_buffer[55:48];

endmodule
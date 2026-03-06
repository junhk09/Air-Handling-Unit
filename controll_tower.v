`timescale 1ns / 1ps

module controll_tower(
    input clk, input reset,
    input [7:0] rtc_hour, input [7:0] rtc_min,
    output [7:0] seg, output [3:0] an
);
    reg [3:0] r_digit;
    reg [1:0] r_fnd_select;
    wire w_fnd_tick;

    tick_gen #(.Tick_Hz(1000)) u_fnd_tick (.clk(clk), .reset(reset), .tick(w_fnd_tick)); 

    always @(posedge clk) begin
        if(reset) r_fnd_select <= 0;
        else if(w_fnd_tick) r_fnd_select <= r_fnd_select + 1;
    end

    always @(*) begin
        case(r_fnd_select)
            2'b00: r_digit = rtc_min[3:0];
            2'b01: r_digit = rtc_min[7:4];
            2'b10: r_digit = rtc_hour[3:0];
            2'b11: r_digit = rtc_hour[7:4];
        endcase
    end

    assign an = (r_fnd_select == 2'b00) ? 4'b1110 : (r_fnd_select == 2'b01) ? 4'b1101 :
                (r_fnd_select == 2'b10) ? 4'b1011 : 4'b0111; 

    assign seg = (r_digit == 4'h0) ? 8'hc0 : (r_digit == 4'h1) ? 8'hf9 :
                 (r_digit == 4'h2) ? 8'ha4 : (r_digit == 4'h3) ? 8'hb0 :
                 (r_digit == 4'h4) ? 8'h99 : (r_digit == 4'h5) ? 8'h92 :
                 (r_digit == 4'h6) ? 8'h82 : (r_digit == 4'h7) ? 8'hf8 :
                 (r_digit == 4'h8) ? 8'h80 : (r_digit == 4'h9) ? 8'h90 : 8'hff; 
endmodule
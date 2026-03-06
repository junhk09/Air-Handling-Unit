`timescale 1ns / 1ps

   module tick_gen #( // 100MHz, 1KHz
    parameter INPUT_FREQUENCY =100_000_000, parameter Tick_Hz=1000)
   (
           input clk,
           input reset,
          output reg tick
    ); 
    parameter TICK_COUNT=INPUT_FREQUENCY/Tick_Hz; // 100_000

    reg [$clog2(TICK_COUNT)-1:0] r_tick_counter=0; //log함수로 필요한 bit수 자동계산

    always@(posedge clk, posedge reset) begin
        if(reset) begin
            tick<=0;
            r_tick_counter<=0;

        end else begin
            if(r_tick_counter==TICK_COUNT-1) begin
                r_tick_counter<=0;
                tick <=1'b1;
            end else begin
                r_tick_counter<=r_tick_counter +1;
                tick<=1'b0;
            end
        end

    end
    endmodule

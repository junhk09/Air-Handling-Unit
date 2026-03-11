module clock_div_100(
    input clk, 
    input reset,
    output clk_div_100
    );

    reg [6:0] cnt;
    // 100MHz / 100 = 1MHz (1us period)
    always @(posedge clk or posedge reset) begin
        if(reset) cnt <= 0;
        else if(cnt >= 99) cnt <= 0;
        else cnt <= cnt + 1;
    end

    assign clk_div_100 = (cnt == 99);
endmodule
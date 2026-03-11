module mode_switch_controller(
    input clk, reset, tick,
    output reg mode_out
);
    always @(posedge clk or posedge reset) begin
        if(reset) mode_out <= 0;
        else if(tick) mode_out <= ~mode_out;
    end
endmodule
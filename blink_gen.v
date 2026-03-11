module blink_gen(
    input clk, reset,
    output blink_out
);
    reg [24:0] count;
    always @(posedge clk or posedge reset) begin
        if(reset) count <= 0;
        else      count <= count + 1;
    end
    assign blink_out = count[24];
endmodule
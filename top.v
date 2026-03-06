module top(
    input clk, input reset,
    output RsTx, input RsRx,
    output [7:0] seg, output [3:0] an,
    output ds1302_sclk, // JC1
    inout  ds1302_io,   // JC2
    output ds1302_ce    // JC3
);
    wire [7:0] y, m, d, h, min, s;
    wire w_1Hz, w_tx_start, w_tx_busy;
    wire [7:0] w_tx_data;

    ds1302_controller u_rtc (.clk(clk), .reset(reset), .ds1302_sclk(ds1302_sclk), 
        .ds1302_ce(ds1302_ce), .ds1302_io(ds1302_io), 
        .out_year(y), .out_month(m), .out_day(d), .out_hour(h), .out_min(min), .out_sec(s));

    tick_gen #(.Tick_Hz(1)) u_trig (.clk(clk), .reset(reset), .tick(w_1Hz));

    data_sender u_send (.clk(clk), .reset(reset), .start_trigger(w_1Hz),
        .r_year(y), .r_month(m), .r_day(d), .r_hour(h), .r_min(min), .r_sec(s),
        .tx_busy(w_tx_busy), .tx_start(w_tx_start), .tx_data(w_tx_data));

    uart_tx #(.BPS(9600)) u_tx (.clk(clk), .reset(reset), .tx_data(w_tx_data), 
        .tx_start(w_tx_start), .tx(RsTx), .tx_busy(w_tx_busy));

    controll_tower u_fnd (.clk(clk), .reset(reset), .rtc_hour(h), .rtc_min(min), .seg(seg), .an(an));
endmodule
module edge_detector_n(
    input clk, 
    input reset, 
    input cp,
    output p_edge, n_edge
    );

    reg ff1, ff2;
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else begin
            ff1 <= cp;
            ff2 <= ff1;
        end
    end
    assign p_edge = (ff1 && !ff2);
    assign n_edge = (!ff1 && ff2);
endmodule
module dht11_controller(
      input clk,
      input reset,
      inout dht11_data,
      output reg [7:0] humidity,
      output reg [7:0] temperature,
      output reg done,           // 추가됨
      output [3:0] state_out     // 추가됨
); 
      
      parameter S_IDLE = 6'b00_0001;
      parameter S_LOW_18MS = 6'b00_0010;
      parameter S_HIGH_20US = 6'b00_0100;
      parameter S_LOW_80US = 6'b00_1000;
      parameter S_HIGH_80US = 6'b01_0000;
      parameter S_READ_DATA = 6'b10_0000;
      
      parameter S_WAIT_PEDGE = 2'b01;
      parameter S_WAIT_NEDGE = 2'b10;
      
      reg [21:0] count_usec;
      wire clk_usec;
      reg count_usec_e;
      
      clock_div_100 us_clk(.clk(clk), .reset(reset), .clk_div_100(clk_usec));
      
      always @(negedge clk or posedge reset) begin
            if(reset) count_usec <= 0;
            else if(clk_usec && count_usec_e) count_usec <= count_usec + 1;
            else if(count_usec_e == 0) count_usec <= 0;
      end
      
      wire dht_pedge, dht_nedge;
      edge_detector_n ed(
            .clk(clk), .reset(reset), .cp(dht11_data), 
            .p_edge(dht_pedge), .n_edge(dht_nedge)); 
      
      reg [5:0] state, next_state;
      reg [1:0] read_state;
      reg [39:0] temp_data;
      reg [5:0] data_count;
      reg dht11_buffer;

      assign dht11_data = dht11_buffer;
      assign state_out = state[3:0]; // 현재 상태 하위 4비트 출력

      always @(negedge clk or posedge reset) begin
            if(reset) state <= S_IDLE;
            else state <= next_state;
      end
      
      always @(posedge clk or posedge reset) begin
            if(reset) begin
                  count_usec_e <= 0;
                  next_state <= S_IDLE;
                  read_state <= S_WAIT_PEDGE;
                  data_count <= 0;
                  dht11_buffer <= 'bz;
                  done <= 0;
            end
            else begin
                  case(state)
                        S_IDLE: begin
                              done <= 0;
                              if(count_usec < 22'd3_000_000) begin 
                                    count_usec_e <= 1;
                                    dht11_buffer <= 'bz;
                              end
                              else begin
                                    next_state <= S_LOW_18MS;
                                    count_usec_e <= 0;
                              end
                        end

                        S_LOW_18MS: begin
                              if(count_usec < 22'd18_000) begin
                                    dht11_buffer <= 0;
                                    count_usec_e <= 1;
                              end
                              else begin
                                    next_state <= S_HIGH_20US;
                                    count_usec_e <= 0;
                                    dht11_buffer <= 'bz;
                              end
                        end      

                        S_HIGH_20US: begin
                              count_usec_e <= 1;
                              if(count_usec > 22'd100_000) begin
                                    next_state <= S_IDLE;
                                    count_usec_e <= 0;
                              end
                              if(dht_nedge) begin
                                    next_state <= S_LOW_80US;
                                    count_usec_e <= 0;
                              end      
                        end

                        S_LOW_80US: begin
                              count_usec_e <= 1;
                              if(count_usec > 22'd100_000) begin
                                    next_state <= S_IDLE;
                                    count_usec_e <= 0;
                              end
                              if(dht_pedge) begin
                                    next_state <= S_HIGH_80US;
                              end
                        end

                        S_HIGH_80US: begin
                              if(dht_nedge) begin
                                    next_state <= S_READ_DATA;
                              end
                        end

                        S_READ_DATA: begin
                              case(read_state)
                                    S_WAIT_PEDGE: begin
                                          if(dht_pedge) read_state <= S_WAIT_NEDGE;
                                          count_usec_e <= 0;
                                    end

                                    S_WAIT_NEDGE: begin
                                          if(dht_nedge) begin
                                                if(count_usec < 45) begin
                                                      temp_data <= {temp_data[38:0], 1'b0}; 
                                                end
                                                else begin
                                                      temp_data <= {temp_data[38:0], 1'b1}; 
                                                end
                                                data_count <= data_count + 1;
                                                read_state <= S_WAIT_PEDGE;
                                          end
                                          else count_usec_e <= 1;

                                          if(count_usec > 22'd700_000) begin
                                                next_state <= S_IDLE;
                                                count_usec_e <= 0;
                                                data_count <= 0;
                                                read_state <= S_WAIT_PEDGE;
                                          end
                                    end
                              endcase

                              if(data_count >= 40) begin
                                    data_count <= 0;
                                    next_state <= S_IDLE;
                                    if((temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8]) == temp_data[7:0]) begin
                                          humidity <= temp_data[39:32];
                                          temperature <= temp_data[23:16];
                                          done <= 1; // 체크섬 통과 시 완료 신호
                                    end
                              end
                        end
                        default: next_state <= S_IDLE;
                  endcase
            end
      end
endmodule
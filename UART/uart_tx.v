module uart_tx (input rst,
                input clk,
                input [31 : 0] period,
                input in_sync,
                input [7 : 0] in_data,
                output tx);
    
    reg [3 : 0] state;
    reg [3 : 0] state_next;
    localparam STATE_RESET = 4'h0;
    localparam STATE_IDEL  = 4'h1;
    localparam STATE_RD    = 4'h2;
    localparam STATE_START = 4'h3;
    localparam STATE_SEND  = 4'h4;
    localparam STATE_STOP  = 4'h5;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_RESET;
        end
        else begin
            state <= state_next;
        end
    end
    
    reg [31 : 0] period_counter;
    reg period_counter_en;
    reg period_counter_break;
    
    always @(posedge clk) begin
        if (rst) begin
            period_counter       <= 32'b0;
            period_counter_break <= 0;
        end
        else begin
            if (period_counter_en) begin
                if (period_counter < period - 1) begin
                    period_counter       <= period_counter + 1;
                    period_counter_break <= 0;
                end
                else begin
                    period_counter       <= 32'b0;
                    period_counter_break <= 1;
                end
            end
            else begin
                period_counter       <= 0;
                period_counter_break <= 0;
            end
        end
    end
    
    reg [2 : 0] send_bit_counter;
    reg send_bit_counter_en;
    reg send_bit_counter_break;
    
    always @(posedge clk) begin
        if (rst) begin
            send_bit_counter       <= 32'b0;
            send_bit_counter_break <= 0;
        end
        else begin
            if (send_bit_counter_en && state == STATE_SEND) begin
                if (send_bit_counter < 7) begin
                    if (period_counter_break) begin
                        send_bit_counter       <= send_bit_counter + 1;
                        send_bit_counter_break <= 0;
                    end
                    else begin
                        send_bit_counter       <= send_bit_counter;
                        send_bit_counter_break <= 0;
                    end
                end
                else
                begin
                    if (period_counter_break) begin
                        send_bit_counter       <= 3'b0;
                        send_bit_counter_break <= 1;
                    end
                    else begin
                        send_bit_counter       <= send_bit_counter;
                        send_bit_counter_break <= 0;
                    end
                end
            end
            else begin
                send_bit_counter       <= 0;
                send_bit_counter_break <= 0;
            end
        end
    end
    
    always @(*) begin
        case (state)
            STATE_RESET : begin
                period_counter_en   = 0;
                send_bit_counter_en = 0;
                
                state_next = STATE_IDEL;
            end
            
            STATE_IDEL : begin
                period_counter_en   = 0;
                send_bit_counter_en = 0;
                
                if (in_sync) begin
                    state_next = STATE_RD;
                end
                else begin
                    state_next = STATE_IDEL;
                end
            end
            
            STATE_RD : begin
                period_counter_en   = 1;
                send_bit_counter_en = 0;
                
                state_next = STATE_START;
            end
            
            STATE_START : begin
                if (period_counter_break) begin
                    period_counter_en   = 1;
                    send_bit_counter_en = 1;
                    
                    state_next = STATE_SEND;
                end
                else begin
                    state_next = STATE_START;
                end
            end
            
            STATE_SEND : begin
                if (send_bit_counter_break) begin
                    period_counter_en   = 1;
                    send_bit_counter_en = 0;
                    
                    state_next = STATE_STOP;
                end
                else begin
                    state_next = STATE_SEND;
                end
            end
            
            STATE_STOP : begin
                if (period_counter_break) begin
                    period_counter_en   = 0;
                    send_bit_counter_en = 0;
                    
                    state_next = STATE_IDEL;
                end
                else begin
                    state_next = STATE_STOP;
                end
            end
            
            default: begin
                period_counter_en = 0;
                period_counter_en = 0;
                
                state_next = STATE_RESET;
            end
        endcase
    end
    
    reg [7 : 0] tx_data_r;
    reg tx_r;
    
    assign tx = tx_r;
    
    always @(*) begin
        case (state)
            STATE_RESET : begin
                tx_data_r = 8'b0;
                tx_r      = 1;
            end
            
            STATE_IDEL : begin
                tx_data_r = 8'b0;
                tx_r      = 1;
            end
            
            STATE_RD : begin
                tx_data_r = in_data;
                tx_r      = 1;
            end
            
            STATE_START : begin
                tx_r = 0;
            end
            
            STATE_SEND : begin
                tx_r = tx_data_r[send_bit_counter];
            end
            
            STATE_STOP : begin
                tx_r = 1;
            end
            
            default: begin
                tx_data_r = 8'b0;
                tx_r      = 1;
            end
        endcase
    end
    
endmodule

module uart_rx (input rst,
                input clk,
                input [31 : 0] period,    // number of pulse each cycles
                input rx,
                output out_sync,
                output [7 : 0] out_data);
    
    reg [3 : 0] state;
    reg [3 : 0] state_next;
    localparam STATE_RESET = 4'h0;
    localparam STATE_IDEL  = 4'h1;
    localparam STATE_START = 4'h2;
    localparam STATE_RECV  = 4'h3;
    localparam STATE_STOP  = 4'h4;
    localparam STATE_SYNC  = 4'h5;
    localparam STATE_SEND  = 4'h6;
    
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
    
    reg [2 : 0] recv_bit_counter;
    reg recv_bit_counter_en;
    reg recv_bit_counter_break;
    
    always @(posedge clk) begin
        if (rst) begin
            recv_bit_counter       <= 32'b0;
            recv_bit_counter_break <= 0;
        end
        else begin
            if (recv_bit_counter_en && state == STATE_RECV) begin
                if (recv_bit_counter < 7) begin
                    if (period_counter_break) begin
                        recv_bit_counter       <= recv_bit_counter + 1;
                        recv_bit_counter_break <= 0;
                    end
                    else begin
                        recv_bit_counter       <= recv_bit_counter;
                        recv_bit_counter_break <= 0;
                    end
                end
                else
                begin
                    if (period_counter_break) begin
                        recv_bit_counter       <= 3'b0;
                        recv_bit_counter_break <= 1;
                    end
                    else begin
                        recv_bit_counter       <= recv_bit_counter;
                        recv_bit_counter_break <= 0;
                    end
                end
            end
            else begin
                recv_bit_counter       <= 0;
                recv_bit_counter_break <= 0;
            end
        end
    end
    
    always @(*) begin
        case (state)
            STATE_RESET : begin
                period_counter_en   = 0;
                recv_bit_counter_en = 0;
                
                state_next = STATE_IDEL;
            end
            
            STATE_IDEL  : begin
                if (!rx) begin
                    period_counter_en   = 1;
                    recv_bit_counter_en = 0;
                    state_next          = STATE_START;
                end
                else begin
                    period_counter_en   = 0;
                    recv_bit_counter_en = 0;
                    state_next          = STATE_IDEL;
                end
            end
            
            STATE_START : begin
                if (period_counter_break) begin
                    recv_bit_counter_en = 1;
                    state_next          = STATE_RECV;
                end
                else begin
                    state_next = STATE_START;
                end
            end
            
            STATE_RECV : begin
                if (recv_bit_counter_break) begin
                    recv_bit_counter_en = 0;
                    state_next          = STATE_STOP;
                end
                else begin
                    state_next = STATE_RECV;
                end
            end
            
            STATE_STOP : begin
                if (period_counter_break) begin
                    period_counter_en = 0;
                    state_next        = STATE_SYNC;
                end
                else begin
                    state_next = STATE_STOP;
                end
            end
            
            STATE_SYNC : begin
                state_next = STATE_SEND;
            end
            
            STATE_SEND : begin
                state_next = STATE_IDEL;
            end
            
            default : begin
                state_next = STATE_RESET;
            end
        endcase
    end
    
    reg [31 : 0] bit_h_num;
    reg [31 : 0] bit_h_num_next;
    reg [31 : 0] bit_l_num;
    reg [31 : 0] bit_l_num_next;
    reg bit_level;
    
    always @(posedge clk) begin
        if (rst) begin
            bit_h_num <= 32'b0;
            bit_l_num <= 32'b0;
        end
        else begin
            bit_h_num <= bit_h_num_next;
            bit_l_num <= bit_l_num_next;
        end
    end
    
    always @(*) begin
        if (state == STATE_RECV) begin
            if (period_counter_break) begin
                bit_level      = (bit_h_num > bit_l_num) ? 1 : 0;
                bit_h_num_next = 32'b0;
                bit_l_num_next = 32'b0;
            end
            else begin
                if (rx) begin
                    bit_h_num_next = bit_h_num + 1;
                end
                else begin
                    bit_l_num_next = bit_l_num + 1;
                end
            end
        end
        else begin
            bit_h_num_next = 32'b0;
            bit_l_num_next = 32'b0;
            bit_level      = 0;
        end
    end
    
    reg out_sync_r;
    reg out_sync_en;
    
    assign out_sync = out_sync_r;
    
    always @(negedge clk) begin
        if (out_sync_en) begin
            out_sync_r <= 1;
        end
        else begin
            out_sync_r <= 0;
        end
    end
    
    reg [7 : 0]out_data_r;
    reg [7 : 0]out_data_r_b;
    reg out_data_en;
    
    assign out_data = out_data_r;
    
    always @(negedge clk) begin
        if (out_data_en) begin
            out_data_r <= out_data_r_b;
        end
        else begin
            out_data_r <= 8'b0;
        end
    end
    
    always @(*) begin
        case (state)
            STATE_RESET : begin
                out_data_r_b = 8'b0;
                out_data_en  = 0;
                out_sync_en  = 0;
            end
            
            STATE_IDEL  : begin
                out_data_r_b = 8'b0;
                out_data_en  = 0;
                out_sync_en  = 0;
            end
            
            STATE_START : begin
                out_data_r_b = 8'b0;
                out_data_en  = 0;
                out_sync_en  = 0;
            end
            
            STATE_RECV  : begin
                if (period_counter_break) begin
                    out_data_r_b[recv_bit_counter] = bit_level;
                end
                else begin
                    out_data_r_b[recv_bit_counter] = out_data_r_b[recv_bit_counter];
                end
            end
            
            STATE_STOP  : begin
                out_data_en = 0;
                out_sync_en = 0;
            end
            
            STATE_SYNC : begin
                out_data_en = 0;
                out_sync_en = 1;
            end
            
            STATE_SEND  : begin
                out_data_en = 1;
                out_sync_en = 0;
            end
            
            default : begin
                out_data_r_b = 8'b0;
                out_data_en  = 0;
                out_sync_en  = 0;
            end
        endcase
    end
    
endmodule

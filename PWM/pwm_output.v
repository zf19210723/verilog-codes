module pwm_output (input rst,
                   input clk,
                   output pwm,
                   input [31 : 0] low_level_width,
                   input [31 : 0] high_level_width);
    
    reg [31 : 0] low_level_counter;
    reg [31 : 0] low_level_counter_next;
    
    always @(posedge clk) begin
        if (rst) begin
            low_level_counter <= 32'b0;
        end
        else begin
            low_level_counter <= low_level_counter_next;
        end
    end
    
    reg [31 : 0] high_level_counter;
    reg [31 : 0] high_level_counter_next;
    
    always @(posedge clk) begin
        if (rst) begin
            high_level_counter <= 32'b0;
        end
        else begin
            high_level_counter <= high_level_counter_next;
        end
    end
    
    reg [3 : 0] state;
    reg [3 : 0] state_next;
    localparam STATE_RESET = 4'h0;
    localparam STATE_LOW   = 4'h1;
    localparam STATE_HIGH  = 4'h2;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_RESET;
        end
        else begin
            state <= state_next;
        end
    end
    
    always @(*) begin
        case (state)
            STATE_RESET : begin
                low_level_counter_next  = 32'b0;
                high_level_counter_next = 32'b0;
                
                state_next = STATE_LOW;
            end
            
            STATE_LOW : begin
                if (low_level_counter < low_level_width - 1) begin
                    low_level_counter_next = low_level_counter + 1;
                    state_next             = STATE_LOW;
                end
                else begin
                    low_level_counter_next = 32'b0;
                    state_next             = STATE_HIGH;
                end
            end
            
            STATE_HIGH : begin
                if (high_level_counter < high_level_width - 1) begin
                    high_level_counter_next = high_level_counter + 1;
                    state_next              = STATE_HIGH;
                end
                else begin
                    high_level_counter_next = 32'b0;
                    state_next              = STATE_LOW;
                end
            end
            
            default: begin
                state_next = STATE_RESET;
            end
        endcase
    end
    
    reg pwm_r;
    assign pwm = pwm_r;
    
    always @(*) begin
        case (state)
            STATE_RESET : begin
                pwm_r = 0;
            end
            
            STATE_LOW : begin
                pwm_r = 0;
            end
            
            STATE_HIGH : begin
                pwm_r = 1;
            end
            
            default: begin
                pwm_r = 0;
            end
        endcase
    end
endmodule

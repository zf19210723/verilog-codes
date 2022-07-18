module pwm_bus_interface (input rst,
                          input clk,
                          output pwm,
                          input sync,
                          input [31 : 0] clk_freq, // kHz
                          input [31 : 0] pwm_freq, // kHz
                          input [31 : 0] duty);
    
    reg [3 : 0] state;
    reg [3 : 0] state_next;
    localparam STATE_RESET = 4'h0;
    localparam STATE_IDEL  = 4'h1;
    localparam STATE_CALC  = 4'h2;
    localparam STATE_READ  = 4'h3;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_RESET;
        end
        else begin
            state <= state_next;
        end
    end
    
    reg [31 : 0] low_level_width_r;
    reg [31 : 0] high_level_width_r;
    
    pwm_output pwm_output_inst (
    .rst (rst),
    .clk (clk),
    
    .pwm (pwm),
    
    .low_level_width (low_level_width_r),
    .high_level_width (high_level_width_r)
    );
    
    always @(*) begin
        case(state)
            STATE_RESET : begin
                state_next = STATE_IDEL;
            end
            
            STATE_IDEL  : begin
                if (sync) begin
                    state_next = STATE_READ;
                end
                else begin
                    state_next = STATE_IDEL;
                end
            end
            
            STATE_READ  : begin
                state_next = STATE_CALC;
            end
            
            STATE_CALC : begin
                state_next = STATE_IDEL;
            end
            
            default : begin
                state_next = STATE_RESET;
            end
        endcase
    end
    
    reg [31 : 0] clk_freq_r;
    reg [31 : 0] pwm_freq_r;
    reg [31 : 0] duty_r;
    reg [31 : 0] cycles;
    
    always @(*) begin
        case(state)
            STATE_RESET : begin
                clk_freq_r = 32'd0;
                pwm_freq_r = 32'd0;
                duty_r     = 32'd0;
                
                high_level_width_r = 32'd100;
                low_level_width_r  = 32'd100;
            end
            
            STATE_IDEL  : begin
                clk_freq_r = 32'd0;
                pwm_freq_r = 32'd0;
                duty_r     = 32'd0;

                low_level_width_r  = low_level_width_r;
                high_level_width_r = low_level_width_r;
            end
            
            STATE_READ : begin
                clk_freq_r = clk_freq;
                pwm_freq_r = pwm_freq;
                duty_r     = duty;

                low_level_width_r  = low_level_width_r;
                high_level_width_r = low_level_width_r;
            end
            
            STATE_CALC  : begin
                cycles             = clk_freq_r / pwm_freq_r;
                high_level_width_r = cycles * duty_r / {32'b0, 32'b1};
                low_level_width_r  = cycles - high_level_width_r;
            end
            
            default : begin
                clk_freq_r = 32'd0;
                pwm_freq_r = 32'd0;
                duty_r     = 32'd0;

                high_level_width_r = 32'd100;
                low_level_width_r  = 32'd100;
            end
        endcase
    end
    
endmodule

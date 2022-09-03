module axi_lite_pwm (
           input axi_lite_aclk,
           input axi_lite_aresetn,

           //PWM
           output pwm,

           //AXI Lite interface
           input [31 : 0] axi_lite_awaddr,
           input axi_lite_awvalid,
           output reg axi_lite_awready,

           input [31 : 0] axi_lite_wdata,
           input axi_lite_wvalid,
           output reg axi_lite_wready,

           output reg [1 : 0] axi_lite_bresp,
           output reg axi_lite_bvalid,
           input axi_lite_bready
       );

reg [7 : 0] state;
reg [7 : 0] state_next;
parameter STATE_RESET = 8'h0;
parameter STATE_IDEL = 8'h1;
parameter STATE_WRITE_REG = 8'h3;
parameter STATE_WRITE_BUF = 8'h4;
parameter STATE_CALC = 8'h5;
parameter STATE_RESP = 8'h6;

always @(posedge axi_lite_aclk) begin
    if (!axi_lite_aresetn) begin
        state <= STATE_RESET;
    end
    else begin
        state <= state_next;
    end
end

reg [31 : 0] addr_buf;
reg [31 : 0] data_buf;
reg [1 : 0] resp_buf;

reg [31 : 0] clk_freq_base;
reg [31 : 0] clk_freq_coefficient;
/*
[clock frequence] = clk_freq_base * (2 ^ clk_freq_coefficient)
*/
reg [31 : 0] pwm_frequence;
reg [31 : 0] duty;

always @( * ) begin
    case (state)
        STATE_RESET: begin
            state_next = STATE_IDEL;
        end

        STATE_IDEL: begin
            if (axi_lite_awvalid) begin
                state_next = STATE_WRITE_REG;
            end
            else begin
                state_next = STATE_IDEL;
            end
        end

        STATE_WRITE_REG: begin
            if (axi_lite_wvalid) begin
                state_next = STATE_WRITE_BUF;
            end
            else begin
                state_next = STATE_WRITE_REG;
            end
        end

        STATE_WRITE_BUF: begin
            if ((clk_freq_base == 32'h0) || (clk_freq_coefficient == 32'h0) || (pwm_frequence == 32'h0) || (duty == 32'h0)) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_CALC;
            end
        end

        STATE_CALC: begin
            state_next = STATE_RESP;
        end

        STATE_RESP: begin
            if (axi_lite_bready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_RESP;
            end
        end

        default: begin

        end
    endcase
end

reg [31 : 0] cycle;
reg [31 : 0] high_level_cycle;

pwm_core pwm_core_inst(
             .rstn(axi_lite_aresetn),
             .clk(axi_lite_aclk),
             .pwm(pwm),
             .cycle(cycle),
             .high_level_cycle(high_level_cycle)
         );

always @( * ) begin
    case (state)
        STATE_RESET: begin
            axi_lite_awready = 0;
            axi_lite_wready = 0;
            axi_lite_bvalid = 0;

            axi_lite_bresp = 2'b0;

            cycle = 100;
            high_level_cycle = 10;

            addr_buf = 32'h0;
            data_buf = 32'h0;
            resp_buf = 2'b0;

            clk_freq_base = 32'h0;
            clk_freq_coefficient = 32'h0;
            pwm_frequence = 32'h0;
            duty = 32'h0;
        end

        STATE_IDEL: begin
            axi_lite_awready = 1;
            axi_lite_wready = 0;
            axi_lite_bvalid = 0;

            axi_lite_bresp = 2'b0;

            data_buf = 32'h0;
            resp_buf = 2'b0;

            if (axi_lite_awvalid) begin
                addr_buf = axi_lite_awaddr;
            end
            else begin
                addr_buf = 32'h0;
            end
        end

        STATE_WRITE_REG: begin
            axi_lite_awready = 0;
            axi_lite_wready = 1;

            if (axi_lite_wvalid) begin
                data_buf = axi_lite_wdata;
            end
            else begin
                data_buf = 32'b0;
            end
        end

        STATE_WRITE_BUF: begin
            case (addr_buf)
                32'h0000_0000: begin
                    clk_freq_base = data_buf;
                    resp_buf = 2'b01;
                end

                32'h0000_0004: begin
                    clk_freq_coefficient = data_buf;
                    resp_buf = 2'b01;
                end

                32'h0000_0008: begin
                    pwm_frequence = data_buf;
                    resp_buf = 2'b01;
                end

                32'h0000_000c: begin
                    duty = data_buf;
                    resp_buf = 2'b01;
                end

                default: begin
                    resp_buf = 2'b10;
                end
            endcase
        end

        STATE_CALC: begin
            cycle = (clk_freq_base << clk_freq_coefficient) / pwm_frequence;
            high_level_cycle = cycle * 100 / duty;
        end

        STATE_RESP: begin
            if (axi_lite_bready) begin
                axi_lite_bresp = resp_buf;
            end
            else begin
                axi_lite_bresp = 2'b0;
            end
        end

        default: begin
            axi_lite_awready = 0;
            axi_lite_wready = 0;
            axi_lite_bvalid = 0;

            axi_lite_bresp = 2'b0;

            cycle = 100;
            high_level_cycle = 10;

            addr_buf = 32'h0;
            data_buf = 32'h0;
            resp_buf = 2'b0;

            clk_freq_base = 32'h0;
            clk_freq_coefficient = 32'h0;
            pwm_frequence = 32'h0;
            duty = 32'h0;
        end
    endcase
end

endmodule

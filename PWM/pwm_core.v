module pwm_core (
           input rstn,
           input clk,
           output reg pwm,
           input [31 : 0] cycle,
           input [31 : 0] high_level_cycle);

reg [31 : 0] pwm_counter;
always @(posedge clk) begin
    if ((!rstn)) begin
        pwm_counter <= 32'h0;
    end
    else begin
        if (pwm_counter < cycle - 1) begin
            pwm_counter <= pwm_counter + 1;
        end
        else begin
            pwm_counter <= 32'h0;
        end
    end
end

always @( * ) begin
    if (!rstn) begin
        pwm = 0;
    end
    else begin
        if (pwm_counter < high_level_cycle - 1) begin
            pwm = 1;
        end
        else begin
            pwm = 0;
        end
    end
end

endmodule
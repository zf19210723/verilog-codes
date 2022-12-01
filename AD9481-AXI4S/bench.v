`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2022 02:59:42 PM
// Design Name: 
// Module Name: bench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bench ();

    reg clk = 0;
    always #2.5 clk = ~clk;

    reg          rst = 1;

    wire         adc_clk;
    wire         adc_pdn;

    reg  [7 : 0] adc_data_a = 8'b0;
    reg  [7 : 0] adc_data_b = 8'b0;

    main main_inst (
        .pl_key(~rst),

        .osc_200m_p(clk),
        .osc_200m_n(~clk),

        .fan_control(),

        .led_control(),

        .adc_clk(adc_clk),
        .adc_pdn(adc_pdn),

        .adc_data_a_clk(adc_clk),
        .adc_data_b_clk(~adc_clk),

        .adc_data_a(adc_data_a),
        .adc_data_b(adc_data_b)
    );

    always @(negedge adc_clk) begin
        if (rst) begin
            adc_data_a <= 8'b0;
        end else begin
            adc_data_a <= adc_data_a + 1;
        end
    end

    always @(posedge adc_clk) begin
        if (rst) begin
            adc_data_b <= 8'b0;
        end else begin
            adc_data_b <= adc_data_b + 1;
        end
    end

    initial begin
        #100 rst = 0;
    end

endmodule

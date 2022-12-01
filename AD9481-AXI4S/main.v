`timescale 1ns / 1ps

module main (
    input pl_key,

    //ref clk
    input osc_200m_p,
    input osc_200m_n,

    //fan
    output fan_control,

    //led
    output led_control,

    //ADC
    output adc_clk,
    output adc_pdn,

    input adc_data_a_clk,
    input adc_data_b_clk,
    input [7 : 0] adc_data_a,
    input [7 : 0] adc_data_b
);
    assign fan_control = 1;

    // OSC clock input buffer
    wire osc_200m;
    IBUFGDS osc_inbuf (
        .I (osc_200m_p),
        .IB(osc_200m_n),
        .O (osc_200m)
    );

    // MMCM for system and ADC
    wire sys_rstn;
    wire sys_clk;
    wire adc_basic_clk;
    mmcm_main mmcm_main_inst (
        .clk_in1(osc_200m),
        .reset  (~pl_key),

        .clk_out1(sys_clk),
        .clk_out2(adc_basic_clk),

        .locked(sys_rstn)
    );

    // ADC clock buffer
    wire adc_data_a_clk_i;
    wire adc_data_b_clk_i;
    IBUFG clka_ibuf(
        .I(adc_data_a_clk),
        .O(adc_data_a_clk_i)
    );

    IBUFG clkb_ibuf(
        .I(adc_data_b_clk),
        .O(adc_data_b_clk_i)
    );

    // ADC data Reciver
    wire          axis_tvalid;
    wire [15 : 0] axis_tdata;
    wire [ 1 : 0] axis_tkeep;
    wire          axis_tlast;
    ad9481 ad9481_inst (
        .axis_aresetn(sys_rstn),
        .axis_aclk   (sys_clk),

        .adc_basic_clk (adc_basic_clk),
        .adc_clk       (adc_clk),
        .adc_pdn       (adc_pdn),
        .adc_data_a_clk(adc_data_a_clk_i),
        .adc_data_b_clk(adc_data_b_clk_i),
        .adc_data_a    (adc_data_a),
        .adc_data_b    (adc_data_b),

        .axis_tvalid(axis_tvalid),
        .axis_tready(1),
        .axis_tdata (axis_tdata),
        .axis_tkeep (axis_tkeep),
        .axis_tlast (axis_tlast)
    );

    // ILA
    ila_0 ila_0 (
        .clk(sys_clk),

        .probe0(axis_tvalid),
        .probe1(axis_tdata),
        .probe2(axis_tkeep),
        .probe3(axis_tlast)
    );

    // Other
    assign led_control = axis_tvalid;

endmodule

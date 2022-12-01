`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2022 09:24:42 AM
// Design Name: 
// Module Name: ad9481
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

module ad9481 (
    input axis_aresetn,
    input axis_aclk,

    //ADC interface
    input              adc_basic_clk,
    output             adc_clk,
    output reg         adc_pdn,
    input              adc_data_a_clk,
    input              adc_data_b_clk,
    input      [7 : 0] adc_data_a,
    input      [7 : 0] adc_data_b,

    //AXI4-Stream Transmitter interface
    output reg          axis_tvalid,
    input               axis_tready,
    output reg [15 : 0] axis_tdata,
    output reg [ 1 : 0] axis_tkeep,
    output reg          axis_tlast
);
  //Generate ADC clock
  assign adc_clk = adc_basic_clk;

  // ADC ready flag
  reg flag_adc_ready;
  always @(posedge adc_data_a_clk, posedge adc_pdn) begin
    if ((!axis_aresetn) || (adc_pdn == 1)) begin
      flag_adc_ready <= 0;
    end else begin
      flag_adc_ready <= 1;
    end
  end

  // FIFO
  reg           fifo_wr_dv;
  wire          fifo_full;
  wire          fifo_empty;
  reg           fifo_rd_dv;
  wire          fifo_wr_rst_busy;
  wire          fifo_rd_rst_busy;
  wire [15 : 0] fifo_data_rd;
  fifo_adc fifo_adc_inst (
      .srst(~axis_aresetn),

      .wr_clk(adc_data_b_clk),
      .wr_en (fifo_wr_dv),
      .din   ({adc_data_a, adc_data_b}),
      .full  (fifo_full),

      .rd_clk(axis_aclk),
      .rd_en (fifo_rd_dv),
      .dout  (fifo_data_rd),
      .empty (fifo_empty),

      .wr_rst_busy(fifo_wr_rst_busy),
      .rd_rst_busy(fifo_rd_rst_busy)
  );

  //AXI4 Stream FSM
  localparam STATE_RESET = 8'h0;
  localparam STATE_IDEL = 8'h1;
  localparam STATE_RECV_ADC_DATA = 8'h2;
  localparam STATE_WAIT_TRANS = 8'h3;
  localparam STATE_TRANS = 8'h4;
  reg [7 : 0] state;
  reg [7 : 0] state_next;

  always @(posedge axis_aclk) begin
    if (!axis_aresetn) begin
      state <= STATE_RESET;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    case (state)
      STATE_RESET: begin
        state_next = STATE_IDEL;
      end

      STATE_IDEL: begin
        if (flag_adc_ready) begin
          state_next = STATE_RECV_ADC_DATA;
        end else begin
          state_next = STATE_IDEL;
        end
      end

      STATE_RECV_ADC_DATA: begin
        if (fifo_full) begin
          state_next = STATE_WAIT_TRANS;
        end else begin
          state_next = STATE_RECV_ADC_DATA;
        end
      end

      STATE_WAIT_TRANS: begin
        if (axis_tready && axis_tvalid) begin
          state_next = STATE_TRANS;
        end else begin
          state_next = STATE_WAIT_TRANS;
        end
      end

      STATE_TRANS: begin
        if (fifo_empty && axis_tready) begin
          state_next = STATE_IDEL;
        end else begin
          state_next = STATE_TRANS;
        end
      end

      default: begin
        state_next = STATE_RESET;
      end
    endcase
  end

  always @(*) begin
    case (state)
      STATE_RESET: begin
        adc_pdn     = 1;

        axis_tvalid = 0;
        axis_tdata  = 16'h0;
        axis_tkeep  = 2'b0;
        axis_tlast  = 0;

        fifo_wr_dv  = 0;
        fifo_rd_dv  = 0;
      end

      STATE_IDEL: begin
        adc_pdn     = 0;

        axis_tvalid = 0;
        axis_tdata  = 16'h0;
        axis_tkeep  = 2'b0;
        axis_tlast  = 0;

        fifo_wr_dv  = 0;
        fifo_rd_dv  = 0;
      end

      STATE_RECV_ADC_DATA: begin
        adc_pdn     = 0;

        axis_tvalid = 0;
        axis_tdata  = 16'h0;
        axis_tkeep  = 2'b0;
        axis_tlast  = 0;

        fifo_wr_dv  = 1;
        fifo_rd_dv  = 0;
      end

      STATE_WAIT_TRANS: begin
        adc_pdn     = 1;

        axis_tvalid = 1;
        axis_tdata  = 16'h0;
        axis_tkeep  = 2'b0;
        axis_tlast  = 0;

        fifo_wr_dv  = 0;
        fifo_rd_dv  = 0;
      end

      STATE_TRANS: begin
        adc_pdn     = 1;

        axis_tvalid = 1;
        axis_tdata  = fifo_data_rd;
        axis_tkeep  = 2'b11;
        if (fifo_empty) begin
          axis_tlast = 1;
        end else begin
          axis_tlast = 0;
        end

        fifo_wr_dv = 0;
        fifo_rd_dv = 1;
      end

      default: begin
        adc_pdn     = 1;

        axis_tvalid = 0;
        axis_tdata  = 16'h0;
        axis_tkeep  = 2'b0;
        axis_tlast  = 0;

        fifo_wr_dv  = 0;
        fifo_rd_dv  = 0;
      end
    endcase
  end

endmodule

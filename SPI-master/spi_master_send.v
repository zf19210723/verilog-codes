module spi_master_send(
           input resetn,
           input clk,

           input [31 : 0] axi_lite_awaddr,
           output reg axi_lite_awready,
           input axi_lite_awvalid,

           input [31 : 0] axi_lite_wdata,
           output reg axi_lite_wready,
           input axi_lite_wvalid,
           input [3 : 0] axi_lite_wstrb,

           output reg [1 : 0] axi_lite_bresp,
           input axi_lite_bready,
           output reg axi_lite_bvalid,

           input spi_clk_send_int,
           output reg spi_clk_dv,
           output reg spi_miso
       );

reg [3 : 0] state;
reg [3 : 0] state_next;
parameter STATE_RESET = 4'h0;
parameter STATE_IDEL = 4'h1;
parameter STATE_RECV_ADDR = 4'h2;
parameter STATE_RECV_DATA = 4'h2;
parameter STATE_SEND_B7 = 4'h3;
parameter STATE_SEND_B6 = 4'h4;
parameter STATE_SEND_B5 = 4'h5;
parameter STATE_SEND_B4 = 4'h6;
parameter STATE_SEND_B3 = 4'h7;
parameter STATE_SEND_B2 = 4'h8;
parameter STATE_SEND_B1 = 4'h9;
parameter STATE_SEND_B0 = 4'ha;
parameter STATE_DONE = 4'hb;

always @(posedge clk) begin
    if (!resetn) begin
        state <= STATE_RESET;
    end
    else begin
        state <= state_next;
    end
end

always @( * ) begin
    case (state)
        STATE_RESET : begin
            state_next = STATE_IDEL;
        end

        STATE_IDEL : begin
            if (axi_lite_awvalid) begin
                state_next = STATE_RECV_DATA;
            end
            else begin
                state_next = STATE_IDEL;
            end
        end

        STATE_RECV_DATA : begin
            if (axi_lite_wvalid) begin
                state_next = STATE_SEND_B7;
            end
            else begin
                state_next = STATE_RECV_ADDR;
            end
        end

        STATE_SEND_B7 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B6;
            end
            else begin
                state_next = STATE_SEND_B7;
            end
        end

        STATE_SEND_B6 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B5;
            end
            else begin
                state_next = STATE_SEND_B6;
            end
        end

        STATE_SEND_B5 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B4;
            end
            else begin
                state_next = STATE_SEND_B5;
            end
        end

        STATE_SEND_B4 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B3;
            end
            else begin
                state_next = STATE_SEND_B4;
            end
        end

        STATE_SEND_B3 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B2;
            end
            else begin
                state_next = STATE_SEND_B3;
            end
        end

        STATE_SEND_B2 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B1;
            end
            else begin
                state_next = STATE_SEND_B2;
            end
        end

        STATE_SEND_B1 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_SEND_B0;
            end
            else begin
                state_next = STATE_SEND_B1;
            end
        end

        STATE_SEND_B0 : begin
            if (spi_clk_send_int) begin
                state_next = STATE_DONE;
            end
            else begin
                state_next = STATE_SEND_B0;
            end
        end

        STATE_DONE : begin
            if (axi_lite_bready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_DONE;
            end
        end

        default : begin
            state_next = STATE_RESET;
        end
    endcase
end

reg [7 : 0] data_buf;
reg [31 : 0] addr_buf;

always @( * ) begin
    case (state)
        STATE_RESET : begin
            spi_clk_dv = 0;
            spi_miso = 0;
            data_buf = 8'b0;

            axi_lite_awready = 0;
            axi_lite_wready = 0;
            axi_lite_bvalid = 0;

            axi_lite_bresp = 2'b0;
        end

        STATE_IDEL : begin
            spi_clk_dv = 0;
            spi_miso = 0;
            data_buf = 8'b0;

            axi_lite_awready = 1;
            axi_lite_wready = 0;
            axi_lite_bvalid = 0;

            axi_lite_bresp = 2'b0;

            addr_buf = axi_lite_awvalid ? axi_lite_awaddr : 32'b0;
        end

        STATE_RECV_DATA : begin
            spi_clk_dv = 1;

            axi_lite_awready = 0;
            axi_lite_wready = 1;

            data_buf = axi_lite_wvalid ? axi_lite_wdata[7 : 0] : 8'b0;
        end

        STATE_SEND_B7 : begin
            axi_lite_wready = 0;
            spi_miso = data_buf[7];
        end

        STATE_SEND_B6 : begin
            spi_miso = data_buf[6];
        end

        STATE_SEND_B5 : begin
            spi_miso = data_buf[5];
        end

        STATE_SEND_B4 : begin
            spi_miso = data_buf[4];
        end

        STATE_SEND_B3 : begin
            spi_miso = data_buf[3];
        end

        STATE_SEND_B2 : begin
            spi_miso = data_buf[2];
        end

        STATE_SEND_B1 : begin
            spi_miso = data_buf[1];
        end

        STATE_SEND_B0 : begin
            spi_miso = data_buf[0];
        end

        STATE_DONE : begin
            spi_clk_dv = 0;
            axi_lite_bvalid = 1;
            axi_lite_bresp = axi_lite_bready ? 2'b01 : 2'b0;
        end

        default : begin
            spi_clk_dv = 0;
            spi_miso = 0;
            data_buf = 8'b0;

            axi_lite_awready = 1;
            axi_lite_wready = 0;
            axi_lite_bvalid = 0;

            axi_lite_bresp = 2'b0;
        end
    endcase
end

endmodule

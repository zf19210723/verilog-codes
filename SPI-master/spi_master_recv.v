module spi_master_recv(
           input resetn,
           input clk,

           input [31 : 0] axi_lite_araddr,
           output reg axi_lite_arready,
           input axi_lite_arvalid,

           output reg [31 : 0] axi_lite_rdata,
           input axi_lite_rready,
           output reg axi_lite_rvalid,

           input spi_clk_recv_int,
           input spi_clk_en,
           input spi_mosi
       );

reg [3 : 0] state;
reg [3 : 0] state_next;
parameter STATE_RESET = 4'h0;
parameter STATE_IDEL = 4'h1;
parameter STATE_RECV_B7 = 4'h2;
parameter STATE_RECV_B6 = 4'h3;
parameter STATE_RECV_B5 = 4'h4;
parameter STATE_RECV_B4 = 4'h5;
parameter STATE_RECV_B3 = 4'h6;
parameter STATE_RECV_B2 = 4'h7;
parameter STATE_RECV_B1 = 4'h8;
parameter STATE_RECV_B0 = 4'h9;
parameter STATE_SEND_DATA = 4'ha;

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
            if (spi_clk_en) begin
                state_next = STATE_RECV_B7;
            end
            else begin
                state_next = STATE_IDEL;
            end
        end

        STATE_RECV_B7 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B6;
            end
            else begin
                state_next = STATE_RECV_B7;
            end
        end

        STATE_RECV_B6 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B5;
            end
            else begin
                state_next = STATE_RECV_B6;
            end
        end

        STATE_RECV_B5 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B4;
            end
            else begin
                state_next = STATE_RECV_B5;
            end
        end

        STATE_RECV_B4 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B3;
            end
            else begin
                state_next = STATE_RECV_B4;
            end
        end

        STATE_RECV_B3 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B2;
            end
            else begin
                state_next = STATE_RECV_B3;
            end
        end

        STATE_RECV_B2 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B1;
            end
            else begin
                state_next = STATE_RECV_B2;
            end
        end

        STATE_RECV_B1 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_RECV_B0;
            end
            else begin
                state_next = STATE_RECV_B1;
            end
        end

        STATE_RECV_B0 : begin
            if (spi_clk_recv_int) begin
                state_next = STATE_SEND_DATA;
            end
            else begin
                state_next = STATE_RECV_B0;
            end
        end

        STATE_SEND_DATA : begin
            if (axi_lite_rready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_SEND_DATA;
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
            addr_buf = 32'b0;
            data_buf = 8'b0;

            axi_lite_arready = 0;
            axi_lite_rvalid = 0;

            axi_lite_rdata = 32'b0;
        end

        STATE_IDEL : begin
            addr_buf = axi_lite_arvalid ? axi_lite_araddr : 32'b0;
            data_buf = 8'b0;

            axi_lite_arready = 1;
            axi_lite_rvalid = 0;

            axi_lite_rdata = 32'b0;
        end

        STATE_RECV_B7 : begin
            axi_lite_arready = 0;
            if (spi_clk_recv_int)
                data_buf[7] = spi_mosi;
        end

        STATE_RECV_B6 : begin
            if (spi_clk_recv_int)
                data_buf[6] = spi_mosi;
        end

        STATE_RECV_B5 : begin
            if (spi_clk_recv_int)
                data_buf[5] = spi_mosi;
        end

        STATE_RECV_B4 : begin
            if (spi_clk_recv_int)
                data_buf[4] = spi_mosi;
        end

        STATE_RECV_B3 : begin
            if (spi_clk_recv_int)
                data_buf[3] = spi_mosi;
        end

        STATE_RECV_B2 : begin
            if (spi_clk_recv_int)
                data_buf[2] = spi_mosi;
        end

        STATE_RECV_B1 : begin
            if (spi_clk_recv_int)
                data_buf[1] = spi_mosi;
        end

        STATE_RECV_B0 : begin
            if (spi_clk_recv_int)
                data_buf[0] = spi_mosi;
        end

        STATE_SEND_DATA : begin
            axi_lite_rvalid = 1;
            axi_lite_rdata = axi_lite_rready ? data_buf : 32'b0;
        end

        default : begin
            addr_buf = 32'b0;
            data_buf = 8'b0;

            axi_lite_arready = 0;
            axi_lite_rvalid = 0;

            axi_lite_rdata = 32'b0;
        end
    endcase
end

endmodule

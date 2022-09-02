module spi_master (
           // System interfaces
           input resetn,
           input clk,

           // SPI interface
           output spi_miso,
           input spi_mosi,
           output reg spi_clk,

           // AXI4 Lite interface (Slave)
           input [31 : 0] axi_lite_araddr,
           output axi_lite_arready,
           input axi_lite_arvalid,

           output [31 : 0] axi_lite_rdata,
           input axi_lite_rready,
           output axi_lite_rvalid,

           input [31 : 0] axi_lite_awaddr,
           output axi_lite_awready,
           input axi_lite_awvalid,

           input [31 : 0] axi_lite_wdata,
           output axi_lite_wready,
           input axi_lite_wvalid,
           input [3 : 0] axi_lite_wstrb,

           output [1 : 0] axi_lite_bresp,
           input axi_lite_bready,
           output axi_lite_bvalid
       );
parameter SPI_CLK_DIV = 256;

// Generate basic SPI clock
reg [15 : 0] spi_clk_counter;
wire spi_clk_counter_en;
always @(posedge clk) begin
    if ((!resetn) || (!spi_clk_counter_en)) begin
        spi_clk_counter <= 16'b0;
        spi_clk = 0;
    end
    else begin
        if (spi_clk_counter < SPI_CLK_DIV) begin
            spi_clk_counter <= spi_clk_counter + 1;
            if (spi_clk_counter == SPI_CLK_DIV || spi_clk_counter == SPI_CLK_DIV / 2) begin
                spi_clk <= ~spi_clk;
            end
            else begin
                spi_clk <= spi_clk;
            end
        end
        else begin
            spi_clk_counter <= 16'b0;
            spi_clk <= 0;
        end
    end
end

// Generate SPI send/recv interrupt
reg spi_clk_send_int_dv;
reg spi_clk_recv_int_dv;
always @( * ) begin
    if ((!resetn) || (!spi_clk_counter_en)) begin
        spi_clk_send_int_dv = 0;
        spi_clk_recv_int_dv = 0;
    end
    else begin
        if (spi_clk_counter == 16'b0) begin
            spi_clk_send_int_dv = 1;
            spi_clk_recv_int_dv = 0;
        end
        else if (spi_clk_counter == SPI_CLK_DIV / 2) begin
            spi_clk_send_int_dv = 0;
            spi_clk_recv_int_dv = 1;
        end
        else begin
            spi_clk_send_int_dv = 0;
            spi_clk_recv_int_dv = 0;
        end
    end
end

// Combination
spi_master_send spi_master_send_inst(
                    .resetn(resetn),
                    .clk(clk),

                    .axi_lite_awaddr(axi_lite_awaddr),
                    .axi_lite_awready(axi_lite_awready),
                    .axi_lite_awvalid(axi_lite_awvalid),

                    .axi_lite_wdata(axi_lite_wdata),
                    .axi_lite_wready(axi_lite_wready),
                    .axi_lite_wvalid(axi_lite_wvalid),
                    .axi_lite_wstrb(axi_lite_wstrb),

                    .axi_lite_bresp(axi_lite_bresp),
                    .axi_lite_bready(axi_lite_bready),
                    .axi_lite_bvalid(axi_lite_bvalid),

                    .spi_clk_send_int(spi_clk_send_int_dv),
                    .spi_clk_dv(spi_clk_counter_en),
                    .spi_miso(spi_miso)
                );

spi_master_recv spi_master_recv_inst(
                    .resetn(resetn),
                    .clk(clk),

                    .axi_lite_araddr(axi_lite_araddr),
                    .axi_lite_arready(axi_lite_arready),
                    .axi_lite_arvalid(axi_lite_arvalid),

                    .axi_lite_rdata(axi_lite_rdata),
                    .axi_lite_rready(axi_lite_rready),
                    .axi_lite_rvalid(axi_lite_rvalid),

                    .spi_clk_recv_int(spi_clk_recv_int_dv),
                    .spi_clk_en(spi_clk_counter_en),
                    .spi_mosi(spi_mosi)
                );

endmodule

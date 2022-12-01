`timescale 1ns/1ps

module bench ();

reg clk = 0;
always #1 clk = ~clk;

reg rstn = 0;

wire spi_miso;
reg spi_mosi;
wire spi_clk;

reg [31 : 0] axi_lite_araddr;
wire axi_lite_arready;
reg axi_lite_arvalid;

wire [31 : 0] axi_lite_rdata;
reg axi_lite_rready;
wire axi_lite_rvalid;

reg [31 : 0] axi_lite_awaddr;
wire axi_lite_awready;
reg axi_lite_awvalid;

reg [31 : 0] axi_lite_wdata;
wire axi_lite_wready;
reg axi_lite_wvalid;
reg [3 : 0] axi_lite_wstrb;

wire [1 : 0] axi_lite_bresp;
reg axi_lite_bready;
wire axi_lite_bvalid;

axi_lite_spi_master axi_lite_spi_master_inst(
               // System interfaces
               .resetn(rstn),
               .clk(clk),

               // SPI interface
               .spi_miso(spi_miso),
               .spi_mosi(spi_mosi),
               .spi_clk(spi_clk),

               // AXI4 Lite interface (Slave)
               .axi_lite_araddr(axi_lite_araddr),
               .axi_lite_arready(axi_lite_arready),
               .axi_lite_arvalid(axi_lite_arvalid),

               .axi_lite_rdata(axi_lite_rdata),
               .axi_lite_rready(axi_lite_rready),
               .axi_lite_rvalid(axi_lite_rvalid),

               .axi_lite_awaddr(axi_lite_awaddr),
               .axi_lite_awready(axi_lite_awready),
               .axi_lite_awvalid(axi_lite_awvalid),

               .axi_lite_wdata(axi_lite_wdata),
               .axi_lite_wready(axi_lite_wready),
               .axi_lite_wvalid(axi_lite_wvalid),
               .axi_lite_wstrb(axi_lite_wstrb),

               .axi_lite_bresp(axi_lite_bresp),
               .axi_lite_bready(axi_lite_bready),
               .axi_lite_bvalid(axi_lite_bvalid)
           );

event axi_init;
always @(axi_init) begin
    spi_mosi = 0;

    axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;
    axi_lite_wstrb = 4'b0000;

    axi_lite_bready = 0;
end

event write_spi;
always @(write_spi) begin
    spi_mosi = 0;
    #512 spi_mosi = 0;
    #512 spi_mosi = 0;
    #512 spi_mosi = 1;
    #512 spi_mosi = 0;
    #512 spi_mosi = 0;
    #512 spi_mosi = 0;
    #512 spi_mosi = 0;
end

initial begin
    #50
    rstn = 1;

    #100
    ->axi_init;

    #5000 -> write_spi;
    axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 1;
    axi_lite_wdata = 32'h4;
    axi_lite_wvalid = 1;
    axi_lite_wstrb = 4'b0001;

    axi_lite_bready = 0;

    #10 ->axi_init;

    #5000
    axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 1;
    axi_lite_rready = 1;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;
    axi_lite_wstrb = 4'b0000;

    axi_lite_bready = 1;

    #10 ->axi_init;

    #5000
    axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 1;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;
    axi_lite_wstrb = 4'b0000;

    axi_lite_bready = 0;

    #10 ->axi_init;

end

endmodule

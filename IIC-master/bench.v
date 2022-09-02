`timescale 1ns/1ps

module bench (
       );

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

reg clk = 0;
always #1 clk = ~clk;

reg rstn = 0;

wire iic_scl;
wire iic_sda;

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

wire [1 : 0] axi_lite_bresp;
reg axi_lite_bready;
wire axi_lite_bvalid;

iic_master
    #(
        .C_DIV_SELECT(128)
    )
    iic_master_inst
    (
        .resetn(rstn),
        .clk(clk),

        .iic_scl(iic_scl),
        .iic_sda(iic_sda),

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

        .axi_lite_bresp(axi_lite_bresp),
        .axi_lite_bready(axi_lite_bready),
        .axi_lite_bvalid(axi_lite_bvalid)
    );

event axi_init;
always @(axi_init) begin
    axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;

    axi_lite_bready = 0;
end
/*
initial begin
    -> axi_init;
    #50 rstn = 1;

    #5000
     axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0000_0505;
    axi_lite_awvalid = 1;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;

    axi_lite_bready = 0;

    #2
     -> axi_init;

    #5000
     axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0000_0011;
    axi_lite_wvalid = 1;

    axi_lite_bready = 0;

    #2
     ->axi_init;

    #5000
     axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;

    axi_lite_bready = 1;

    #2
     -> axi_init;

    #5000
     $stop;
end
*/

initial begin
    -> axi_init;
    #50 rstn = 1;

    #5000
     axi_lite_araddr = 32'h0505;
    axi_lite_arvalid = 1;
    axi_lite_rready = 0;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;

    axi_lite_bready = 0;

    #2
     -> axi_init;

    #5000
     axi_lite_araddr = 32'h0;
    axi_lite_arvalid = 0;
    axi_lite_rready = 1;

    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0000_0011;
    axi_lite_wvalid = 1;

    axi_lite_bready = 0;

    #2
     ->axi_init;

    #5000
     $stop;
end

endmodule

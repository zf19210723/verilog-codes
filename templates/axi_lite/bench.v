`timescale 1ns/1ps

module bench ();

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

reg clk = 0;
always #1 clk = ~clk;

reg rstn = 0;

reg [31 : 0] axi_lite_araddr;
wire axi_lite_arready;
reg axi_lite_arvalid;

wire [31 : 0] axi_lite_rdata;
wire [1 : 0] axi_lite_rresp;
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

axi_lite_slave axi_lite_slave_inst(
                   // System interfaces
                   .axi_lite_aresetn(rstn),
                   .axi_lite_aclk(clk),

                   // AXI4 Lite interface (Slave)
                   .axi_lite_araddr(axi_lite_araddr),
                   .axi_lite_arready(axi_lite_arready),
                   .axi_lite_arvalid(axi_lite_arvalid),

                   .axi_lite_rdata(axi_lite_rdata),
                   .axi_lite_rresp(axi_lite_rresp),
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

reg [31 : 0] addr;
reg [31 : 0] data;
reg [1 : 0] resp;

event write_reg;
always @(write_reg) begin

end

event read_reg;
always @(read_reg) begin

end

initial begin
    #19
     rstn = 1;
    ->axi_init;

    #10
     addr = 32'h0000_0000;
    data = 32'h5a5a_4b4b;
    ->write_reg;

    #10
     addr = 32'h0000_0004;
    data = 32'h5b5b_4a4a;
    ->write_reg;

    #10
     addr = 32'h0000_0000;
    ->read_reg;

    #50
     $stop;
end

endmodule

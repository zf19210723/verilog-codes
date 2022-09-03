module bench ();

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

reg clk = 0;
always #1 clk = ~clk;

reg rstn = 1;
wire pwm;

reg [31 : 0] axi_lite_awaddr;
reg axi_lite_awvalid;
wire axi_lite_awready;

reg [31 : 0] axi_lite_wdata;
reg axi_lite_wvalid;
wire axi_lite_wready;

wire [1 : 0] axi_lite_bresp;
wire axi_lite_bvalid;
reg axi_lite_bready;

axi_lite_pwm axi_lite_pwm_inst
             (
                 .axi_lite_aclk(clk),
                 .axi_lite_aresetn(rstn),

                 .pwm(pwm),

                 .axi_lite_awaddr(axi_lite_awaddr),
                 .axi_lite_awvalid(axi_lite_awvalid),
                 .axi_lite_awready(axi_lite_awready),

                 .axi_lite_wdata(axi_lite_wdata),
                 .axi_lite_wvalid(axi_lite_wvalid),
                 .axi_lite_wready(axi_lite_wready),

                 .axi_lite_bresp(axi_lite_bresp),
                 .axi_lite_bvalid(axi_lite_bvalid),
                 .axi_lite_bready(axi_lite_bready)
             );

event init;
always @(init) begin
    axi_lite_awaddr = 32'h0;
    axi_lite_awvalid = 0;
    axi_lite_wdata = 32'h0;
    axi_lite_wvalid = 0;
    axi_lite_bready = 0;
end

reg [31 : 0] addr;
reg [31 : 0] data;
reg [1 : 0] errno;

event write_reg;
always @(write_reg) begin
    errno = 2'b0;

    #10
     if (axi_lite_awready) begin
         axi_lite_awaddr = addr;
         axi_lite_awvalid = 1;
     end
     #2 -> init;

    #10
     if (axi_lite_wready) begin
         axi_lite_wdata = data;
         axi_lite_wvalid = 1;
     end
     #2 -> init;

    #10
     axi_lite_bready = 1;
    if (axi_lite_bvalid) begin
        errno = axi_lite_bresp;
    end
    #2 -> init;
end

initial begin
    #10 rstn = 0;
    -> init;
    #100 rstn = 1;

    #1000
     addr = 32'h0000_0000;
    data = 32'h02e9_0edd;
    ->write_reg;

    #1000
     addr = 32'h0000_0004;
    data = 32'd10;
    ->write_reg;

    #1000
     addr = 32'h0000_0008;
    data = 32'd10000;
    ->write_reg;

    #1000
     addr = 32'h0000_000c;
    data = 32'd5000;
    ->write_reg;

    #10000
     $stop;
end

endmodule

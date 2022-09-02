module bench ();

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

reg clk = 0;
always #1 clk = ~clk;

reg rst = 0;
reg sync = 0;
reg [31 : 0] clk_freq = 32'd1000000;
reg [31 : 0] pwm_freq = 32'd10000;
reg [31 : 0] duty = 32'h7fffffff;

wire pwm;

pwm_bus_interface pwm_bus_interface_inst (
                      .rst (rst),
                      .clk (clk),

                      .pwm (pwm),

                      .sync(sync),
                      .clk_freq(clk_freq),   // kHz
                      .pwm_freq(pwm_freq),   // kHz
                      .duty(duty));

initial begin
    #10 rst = 1;
    #100 rst = 0;

    #100 sync = 1;
    #2 sync = 0;


    #100
     $stop;
end

endmodule

module dfp (
    // System interface
    input clk,
    input rstn,

    // Confugure interface
    input [1 : 0] calc_mode,

    // Double Floating Number interface
    input [63 : 0] dfn_a,
    input [63 : 0] dfn_b,
    input wvaild,
    output wready,

    output [63 : 0] dfn_o,
    output rvalid,
    input rready,
);

reg [3 : 0] state;
reg [3 : 0] state_next;
parameter STATE_RESET = 8'h0;
parameter STATE_IDEL = 8'h1;
parameter STATE_DF_ = 8'h2;
parameter STATE_DF_ = 8'h3;
parameter STATE_DF_ = 8'h4;
parameter STATE_DF_ = 8'h5;
parameter STATE_READ_RES = 8'h6;
    
endmodule
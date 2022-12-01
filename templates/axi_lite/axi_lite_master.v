module axi_lite_master (
           // System interfaces
           input axi_lite_aresetn,
           input axi_lite_aclk,

           //AXI Lite interfaces
           output reg [31 : 0] axi_lite_awaddr,
           output reg axi_lite_awvalid,
           input axi_lite_awready,

           output reg [31 : 0] axi_lite_wdata,
           output reg axi_lite_wvalid,
           input axi_lite_wready,

           input [1 : 0] axi_lite_bresp,
           input axi_lite_bvalid,
           output reg axi_lite_bready,

           output reg [31 : 0] axi_lite_araddr,
           output reg axi_lite_arvalid,
           input axi_lite_arready,

           input [31 : 0] axi_lite_rdata,
           input [1 : 0] axi_lite_rresp,
           input axi_lite_rvalid,
           output reg axi_lite_rready
       );

endmodule
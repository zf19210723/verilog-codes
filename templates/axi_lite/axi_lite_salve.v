module axi_lite_slave (
           // System interfaces
           input axi_lite_aresetn,
           input axi_lite_aclk,

           //AXI Lite interfaces
           input [31 : 0] axi_lite_awaddr,
           input axi_lite_awvalid,
           output reg axi_lite_awready,

           input [31 : 0] axi_lite_wdata,
           input axi_lite_wvalid,
           output reg axi_lite_wready,

           output reg [1 : 0] axi_lite_bresp,
           output reg axi_lite_bvalid,
           input axi_lite_bready,

           input [31 : 0] axi_lite_araddr,
           input axi_lite_arvalid,
           output reg axi_lite_arready,

           output reg [31 : 0] axi_lite_rdata,
           output reg [1 : 0] axi_lite_rresp,
           output reg axi_lite_rvalid,
           input axi_lite_rready
       );

reg [7 : 0] state;
reg [7 : 0] state_next;
parameter STATE_RESET = 8'h0;
parameter STATE_IDEL = 8'h1;
parameter STATE_AXI_RECV_WRITE_DATA = 8'h2;
parameter STATE_WRITE_REG = 8'h3;
parameter STATE_AXI_SEND_WRITE_RESP = 8'h4;
parameter STATE_AXI_READ_DATA = 8'h5;
parameter STATE_AXI_SEND_READ_DATA = 8'h6;

always @(posedge axi_lite_aclk) begin
    if (!axi_lite_aresetn) begin
        state <= STATE_RESET;
    end
    else begin
        state <= state_next;
    end
end

always @(*) begin
    case (state)
        STATE_RESET: begin
            state_next = STATE_IDEL;
        end

        STATE_IDEL: begin
            if (axi_lite_awvalid & axi_lite_awready) begin
                state_next = STATE_AXI_RECV_WRITE_DATA;
            end
            else if (axi_lite_arvalid & axi_lite_arready) begin
                state_next = STATE_AXI_READ_DATA;
            end
            else begin
                state_next = STATE_IDEL;
            end
        end

        STATE_AXI_RECV_WRITE_DATA: begin
            if (axi_lite_wvalid & axi_lite_wready) begin
                state_next = STATE_WRITE_REG;
            end
            else begin
                state_next = STATE_AXI_RECV_WRITE_DATA;
            end
        end

        STATE_WRITE_REG: begin
            state_next = STATE_AXI_SEND_WRITE_RESP;
        end

        STATE_AXI_SEND_WRITE_RESP: begin
            if (axi_lite_bvalid & axi_lite_bready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_AXI_SEND_WRITE_RESP;
            end
        end

        STATE_AXI_READ_DATA: begin
            state_next = STATE_AXI_SEND_READ_DATA;
        end

        STATE_AXI_SEND_READ_DATA: begin
            if (axi_lite_rvalid & axi_lite_rready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_AXI_SEND_READ_DATA;
            end
        end

        default: begin
            state_next = STATE_RESET;
        end
    endcase
end

reg [31 : 0] axi_lite_reg_0;
reg [31 : 0] axi_lite_reg_1;
reg [31 : 0] axi_lite_reg_2;
reg [31 : 0] axi_lite_reg_3;
reg [31 : 0] axi_lite_reg_4;
reg [31 : 0] axi_lite_reg_5;
reg [31 : 0] axi_lite_reg_6;
reg [31 : 0] axi_lite_reg_7;

reg [31 : 0] addr_buf;
reg [31 : 0] data_buf;
reg [1 : 0] err_code;

always @(*) begin
    case (state)
        STATE_RESET: begin
            axi_lite_awready = 0;
            axi_lite_wready = 0;
            axi_lite_bresp = 2'b0;
            axi_lite_bvalid = 0;
            axi_lite_arready = 0;
            axi_lite_rdata = 32'h0;
            axi_lite_rresp = 2'b0;
            axi_lite_rvalid = 0;

            axi_lite_reg_0 = 32'h0;
            axi_lite_reg_1 = 32'h0;
            axi_lite_reg_2 = 32'h0;
            axi_lite_reg_3 = 32'h0;
            axi_lite_reg_4 = 32'h0;
            axi_lite_reg_5 = 32'h0;
            axi_lite_reg_6 = 32'h0;
            axi_lite_reg_7 = 32'h0;

            addr_buf = 32'h0;
            data_buf = 32'h0;
            err_code = 2'b0;
        end

        STATE_IDEL: begin
            axi_lite_awready = 1;
            axi_lite_wready = 0;
            axi_lite_bresp = 2'b0;
            axi_lite_bvalid = 0;
            axi_lite_arready = 1;
            axi_lite_rdata = 32'h0;
            axi_lite_rresp = 2'b0;
            axi_lite_rvalid = 0;

            data_buf = 32'h0;
            err_code = 2'b0;

            if (axi_lite_awvalid & axi_lite_awready) begin
                addr_buf = axi_lite_awaddr;
            end
            else if (axi_lite_arvalid & axi_lite_arready) begin
                addr_buf = axi_lite_araddr;
            end
            else begin
                addr_buf = 32'h0;
            end
        end

        STATE_AXI_RECV_WRITE_DATA: begin
            axi_lite_arready = 0;
            axi_lite_awready = 0;
            axi_lite_wready = 1;

            if (axi_lite_wvalid & axi_lite_wready) begin
                data_buf = axi_lite_wdata;
            end
            else begin
                data_buf = 32'h0;
            end
        end

        STATE_WRITE_REG: begin
            axi_lite_wready = 0;

            case (addr_buf)
                32'h0000_0000: begin
                    axi_lite_reg_0 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_0004: begin
                    axi_lite_reg_1 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_0008: begin
                    axi_lite_reg_2 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_000c: begin
                    axi_lite_reg_3 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_0010: begin
                    axi_lite_reg_4 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_0014: begin
                    axi_lite_reg_5 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_0018: begin
                    axi_lite_reg_6 = data_buf;
                    err_code = 2'b01;
                end
                32'h0000_001c: begin
                    axi_lite_reg_7 = data_buf;
                    err_code = 2'b01;
                end
                default: begin
                    axi_lite_reg_7 = 32'h0;
                    err_code = 2'b10;
                end
            endcase
        end

        STATE_AXI_SEND_WRITE_RESP: begin
            axi_lite_bvalid = 1;

            if (axi_lite_bready & axi_lite_bvalid) begin
                axi_lite_bresp = err_code;
            end
            else begin
                axi_lite_bresp = 2'b0;
            end
        end

        STATE_AXI_READ_DATA: begin
            axi_lite_awready = 0;
            axi_lite_arready = 0;

            case (addr_buf)
                32'h0000_0000: begin
                    data_buf = axi_lite_reg_0;
                    err_code = 2'b01;
                end
                32'h0000_0004: begin
                    data_buf = axi_lite_reg_1;
                    err_code = 2'b01;
                end
                32'h0000_0008: begin
                    data_buf = axi_lite_reg_2;
                    err_code = 2'b01;
                end
                32'h0000_000c: begin
                    data_buf = axi_lite_reg_3;
                    err_code = 2'b01;
                end
                32'h0000_0010: begin
                    data_buf = axi_lite_reg_4;
                    err_code = 2'b01;
                end
                32'h0000_0014: begin
                    data_buf = axi_lite_reg_5;
                    err_code = 2'b01;
                end
                32'h0000_0018: begin
                    data_buf = axi_lite_reg_6;
                    err_code = 2'b01;
                end
                32'h0000_001c: begin
                    data_buf = axi_lite_reg_7;
                    err_code = 2'b01;
                end
                default: begin
                    data_buf = 32'h0;
                    err_code = 2'b10;
                end
            endcase
        end

        STATE_AXI_SEND_READ_DATA: begin
            axi_lite_rvalid = 1;

            if (axi_lite_rvalid & axi_lite_rready) begin
                axi_lite_rdata = data_buf;
                axi_lite_rresp = err_code;
            end
            else begin
                axi_lite_rdata = 32'h0;
            end
        end

        default: begin
            axi_lite_awready = 0;
            axi_lite_wready = 0;
            axi_lite_bresp = 2'b0;
            axi_lite_bvalid = 0;
            axi_lite_arready = 0;
            axi_lite_rdata = 32'h0;
            axi_lite_rresp = 2'b0;
            axi_lite_rvalid = 0;

            axi_lite_reg_0 = 32'h0;
            axi_lite_reg_1 = 32'h0;
            axi_lite_reg_2 = 32'h0;
            axi_lite_reg_3 = 32'h0;
            axi_lite_reg_4 = 32'h0;
            axi_lite_reg_5 = 32'h0;
            axi_lite_reg_6 = 32'h0;
            axi_lite_reg_7 = 32'h0;

            addr_buf = 32'h0;
            data_buf = 32'h0;
            err_code = 2'b0;
        end
    endcase
end

endmodule

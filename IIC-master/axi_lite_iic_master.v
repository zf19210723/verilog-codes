module axi_lite_iic_master(
           // System sockets
           input resetn,
           input clk,

           // IIC socket
           output iic_scl,
           inout iic_sda,

           // AXI4 Lite socket (Slave)
           input [31 : 0] axi_lite_araddr,
           output reg axi_lite_arready,
           input axi_lite_arvalid,

           output reg [31 : 0] axi_lite_rdata,
           input axi_lite_rready,
           output reg axi_lite_rvalid,

           input [31 : 0] axi_lite_awaddr,
           output reg axi_lite_awready,
           input axi_lite_awvalid,

           input [31 : 0] axi_lite_wdata,
           output reg axi_lite_wready,
           input axi_lite_wvalid,

           output reg [3 : 0] axi_lite_bresp,
           input axi_lite_bready,
           output reg axi_lite_bvalid
       );

parameter C_DIV_SELECT = 128;

reg iic_send_dv;
reg iic_recv_dv;

reg [6 : 0] iic_dev_addr;
reg [7 : 0] iic_word_addr;
wire iic_done_flag;
wire [7 : 0] iic_read_data;
reg [7 : 0] iic_write_data;

wor iic_scl_w;
assign iic_scl = iic_scl_w;

wire iic_sda_recv;
wire iic_sda_send;
assign iic_sda = iic_send_dv ? iic_sda_send : 1'bz;
assign iic_sda = iic_recv_dv ? iic_sda_recv : 1'bz;

iic_master_send
    #(
        .C_DIV_SELECT(C_DIV_SELECT)
    )
    iic_master_send_inst
    (
        .I_clk(clk),
        .I_rst_n(resetn),
        .I_iic_send_en(iic_send_dv),

        .I_dev_addr(iic_dev_addr),
        .I_word_addr(iic_word_addr),
        .I_write_data(iic_write_data),
        .O_done_flag(iic_done_flag),

        .O_scl(iic_scl_w),
        .IO_sda(iic_sda_recv)
    );

iic_master_recv
    #(
        .C_DIV_SELECT(C_DIV_SELECT)
    )
    iic_master_recv_inst(
        .I_clk(clk),
        .I_rst_n(resetn),
        .I_iic_recv_en(iic_recv_dv),

        .I_dev_addr(iic_dev_addr),
        .I_word_addr(iic_word_addr),
        .O_read_data(iic_read_data),
        .O_done_flag(iic_done_flag),

        .O_scl(iic_scl_w),
        .IO_sda(iic_sda_send)
    );

//FSM
reg [8 : 0] state;
reg [8 : 0] state_next;
parameter STATE_RESET = 8'h0;
parameter STATE_IDEL = 8'h1;
parameter STATE_READ = 8'h2;
parameter STATE_SEND_READ_DATA = 8'h0;
parameter STATE_READ_WRITE_DATA = 8'h3;
parameter STATE_WRITE = 8'h4;
parameter STATE_SEND_WRESP = 8'h0;
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
            if (axi_lite_arvalid) begin
                state_next = STATE_READ;
            end
            else if (axi_lite_awvalid) begin
                state_next = STATE_READ_WRITE_DATA;
            end
            else begin
                state_next = STATE_IDEL;
            end
        end

        STATE_READ : begin
            if (iic_done_flag) begin
                state_next = STATE_SEND_READ_DATA;
            end
            else begin
                state_next = STATE_READ;
            end
        end

        STATE_SEND_READ_DATA : begin
            if (axi_lite_rready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_SEND_READ_DATA;
            end
        end

        STATE_READ_WRITE_DATA : begin
            if (axi_lite_wvalid) begin
                state_next = STATE_WRITE;
            end
            else begin
                state_next = STATE_READ_WRITE_DATA;
            end
        end

        STATE_WRITE : begin
            if (iic_done_flag) begin
                state_next = STATE_SEND_WRESP;
            end
            else begin
                state_next = STATE_WRITE;
            end
        end

        STATE_SEND_WRESP : begin
            if (axi_lite_bready) begin
                state_next = STATE_IDEL;
            end
            else begin
                state_next = STATE_SEND_WRESP;
            end
        end

        default : begin
            state_next = STATE_RESET;
        end
    endcase
end

always @( * ) begin
    case (state)
        STATE_RESET : begin
            axi_lite_arready = 0;
            axi_lite_rdata = 32'h0;
            axi_lite_rvalid = 0;

            axi_lite_awready = 0;
            axi_lite_wready = 0;

            axi_lite_bresp = 2'b0;
            axi_lite_bvalid = 0;

            iic_word_addr = 8'h0;
            iic_dev_addr = 7'h0;

            iic_recv_dv = 0;
            iic_send_dv = 0;

            iic_write_data = 8'h0;
        end

        STATE_IDEL : begin
            axi_lite_arready = 1;
            axi_lite_rdata = 32'h0;
            axi_lite_rvalid = 0;

            axi_lite_awready = 1;
            axi_lite_wready = 0;

            axi_lite_bresp = 2'b0;
            axi_lite_bvalid = 0;

            iic_recv_dv = 0;
            iic_send_dv = 0;

            iic_write_data = 8'h0;

            if (axi_lite_arvalid) begin
                iic_word_addr = axi_lite_araddr[7: 0];
                iic_dev_addr = axi_lite_araddr[14 : 8];
            end
            else if (axi_lite_awvalid) begin
                iic_word_addr = axi_lite_awaddr[7: 0];
                iic_dev_addr = axi_lite_awaddr[14 : 8];
            end
            else begin
                iic_word_addr = 8'h0;
                iic_dev_addr = 7'h0;
            end
        end

        STATE_READ : begin
            axi_lite_arready = 0;
            axi_lite_awready = 0;

            if (iic_done_flag) begin
                axi_lite_rdata = {24'b0 , iic_read_data};
                iic_recv_dv = 0;
            end
            else begin
                axi_lite_rdata = 32'h0;
                iic_recv_dv = 1;
            end
        end

        STATE_SEND_READ_DATA : begin
            axi_lite_rvalid = 1;
        end

        STATE_READ_WRITE_DATA : begin
            axi_lite_wready = 1;

            if (axi_lite_wvalid) begin
                iic_write_data = axi_lite_wdata[7 : 0];
            end
            else begin
                iic_write_data = 8'h0;
            end
        end

        STATE_WRITE : begin
            axi_lite_wready = 0;
        end

        STATE_SEND_WRESP : begin
            axi_lite_bvalid = 1;

            if (axi_lite_bready) begin
                axi_lite_bresp = 2'b01;
            end
            else begin
                axi_lite_bresp = 2'b00;
            end
        end

        default : begin
            axi_lite_arready = 0;
            axi_lite_rdata = 32'h0;
            axi_lite_rvalid = 0;

            axi_lite_awready = 0;
            axi_lite_wready = 0;

            axi_lite_bresp = 2'b0;
            axi_lite_bvalid = 0;

            iic_word_addr = 8'h0;
            iic_dev_addr = 7'h0;

            iic_recv_dv = 0;
            iic_send_dv = 0;

            iic_write_data = 8'h0;
        end
    endcase
end

endmodule

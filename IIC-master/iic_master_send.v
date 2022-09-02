module iic_master_send
       (
           input I_clk,  // 系统50MHz时钟
           input I_rst_n,  // 系统全局复位
           input I_iic_send_en,  // IIC发送使能位

           input [6: 0] I_dev_addr,  // IIC设备的物理地址
           input [7: 0] I_word_addr,  // IIC设备的字地址，即我们想操作的IIC的内部地址
           input [7: 0] I_write_data,  // 往IIC设备的字地址写入的数据
           output reg O_done_flag,  // 读或写IIC设备结束标志位

           // 标准的IIC设备总线
           output O_scl,  // IIC总线的串行时钟线
           inout IO_sda            // IIC总线的双向数据线
       );

parameter C_DIV_SELECT = 128; // 分频系数选择

parameter C_DIV_SELECT0 = (C_DIV_SELECT >> 2) - 1,  // 用来产生IIC总线SCL低电平最中间的标志位
          C_DIV_SELECT1 = (C_DIV_SELECT >> 1) - 1,
          C_DIV_SELECT2 = (C_DIV_SELECT0 + C_DIV_SELECT1) + 1,  // 用来产生IIC总线SCL高电平最中间的标志位
          C_DIV_SELECT3 = (C_DIV_SELECT >> 1) + 1; // 用来产生IIC总线SCL下降沿标志位


reg [9: 0] R_scl_cnt; // 用来产生IIC总线SCL时钟线的计数器
reg R_scl_en; // IIC总线SCL时钟线使能信号
reg [3: 0] R_state;
reg R_sda_mode; // 设置SDA模式，1位输出，0为输入
reg R_sda_reg; // SDA寄存器
reg [7: 0] R_load_data; // 发送/接收过程中加载的数据，比如设备物理地址，字地址和数据等
reg [3: 0] R_bit_cnt; // 发送字节状态中bit个数计数
reg R_ack_flag; // 应答标志
reg [3: 0] R_jump_state; // 跳转状态，传输一个字节成功并应答以后通过这个变量跳转到导入下一个数据的状态

wire W_scl_low_mid; // SCL的低电平中间标志位
wire W_scl_high_mid; // SCL的高电平中间标志位
wire W_scl_neg; // SCL的下降沿标志位

assign IO_sda = (R_sda_mode == 1'b1) ? R_sda_reg : 1'bz;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n)
        R_scl_cnt <= 10'd0;
    else if (R_scl_en) begin
        if (R_scl_cnt == C_DIV_SELECT - 1'b1)
            R_scl_cnt <= 10'd0;
        else
            R_scl_cnt <= R_scl_cnt + 1'b1;
    end
    else
        R_scl_cnt <= 10'd0;
end

assign O_scl = (R_scl_cnt <= C_DIV_SELECT1) ? 1'b1 : 1'b0; // 产生串行时钟信号O_scl
assign W_scl_low_mid = (R_scl_cnt == C_DIV_SELECT2) ? 1'b1 : 1'b0; // 产生scl低电平正中间标志位
assign W_scl_high_mid = (R_scl_cnt == C_DIV_SELECT0) ? 1'b1 : 1'b0; // 产生scl高电平正中间标志位
assign W_scl_neg = (R_scl_cnt == C_DIV_SELECT3) ? 1'b1 : 1'b0; // 产生scl下降沿标志位

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        R_state <= 4'd0;
        R_sda_mode <= 1'b1;
        R_sda_reg <= 1'b1;
        R_bit_cnt <= 4'd0;
        O_done_flag <= 1'b0;
        R_jump_state <= 4'd0;
        R_ack_flag <= 1'b0;
    end
    else if (I_iic_send_en) // 往IIC设备发送数据
    begin
        case (R_state)
            4'd0 :  // 空闲状态设置SCL与SDA均为高
            begin
                R_sda_mode <= 1'b1; // 设置SDA为输出
                R_sda_reg <= 1'b1; // 设置SDA为高电平
                R_scl_en <= 1'b0; // 关闭SCL时钟线
                R_state <= 4'd1; // 下一个状态是加载设备物理地址状态
                R_bit_cnt <= 4'd0; // 发送字节状态中bit个数计数清零
                O_done_flag <= 1'b0;
                R_jump_state <= 4'd0;
            end
            4'd1 :   // 加载IIC设备物理地址
            begin
                R_load_data <= {I_dev_addr, 1'b0};
                R_state <= 4'd4;
                R_jump_state <= 4'd2;
            end
            4'd2 :    // 加载IIC设备字地址
            begin
                R_load_data <= I_word_addr;
                R_state <= 4'd5;
                R_jump_state <= 4'd3;
            end
            4'd3 :     // 加载要发送的数据
            begin
                R_load_data <= I_write_data;
                R_state <= 4'd5;
                R_jump_state <= 4'd8;
            end
            4'd4 :     // 发送起始信号
            begin
                R_scl_en <= 1'b1; // 打开SCL时钟线
                R_sda_mode <= 1'b1; // 设置SDA为输出
                if (W_scl_high_mid) begin
                    R_sda_reg <= 1'b0; // 在SCL高电平中间把SDA信号拉低,产生起始信号
                    R_state <= 4'd5;
                end
                else
                    R_state <= 4'd4; // 如果SCL高电平中间标志没出现就一直在这个状态等着
            end
            4'd5 :     // 发送1个字节，从高位开始发
            begin
                R_scl_en <= 1'b1; // 打开SCL时钟线
                R_sda_mode <= 1'b1; // 设置SDA为输出
                if (W_scl_low_mid) begin
                    if (R_bit_cnt == 4'd8) begin
                        R_bit_cnt <= 4'd0;
                        R_state <= 4'd6; // 字节发完以后进入应答状态
                    end
                    else begin
                        R_sda_reg <= R_load_data[7 - R_bit_cnt]; // 先发送高位
                        R_bit_cnt <= R_bit_cnt + 1'b1;
                    end
                end
                else
                    R_state <= 4'd5; // 字节没发完时在这个状态一直等待
            end
            4'd6 :     // 接收应答状态的应答位
            begin
                R_scl_en <= 1'b1; // 打开SCL时钟线
                R_sda_mode <= 1'b0; // 设置SDA为输入
                if (W_scl_high_mid) begin
                    R_ack_flag <= IO_sda;
                    R_state <= 4'd7;
                end
                else
                    R_state <= 4'd6;
            end
            4'd7 :     // 校验应答位
            begin
                R_scl_en <= 1'b1; // 打开SCL时钟线
                if (R_ack_flag == 1'b0)    // 校验通过
                begin
                    if (W_scl_neg == 1'b1) begin
                        R_state <= R_jump_state;
                        R_sda_mode <= 1'b1; // 设置SDA的模式为输出
                        R_sda_reg <= 1'b0; // 读取完应答信号以后要把SDA信号设置成输出并拉低，因为如果这个状
                        // 态后面是停止状态的话，需要SDA信号的上升沿，所以这里提前拉低它
                    end
                    else
                        R_state <= 4'd7;
                end
                else
                    R_state <= 4'd0;
            end
            4'd8 :  // 发送停止信号
            begin
                R_scl_en <= 1'b1; // 打开SCL时钟线
                R_sda_mode <= 1'b1; // 设置SDA为输出
                if (W_scl_high_mid) begin
                    R_sda_reg <= 1'b1;
                    R_state <= 4'd9;
                end
            end
            4'd9 :    // IIC写操作结束
            begin
                R_scl_en <= 1'b0; // 关闭SCL时钟线
                R_sda_mode <= 1'b1; // 设置SDA为输出
                R_sda_reg <= 1'b1; // 拉高SDA保持空闲状态情况
                O_done_flag <= 1'b1;
                R_state <= 4'd0;
                R_ack_flag <= 1'b0;
            end
            default :
                R_state <= 4'd0;
        endcase
    end
    else begin
        R_state <= 4'd0;
        R_sda_mode <= 1'b1;
        R_sda_reg <= 1'b1;
        R_bit_cnt <= 4'd0;
        O_done_flag <= 1'b0;
        R_jump_state <= 4'd0;
        R_ack_flag <= 1'b0;
    end
end

/*
wire [35: 0] CONTROL0;
wire [54: 0] TRIG0;
icon icon_inst (
         .CONTROL0(CONTROL0) // INOUT BUS [35:0]
     );

ila ila_inst (
        .CONTROL(CONTROL0),  // INOUT BUS [35:0]
        .CLK(I_clk),  // IN
        .TRIG0(TRIG0) // IN BUS [49:0]
    );

assign TRIG0[0] = O_scl;
assign TRIG0[1] = IO_sda;
assign TRIG0[11: 2] = R_scl_cnt;
assign TRIG0[12] = R_scl_en;
assign TRIG0[16: 13] = R_state;
assign TRIG0[17] = R_sda_mode;
assign TRIG0[18] = R_sda_reg;
assign TRIG0[26: 19] = R_load_data;

assign TRIG0[30: 27] = R_bit_cnt;
assign TRIG0[31] = R_ack_flag;
assign TRIG0[36: 32] = R_jump_state;
assign TRIG0[37] = W_scl_low_mid;
assign TRIG0[38] = W_scl_high_mid;
assign TRIG0[39] = O_done_flag;
assign TRIG0[40] = I_rst_n;
*/

endmodule

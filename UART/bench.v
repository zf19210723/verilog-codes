`timescale 1ns/1ps

module bench ();
    
    localparam DELAY = 101;
    
    reg clk             = 0;
    always #(DELAY) clk = ~clk;
    
    reg rst             = 0;
    reg [31 : 0] period = 32'h400;
    reg tx              = 1;
    
    event send_byte;
    reg [7 : 0] byte_buffer;
    reg [4 : 0] bit_index;
    
    always @(send_byte) begin
        bit_index = 0;
        tx        = 0;
        while (bit_index < 8) begin
            #(DELAY * period) tx = byte_buffer[bit_index];
            bit_index            = bit_index + 1;
        end
        #(DELAY * period) tx = 1;
    end
    
    wire sync;
    wire [7 : 0]data;
    
    uart_rx uart_rx_inst (
    .rst (rst),
    .clk (clk),
    .period (period / 2),
    .rx(tx),
    .out_sync (sync),
    .out_data (data)
    );
    
    wire rx;
    uart_tx uart_tx_inst (
    .rst (rst),
    .clk (clk),
    .period (period / 2),
    .tx(rx),
    .in_sync (sync),
    .in_data (data)
    );

    initial begin
        #200 rst = 1;
        #5000 rst = 0;

        #5000 byte_buffer = 8'h56;
        -> send_byte;
    end
    
endmodule

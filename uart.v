`include "uart_tx.v"
`include "baud_rate_generator.v"
module uart #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD = 19200
)(
    input clk,
    input rst,
    input wr_en,
    input [31:0] address,
    input [31:0] write_data,
    output busy,
    output tx
);

wire en;


baud_rate_generator #(
    .clk_freq(CLK_FREQ),
    .baud(BAUD)
) u_baud (
    .clk(clk),
    .rst(rst),
    .tx_enb(en)
);

wire tx_wr = wr_en && (address == 32'h10000000);

uart_tx u_tx (
    .clk(clk),
    .rst(rst),
    .wr_en(tx_wr),
    .en(en),
    .data_in(write_data[7:0]),
    .tx(tx),
    .busy(busy)
);



endmodule

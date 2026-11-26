
module baud_rate_generator #(
    parameter clk_freq = 100_000_000,
    parameter baud = 19200
)(
    input clk,
    input rst,
    output reg tx_enb
);

localparam TX_LIMIT = clk_freq / baud;

reg [$clog2(TX_LIMIT)-1:0] counter_tx;

always @(posedge clk) begin
    if (rst) begin
        tx_enb <= 1'b0;
        counter_tx <= 0;
    end
    else begin
        if (counter_tx == TX_LIMIT-1) begin
            tx_enb <= 1'b1;
            counter_tx <= 0;
        end
        else begin
            tx_enb <= 1'b0;
            counter_tx <= counter_tx + 1'b1;
        end
    end
end

endmodule

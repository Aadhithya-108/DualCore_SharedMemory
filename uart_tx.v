module uart_tx(
    input clk,
    input wr_en,
    input rst,
    input en,
    input [7:0] data_in,
    output reg tx,
    output busy
);

    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    reg [7:0] data;
    reg [2:0] index;
    reg [1:0] state;
    
   

    always @(posedge clk) begin
        if (rst) begin
            tx    <= 1'b1;
            state <= IDLE;
            index <= 3'd0;
            data  <= 8'd0;   
        end
        else begin
            case (state)
                IDLE: begin
                    if (wr_en) begin
                        state <= START;
                        data  <= data_in;
                        index <= 3'b000;
                    end
                end

                START: begin
                    if (en) begin
                        tx    <= 1'b0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (en) begin
                        tx <= data[index];
                        if (index == 3'h7) begin
                            state <= STOP;
                        end
                        else begin
                            index <= index + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (en) begin
                        tx    <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    tx    <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    assign busy = (state != IDLE);

endmodule
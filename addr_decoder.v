module addr_decoder(addr,en_uart);
input [31:0]addr;
output reg en_uart;
always @(*) begin
    if(addr==32'h10000000)begin
    en_uart=1;
    end
    else begin
    en_uart=0;
    end
end
endmodule

`timescale 1ns/1ps
module m_pc(clk,clrn,npc,pc,en);
input en;
input [31:0]npc;
output reg[31:0]pc;
input clk,clrn;

always@(posedge clk or negedge clrn) begin
    if(~clrn)
    pc<=32'd0;
    else if(en)
    pc<=npc;
end
endmodule
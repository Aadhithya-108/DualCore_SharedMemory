`timescale 1ns/1ps
module imme(alui,imm,inst);
input [1:0]alui;
input [31:0]inst;
output reg[31:0]imm;

always @(*) begin
    case(alui)
    2'b00: imm = {{21{inst[31]}},inst[30:20]};
    2'b01: imm = {27'b0, inst[24:20]}; 
    2'b10: imm = {{21{inst[31]}},inst[30:25],inst[11:7]}; 
    2'b11: imm = {inst[31:12],12'b0}; 
    endcase
end
endmodule
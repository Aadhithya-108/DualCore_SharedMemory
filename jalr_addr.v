`timescale 1ns/1ps
module jalr_addr(inst,rs1,addr);
input [31:0]inst,rs1;
output [31:0]addr;
wire [31:0]imm,target;

assign imm={{20{inst[31]}},inst[30:20]};
assign target=rs1+imm;
assign addr={target[31:1],1'b0};
endmodule


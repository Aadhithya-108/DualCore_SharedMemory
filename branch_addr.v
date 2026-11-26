`timescale 1ns/1ps
module branch_addr(pc,inst,addr);
input [31:0]inst,pc;
output [31:0]addr;
wire [31:0]offset;

assign offset={{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
assign addr=pc+offset;
endmodule

`timescale 1ns/1ps
module jal_addr (pc,inst,addr); 
input [31:0] pc,inst;
output [31:0] addr;

wire [31:0] offset = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
assign addr = pc + offset;
endmodule
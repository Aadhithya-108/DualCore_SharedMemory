`timescale 1ns/1ps
module cu(opcode,func7,func3,z,rs2,wreg,wmem,m2r,bimm,call,aluc,alui,pcsrc,mreq,lr,sc,en_uart,wr_uart);
input [6:0] opcode;
input [6:0] func7;
input [2:0] func3;
input z;
input [4:0] rs2;
output [3:0] aluc;
output [1:0] alui;
output [1:0] pcsrc;
output lr,sc;
output m2r;
output bimm;
output call;
output wreg;
output wmem;
output mreq;

input en_uart;
output wr_uart;

wire [4:0]func5=func7[6:2];

wire i_lui = (opcode==7'b0110111);
wire i_jal = (opcode==7'b1101111);
wire i_jalr = (opcode == 7'b1100111) & (func3 == 3'b000);
wire i_beq =(opcode==7'b1100011) & (func3 == 3'b000); 
wire i_bne =(opcode==7'b1100011) & (func3 == 3'b001);
wire i_lw =(opcode==7'b0000011) & (func3 == 3'b010);
wire i_sw =(opcode==7'b0100011) & (func3 == 3'b010);
wire i_addi =(opcode==7'b0010011) & (func3 == 3'b000);
wire i_xori =(opcode==7'b0010011) & (func3 == 3'b100);
wire i_ori =(opcode==7'b0010011) & (func3 == 3'b110);
wire i_andi =(opcode==7'b0010011) & (func3 == 3'b111);
wire i_slli = (opcode == 7'b0010011) & (func3 == 3'b001) & (func7 == 7'b0000000);
wire i_srli =(opcode==7'b0010011) & (func3 == 3'b101) & (func7 == 7'b0000000);
wire i_srai =(opcode==7'b0010011) & (func3 == 3'b101) & (func7 == 7'b0100000);
wire i_add =(opcode==7'b0110011) & (func3 == 3'b000) & (func7 == 7'b0000000);
wire i_sub =(opcode==7'b0110011) & (func3 == 3'b000) & (func7 == 7'b0100000);
wire i_slt =(opcode==7'b0110011) & (func3 == 3'b010) & (func7 == 7'b0000000);
wire i_xor =(opcode==7'b0110011) & (func3 == 3'b100) & (func7 == 7'b0000000);
wire i_or =(opcode==7'b0110011) & (func3 == 3'b110) & (func7 == 7'b0000000);
wire i_and =(opcode==7'b0110011) & (func3 == 3'b111) & (func7 == 7'b0000000);
wire i_lr=(opcode == 7'b0101111)& (func3 == 3'b010) & (func5 == 5'b00010) & (rs2==5'b00000);
wire i_sc=(opcode == 7'b0101111)& (func3 == 3'b010) & (func5 == 5'b00011);

assign aluc[0] =i_sub | i_beq | i_bne | i_xor | i_xori | i_and | i_andi | i_slli | i_srli | i_srai;
assign aluc[1] = i_slt | i_xor | i_xori | i_slli | i_srli | i_srai | i_lui;
assign aluc[2] = i_or | i_ori | i_and | i_andi | i_srli | i_srai | i_lui ;
assign aluc[3] = i_xori | i_xor | i_srai;
assign m2r = i_lw | i_lr;
assign wmem = i_sw;
assign wreg = i_lui | i_jal | i_jalr | i_lw | i_addi | i_xori | i_ori | i_andi |i_slli | i_srli | i_srai | i_add | i_sub | i_slt | i_xor | i_or | i_and | i_lr | i_sc;
assign pcsrc[0] =i_jal | (i_beq & z) | (i_bne & ~z); 
assign pcsrc[1] =i_jal | i_jalr;
assign call =i_jalr|i_jal;
assign alui[0] = i_slli | i_srli | i_srai| i_lui;
assign alui[1] =i_sw | i_lui;
assign bimm =i_addi | i_xori | i_ori | i_andi | i_slli | i_srli | i_srai | i_lw | i_sw | i_lui;
assign mreq=(i_lw|i_sw|i_lr|i_sc)&&(~wr_uart);
assign lr=i_lr;
assign sc=i_sc;

assign wr_uart=en_uart&&i_sw;
endmodule
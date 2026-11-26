`timescale 1ns/1ps
`include "ALU.v"
`include "imme.v"
`include "branch_addr.v"
`include "cu.v"
`include "jal_addr.v"
`include "jalr_addr.v"
`include "m_pc.v"
`include "register.v"

module cpu(clk,clrn,inst,memout,pc,alu,memin,wmem,en,mreq,lr,sc,sc_status,en_uart,wr_uart);
input clk,clrn,en;
input [31:0]inst,memout;
input [31:0]sc_status;
output [31:0]pc,alu,memin;
output wmem,mreq,lr,sc;

input en_uart;
output wr_uart;

wire [31:0]npc,p4,bra,jala,jalra;
wire [7:0]opcode,func7;
wire [2:0]func3;
wire z,wreg,m2r,bimm,call;
wire [3:0]aluc;
wire [1:0]alui,pcsrc;
wire [31:0] d,a,data,res;
wire [4:0]rs1,rs2,rd;
wire [31:0]imm;
wire [31:0]b,mem;


assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign rd  = inst[11:7];
assign memin=data;

m_pc i0(.clk(clk),.clrn(clrn),.npc(npc),.pc(pc),.en(en));

assign p4=pc+32'd4;

//i6
assign npc = pcsrc[1] ?(pcsrc[0] ? jala : jalra) :(pcsrc[0] ? bra  : p4);

branch_addr i7(.pc(pc),.inst(inst),.addr(bra));
jalr_addr i8(.inst(inst),.rs1(a),.addr(jalra));
jal_addr i9(.pc(pc),.inst(inst),.addr(jala));

cu i10 (.z(z),.func3(inst[14:12]),.func7(inst[31:25]),.opcode(inst[6:0]),.m2r(m2r),.bimm(bimm),
.call(call),.wreg(wreg),.wmem(wmem),.aluc(aluc),.alui(alui),.pcsrc(pcsrc),.mreq(mreq),.lr(lr),.sc(sc),.rs2(rs2),.en_uart(en_uart),.wr_uart(wr_uart));

//i3
assign d=call?p4:res;

register i2(.rna(rs1),.rnb(rs2),.wn(rd),.we(wreg),.qa(a),.qb(data),.d(d),.clk(clk),.clrn(clrn),.en(en));

imme i4(.alui(alui),.imm(imm),.inst(inst));

//i11 changed for sc,lr
assign b=(sc|lr)?32'b0:bimm?imm:data;

ALU i5(.a(a),.b(b),.r(alu),.aluc(aluc),.z(z));

//i12 changed for lr,sc
assign mem = memout;
assign res=sc?sc_status:m2r?mem:alu;


endmodule
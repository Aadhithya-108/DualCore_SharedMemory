`timescale 1ns/1ps
`include "cpu.v"
`include "mem.v"
`include "instmem0.v"
`include "instmem1.v"
`include "bus_arbiter.v"
`include "addr_decoder.v"
`include "uart.v"

module top(clk,clrn,pc0,pc1,inst0,inst1,dataout,alu0,alu1,tx0,tx1);

input clk,clrn;

output [31:0] pc0,pc1,inst0,inst1,dataout,alu0,alu1;
output tx0,tx1;
wire [31:0] datain0,datain1,datain;
wire wmem1,wmem0,wmem;
wire mreq0,mreq1;
wire grant0,grant1;
wire lr0,lr1,sc0,sc1,lr,sc;
wire [31:0]alu;
wire [31:0]sc_status0,sc_status1;


wire en0,en1,en;
assign en=(grant0||grant1);
assign en0=((!mreq0)||grant0)&&(!busy0||!wr_uart0);
assign en1=((!mreq1)||grant1)&&(!busy1||!wr_uart1);
assign sc=(grant0 && sc0)||(grant1 && sc1);
assign lr=(grant0 && lr0)||(grant1 && lr1);

wire en_uart0,en_uart1;
wire busy0,busy1;


instmem0 instmem0(
    .a(pc0),.inst(inst0)
);
instmem1 instmem1(
    .a(pc1),.inst(inst1)
);

bus_arbiter roundrobin(.clk(clk),.clrn(clrn),.req0(mreq0),.req1(mreq1),.grant0(grant0),.grant1(grant1));

cpu core0(
    .clk(clk),.clrn(clrn),.inst(inst0),.memout(dataout),.pc(pc0),.alu(alu0),.memin(datain0),.wmem(wmem0),.en(en0),.mreq(mreq0),.sc(sc0),.lr(lr0),.sc_status(sc_status0),.en_uart(en_uart0),.wr_uart(wr_uart0)
);
cpu core1(
    .clk(clk),.clrn(clrn),.inst(inst1),.memout(dataout),.pc(pc1),.alu(alu1),.memin(datain1),.wmem(wmem1),.en(en1),.mreq(mreq1),.sc(sc1),.lr(lr1),.sc_status(sc_status1),.en_uart(en_uart1),.wr_uart(wr_uart1)
);

assign datain=grant0?datain0:grant1?datain1:32'b0;
assign alu=grant0?alu0:grant1?alu1:32'b0;
assign wmem=(wmem0&&grant0)||(grant1&&wmem1);

mem mem1(
    .addr(alu),.datain(datain),.dataout(dataout),.we(wmem),.clk(clk),.en(en),.sc(sc),.lr(lr),.core_id(grant1),.sc_status1(sc_status1),.sc_status0(sc_status0)
);

addr_decoder d0(.addr(alu0),.en_uart(en_uart0));
addr_decoder d1(.addr(alu1),.en_uart(en_uart1));

uart u0(.clk(clk),.rst(~clrn),.wr_en(wr_uart0),.address(alu0),.write_data(datain0),.busy(busy0),.tx(tx0));
uart u1(.clk(clk),.rst(~clrn),.wr_en(wr_uart1),.address(alu1),.write_data(datain1),.busy(busy1),.tx(tx1));
endmodule
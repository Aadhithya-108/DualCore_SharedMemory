`timescale 1ns/1ps
`include "top.v"
module tb_multicore;

reg clk, clrn;

wire [31:0] pc0, pc1;
wire [31:0] inst0, inst1;
wire [31:0] dataout;
wire [31:0] alu0, alu1;

top uut (
    .clk(clk),
    .clrn(clrn),
    .pc0(pc0),
    .pc1(pc1),
    .inst0(inst0),
    .inst1(inst1),
    .dataout(dataout),
    .alu0(alu0),
    .alu1(alu1)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    clrn = 0;
    #20;
    clrn = 1;
end

initial begin
    #50000;

    $display("RAM0 = %d", uut.mem1.ram[0]);
    $display("RAM1 = %d", uut.mem1.ram[1]);
    $display("RAM2 = %d", uut.mem1.ram[2]);
    $display("RAM3 = %d", uut.mem1.ram[3]);

    if (uut.mem1.ram[3] == 10)
        $display("MULTICORE TEST PASSED");
    else
        $display("MULTICORE TEST FAILED");

    $finish;
end

initial begin
    $dumpfile("multicore.vcd");
    $dumpvars(0, tb_multicore);
end

endmodule
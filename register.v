`timescale 1ns/1ps
module register(rna,rnb,wn,we,qa,qb,d,clk,clrn,en);
input [4:0]rna,rnb,wn;
input we,clk,clrn,en;
input [31:0]d;
output [31:0]qa,qb;
reg [31:0]register[0:31];
integer i;

assign qa=(rna==0)?32'b0:register[rna];
assign qb=(rnb==0)?32'b0:register[rnb];

always@(posedge clk or negedge clrn) begin
    if(!clrn) begin
        for(i=0;i<32;i=i+1) begin
        register[i]<=32'b0;
        end
    end
    else if(wn!=0 && we && en!=0)
    register[wn]<=d;
end
endmodule

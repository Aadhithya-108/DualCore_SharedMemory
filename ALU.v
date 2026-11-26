`timescale 1ns/1ps
module ALU(a,b,r,aluc,z);
input [31:0]a,b;
input [3:0]aluc;
output reg [31:0]r;
output z;
wire [31:0]sub;

assign sub=a-b;
always@(*) begin
casex(aluc)
4'bx000:r=a+b;
4'bx001:r=sub;
4'bx010:r={31'b0,sub[31]}; 
4'b1011:r=a^b;
4'bx100:r=a|b;
4'bx101:r=a&b;
4'b0011:r=a<<b[4:0]; 
4'b0111:r=a>>b[4:0]; 
4'b1111:r=$signed(a)>>>b[4:0]; 
4'bx110:r=b; 
endcase
end
assign z=~|r;
endmodule
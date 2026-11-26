module bus_arbiter(clk,clrn,req0,req1,grant0,grant1);
input clk,clrn,req0,req1;
output reg grant0,grant1;
reg turn;

always@(*) begin
    grant0=1'b0;
    grant1=1'b0;
    if(req1&&req0) begin
        if(turn)
        grant1=1'b1;
        else
        grant0=1'b1;
    end
    else if(req0)
        grant0=1'b1;
    else if(req1)
        grant1=1'b1;
end

always@(posedge clk or negedge clrn) begin
    if(clrn==0)
    turn<=0;
    else begin
    if(grant0)
    turn<=1;
    else if(grant1)
    turn<=0;
    end
end
endmodule
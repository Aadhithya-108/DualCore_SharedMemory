`timescale 1ns/1ps
module mem(addr,datain,dataout,we,clk,en,lr,sc,core_id,sc_status0,sc_status1);
input [31:0]addr,datain;
input lr,sc,core_id;
output [31:0]dataout;
output [31:0]sc_status0,sc_status1;
input we,clk,en;

reg [31:0]ram[0:31];
reg reservation_valid [0:1];
reg [4:0] reservation_addr [0:1];
wire [4:0]waddr;

assign dataout=ram[addr[6:2]];
assign waddr=addr[6:2];
integer i;

initial begin
    for(i=0;i<32;i=i+1)
    ram[i]=0;
    reservation_valid[0]=1'b0;
    reservation_valid[1]=1'b0;
    reservation_addr[0]=5'b0;
    reservation_addr[1]=5'b0;
end

assign sc_status0={31'b0,(~((sc & en & !we & !lr)&&(~core_id)&&(reservation_valid[0] & (reservation_addr[0]==waddr))))};
assign sc_status1={31'b0,(~((sc & en & !we & !lr)&&(core_id)&&(reservation_valid[1] & (reservation_addr[1]==waddr))))};


always@(posedge clk) begin
    //lr
    if(en& !sc & !we & lr) //write lr only in condtion
    begin
      reservation_valid[core_id]<=1'b1;
      reservation_addr[core_id]<=waddr;  
    end
    //normal store
    if(en& !sc & we & !lr) //write we only in condition
    begin
        ram[waddr]<=datain;
        if(reservation_valid[core_id] && (reservation_addr[core_id] == waddr))
        reservation_valid[core_id] <= 1'b0;

        if(reservation_valid[~core_id] && (reservation_addr[~core_id]==waddr))
        reservation_valid[~core_id]<=1'b0;
    end
    //sc
    if(sc & en & !we & !lr)// !we bcz we means sw instruction
    begin
        if(reservation_valid[core_id] & (reservation_addr[core_id]==waddr)) begin
            ram[waddr]<=datain;
            if(reservation_valid[~core_id] & (reservation_addr[~core_id]==waddr))
            reservation_valid[~core_id]<=1'b0;
        end

        reservation_valid[core_id]<=1'b0;    
    end
end
endmodule


`timescale 1ns/1ps

//with spinlock program in instruction memory

// ===================== ALU.v =====================
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
 
// ===================== imme.v =====================
module imme(alui,imm,inst);
input [1:0]alui;
input [31:0]inst;
output reg[31:0]imm;

always @(*) begin
    case(alui)
    2'b00: imm = {{21{inst[31]}},inst[30:20]};
    2'b01: imm = {27'b0, inst[24:20]}; 
    2'b10: imm = {{21{inst[31]}},inst[30:25],inst[11:7]}; 
    2'b11: imm = {inst[31:12],12'b0}; 
    endcase
end
endmodule
 
// ===================== branch_addr.v =====================
module branch_addr(pc,inst,addr);
input [31:0]inst,pc;
output [31:0]addr;
wire [31:0]offset;

assign offset={{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
assign addr=pc+offset;
endmodule
 
// ===================== jal_addr.v =====================
module jal_addr (pc,inst,addr); 
input [31:0] pc,inst;
output [31:0] addr;

wire [31:0] offset = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
assign addr = pc + offset;
endmodule
 
// ===================== jalr_addr.v =====================
module jalr_addr(inst,rs1,addr);
input [31:0]inst,rs1;
output [31:0]addr;
wire [31:0]imm,target;

assign imm={{20{inst[31]}},inst[30:20]};
assign target=rs1+imm;
assign addr={target[31:1],1'b0};
endmodule

 
// ===================== cu.v =====================
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
 
// ===================== m_pc.v =====================
module m_pc(clk,clrn,npc,pc,en);
input en;
input [31:0]npc;
output reg[31:0]pc;
input clk,clrn;

always@(posedge clk or negedge clrn) begin
    if(~clrn)
    pc<=32'd0;
    else if(en)
    pc<=npc;
end
endmodule
 
// ===================== register.v =====================
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
 
// ===================== cpu.v =====================

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
 
// ===================== bus_arbiter.v =====================
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
 
// ===================== addr_decoder.v =====================
module addr_decoder(addr,en_uart);
input [31:0]addr;
output reg en_uart;
always @(*) begin
    if(addr==32'h10000000)begin
    en_uart=1;
    end
    else begin
    en_uart=0;
    end
end
endmodule
 
// ===================== mem.v =====================
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

 
// ===================== baud_rate_generator.v =====================

module baud_rate_generator #(
    parameter clk_freq = 100_000_000,
    parameter baud = 9600
)(
    input clk,
    input rst,
    output reg tx_enb
);

localparam TX_LIMIT = clk_freq / baud;

reg [$clog2(TX_LIMIT)-1:0] counter_tx;

always @(posedge clk) begin
    if (rst) begin
        tx_enb <= 1'b0;
        counter_tx <= 0;
    end
    else begin
        if (counter_tx == TX_LIMIT-1) begin
            tx_enb <= 1'b1;
            counter_tx <= 0;
        end
        else begin
            tx_enb <= 1'b0;
            counter_tx <= counter_tx + 1'b1;
        end
    end
end

endmodule
 
// ===================== uart_tx.v =====================
module uart_tx(
    input clk,
    input wr_en,
    input rst,
    input en,
    input [7:0] data_in,
    output reg tx,
    output busy
);

    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    reg [7:0] data;
    reg [2:0] index;
    reg [1:0] state;
    
   

    always @(posedge clk) begin
        if (rst) begin
            tx    <= 1'b1;
            state <= IDLE;
            index <= 3'd0;
            data  <= 8'd0;   
        end
        else begin
            case (state)
                IDLE: begin
                    if (wr_en) begin
                        state <= START;
                        data  <= data_in;
                        index <= 3'b000;
                    end
                end

                START: begin
                    if (en) begin
                        tx    <= 1'b0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (en) begin
                        tx <= data[index];
                        if (index == 3'h7) begin
                            state <= STOP;
                        end
                        else begin
                            index <= index + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (en) begin
                        tx    <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    tx    <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    assign busy = (state != IDLE);

endmodule
 
// ===================== uart.v =====================
module uart #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD = 9600
)(
    input clk,
    input rst,
    input wr_en,
    input [31:0] address,
    input [31:0] write_data,
    output busy,
    output tx
);

wire en;


baud_rate_generator #(
    .clk_freq(CLK_FREQ),
    .baud(BAUD)
) u_baud (
    .clk(clk),
    .rst(rst),
    .tx_enb(en)
);

wire tx_wr = wr_en && (address == 32'h10000000);

uart_tx u_tx (
    .clk(clk),
    .rst(rst),
    .wr_en(tx_wr),
    .en(en),
    .data_in(write_data[7:0]),
    .tx(tx),
    .busy(busy)
);



endmodule
 
// ===================== instmem0.v =====================
// core 0: prime detection for 1..50, prints primes, then waits for core 1 and prints total
module instmem0(a, inst);

    input [31:0] a;
    output [31:0] inst;

    reg [31:0] rom [0:63];
    integer i;

    assign inst = rom[a[7:2]];

    initial begin
        for (i = 0; i < 64; i = i + 1)
            rom[i] = 32'h00000013;

        rom[0] = 32'h100000B7; // lui x1,0x10000
        rom[1] = 32'h00200193; // addi x3,x0,2
        rom[2] = 32'h00A00593; // addi x11,x0,10
        rom[3] = 32'h00000213; // addi x4,x0,0
        rom[4] = 32'h00100293; // addi x5,x0,1
        rom[5] = 32'h03300313; // addi x6,x0,51
        rom[6] = 32'h06628263; // beq x5,x6,finish
        rom[7] = 32'h0032A533; // slt x10,x5,x3
        rom[8] = 32'h04051A63; // bne x10,x0,skip
        rom[9] = 32'h00200393; // addi x7,x0,2
        rom[10] = 32'h00400413; // addi x8,x0,4
        rom[11] = 32'h0082A533; // slt x10,x5,x8
        rom[12] = 32'h02051863; // bne x10,x0,is_prime
        rom[13] = 32'h000284B3; // add x9,x5,x0
        rom[14] = 32'h0074A533; // slt x10,x9,x7
        rom[15] = 32'h00051663; // bne x10,x0,mod_done
        rom[16] = 32'h407484B3; // sub x9,x9,x7
        rom[17] = 32'hFF5FF06F; // jal x0,mod
        rom[18] = 32'h02048663; // beq x9,x0,skip
        rom[19] = 32'h00740433; // add x8,x8,x7
        rom[20] = 32'h00740433; // add x8,x8,x7
        rom[21] = 32'h00140413; // addi x8,x8,1
        rom[22] = 32'h00138393; // addi x7,x7,1
        rom[23] = 32'hFD1FF06F; // jal x0,test_d
        rom[24] = 32'h00120213; // addi x4,x4,1
        rom[25] = 32'h000286B3; // add x13,x5,x0
        rom[26] = 32'h048007EF; // jal x15,print_num
        rom[27] = 32'h02000113; // addi x2,x0,32
        rom[28] = 32'h0020A023; // sw x2,0(x1)
        rom[29] = 32'h00128293; // addi x5,x5,1
        rom[30] = 32'hFA1FF06F; // jal x0,next_n
        rom[31] = 32'h100024AF; // lr.w x9,(x0)
        rom[32] = 32'h004484B3; // add x9,x9,x4
        rom[33] = 32'h1890252F; // sc.w x10,x9,(x0)
        rom[34] = 32'hFE051AE3; // bne x10,x0,amo
        rom[35] = 32'h00A00113; // addi x2,x0,10
        rom[36] = 32'h0020A023; // sw x2,0(x1)
        rom[37] = 32'h00402483; // lw x9,4(x0)
        rom[38] = 32'hFE048EE3; // beq x9,x0,wait
        rom[39] = 32'h00002683; // lw x13,0(x0)
        rom[40] = 32'h010007EF; // jal x15,print_num
        rom[41] = 32'h00A00113; // addi x2,x0,10
        rom[42] = 32'h0020A023; // sw x2,0(x1)
        rom[43] = 32'h0000006F; // jal x0,halt
        rom[44] = 32'h00000613; // addi x12,x0,0
        rom[45] = 32'h00B6A533; // slt x10,x13,x11
        rom[46] = 32'h00051863; // bne x10,x0,pn_digits
        rom[47] = 32'h40B686B3; // sub x13,x13,x11
        rom[48] = 32'h00160613; // addi x12,x12,1
        rom[49] = 32'hFF1FF06F; // jal x0,div10
        rom[50] = 32'h00060663; // beq x12,x0,pn_ones
        rom[51] = 32'h03060613; // addi x12,x12,48
        rom[52] = 32'h00C0A023; // sw x12,0(x1)
        rom[53] = 32'h03068693; // addi x13,x13,48
        rom[54] = 32'h00D0A023; // sw x13,0(x1)
        rom[55] = 32'h00078067; // jalr x0,x15,0
    end

endmodule
 
// ===================== instmem1.v =====================
// core 1: prime detection for 51..100, adds count atomically, sets done flag
module instmem1(a, inst);

    input [31:0] a;
    output [31:0] inst;

    reg [31:0] rom [0:63];
    integer i;

    assign inst = rom[a[7:2]];

    initial begin
        for (i = 0; i < 64; i = i + 1)
            rom[i] = 32'h00000013;

        rom[0] = 32'h100000B7; // lui x1,0x10000
        rom[1] = 32'h00200193; // addi x3,x0,2
        rom[2] = 32'h00A00593; // addi x11,x0,10
        rom[3] = 32'h00000213; // addi x4,x0,0
        rom[4] = 32'h03300293; // addi x5,x0,51
        rom[5] = 32'h06500313; // addi x6,x0,101
        rom[6] = 32'h06628263; // beq x5,x6,finish
        rom[7] = 32'h0032A533; // slt x10,x5,x3
        rom[8] = 32'h04051A63; // bne x10,x0,skip
        rom[9] = 32'h00200393; // addi x7,x0,2
        rom[10] = 32'h00400413; // addi x8,x0,4
        rom[11] = 32'h0082A533; // slt x10,x5,x8
        rom[12] = 32'h02051863; // bne x10,x0,is_prime
        rom[13] = 32'h000284B3; // add x9,x5,x0
        rom[14] = 32'h0074A533; // slt x10,x9,x7
        rom[15] = 32'h00051663; // bne x10,x0,mod_done
        rom[16] = 32'h407484B3; // sub x9,x9,x7
        rom[17] = 32'hFF5FF06F; // jal x0,mod
        rom[18] = 32'h02048663; // beq x9,x0,skip
        rom[19] = 32'h00740433; // add x8,x8,x7
        rom[20] = 32'h00740433; // add x8,x8,x7
        rom[21] = 32'h00140413; // addi x8,x8,1
        rom[22] = 32'h00138393; // addi x7,x7,1
        rom[23] = 32'hFD1FF06F; // jal x0,test_d
        rom[24] = 32'h00120213; // addi x4,x4,1
        rom[25] = 32'h000286B3; // add x13,x5,x0
        rom[26] = 32'h038007EF; // jal x15,print_num
        rom[27] = 32'h02000113; // addi x2,x0,32
        rom[28] = 32'h0020A023; // sw x2,0(x1)
        rom[29] = 32'h00128293; // addi x5,x5,1
        rom[30] = 32'hFA1FF06F; // jal x0,next_n
        rom[31] = 32'h100024AF; // lr.w x9,(x0)
        rom[32] = 32'h004484B3; // add x9,x9,x4
        rom[33] = 32'h1890252F; // sc.w x10,x9,(x0)
        rom[34] = 32'hFE051AE3; // bne x10,x0,amo
        rom[35] = 32'h00A00113; // addi x2,x0,10
        rom[36] = 32'h0020A023; // sw x2,0(x1)
        rom[37] = 32'h00100493; // addi x9,x0,1
        rom[38] = 32'h00902223; // sw x9,4(x0)
        rom[39] = 32'h0000006F; // jal x0,halt
        rom[40] = 32'h00000613; // addi x12,x0,0
        rom[41] = 32'h00B6A533; // slt x10,x13,x11
        rom[42] = 32'h00051863; // bne x10,x0,pn_digits
        rom[43] = 32'h40B686B3; // sub x13,x13,x11
        rom[44] = 32'h00160613; // addi x12,x12,1
        rom[45] = 32'hFF1FF06F; // jal x0,div10
        rom[46] = 32'h00060663; // beq x12,x0,pn_ones
        rom[47] = 32'h03060613; // addi x12,x12,48
        rom[48] = 32'h00C0A023; // sw x12,0(x1)
        rom[49] = 32'h03068693; // addi x13,x13,48
        rom[50] = 32'h00D0A023; // sw x13,0(x1)
        rom[51] = 32'h00078067; // jalr x0,x15,0
    end

endmodule
 
 
// ===================== top.v =====================


module dual #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD = 9600
)(clk,clrn,pc0,pc1,inst0,inst1,dataout,alu0,alu1,tx0,tx1);

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
wire en_uart0,en_uart1;
wire busy0,busy1;
wire wr_uart0,wr_uart1;
assign en=(grant0||grant1);
assign en0=((!mreq0)||grant0)&&(!busy0||!wr_uart0);
assign en1=((!mreq1)||grant1)&&(!busy1||!wr_uart1);
assign sc=(grant0 && sc0)||(grant1 && sc1);
assign lr=(grant0 && lr0)||(grant1 && lr1);



instmem0 instm0(
    .a(pc0),.inst(inst0)
);
instmem1 instm1(
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

uart #(.CLK_FREQ(CLK_FREQ),.BAUD(BAUD)) u0(.clk(clk),.rst(~clrn),.wr_en(wr_uart0),.address(alu0),.write_data(datain0),.busy(busy0),.tx(tx0));
uart #(.CLK_FREQ(CLK_FREQ),.BAUD(BAUD)) u1(.clk(clk),.rst(~clrn),.wr_en(wr_uart1),.address(alu1),.write_data(datain1),.busy(busy1),.tx(tx1));
endmodule

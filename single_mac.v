`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.08.2026 18:04:21
// Design Name: 
// Module Name: single_mac
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module single_mac(
    input clk,reset,start,
    output [3:0]mm
     );
reg signed [7:0] w_out_data;
reg signed [7:0] b_out_data;
reg signed [7:0] i_out_data;
parameter s=4;//for increasing the states
parameter w_l=52896,b_l=122,i_l=784;
reg signed [7:0]weights[0:w_l-1];
reg signed [7:0]biases[0:b_l-1];
reg signed [7:0]pic[0:i_l-1];

initial begin
    $display("Loading weights...");
    $readmemb("D:/fpga/prj/tinyML/weights.txt", weights);
    $display("weights[0] = %d", weights[0]);
    $readmemb("D:/fpga/prj/tinyML/baises.txt",biases);
    $readmemb("D:/fpga/prj/tinyML/picture.txt",pic);
end

reg w_en,b_en,i_en;
reg w_r_en,b_r_en,i_r_en;
reg [15:0]w_addr;
reg [6:0]b_addr;
reg [9:0]i_addr,i_addr1;
reg i_r_en_1,i_en_1,reset_i_1;
parameter s0=0,s1=1,s2=2,s3=3,s4=4,s5=5,s6=6,s7=7,s8=8,s9=9,s10=10,s11=11,s12=12,s13=13,s14=14,s15=15,s16=16,s17=17,s18=18,s19=19,s20=20,s21=21,s22=22,s23=23,s24=24,s25=25,s26=26,s27=27,s28=28;
reg [4:0]state,nextstate;
reg [16:0]w_c,w_c_reg;
reg [6:0]b_c,b_c_reg;
reg [9:0]i_c,i_c_reg;
reg load_weights,load_baises;
reg [9:0]c,c_reg;
reg compute,add_bais,reset_w,reset_i,reset_b;
reg[6:0]px,p_reg;
reg reset_a;
reg tap;
reg [5:0]xxx;

reg compute_reg;



always @(posedge clk or posedge reset) begin
    if (reset) begin
        compute_reg <= 1'b0;
    end else begin
        compute_reg <= compute; // Captures the 1-cycle BRAM read latency!
    end
end


always @(posedge clk) begin
    if (reset) begin
        state      <= s6;
        w_c_reg    <= 0;
        b_c_reg    <= 0; 
        i_c_reg    <= 0;
        c_reg<=0;
        p_reg<=0;
    end
    else begin
        state      <= nextstate;
        w_c_reg    <= w_c;       
        b_c_reg    <= b_c;
        i_c_reg    <= i_c;
        c_reg      <= c;
        p_reg<=px;
    end
end

always@(*)begin
    nextstate   = state;
    w_en        = 0;
    i_en        = 0;
    b_en        = 0;
    w_r_en      = 0;
    b_r_en      = 0;
    i_r_en      = 0;
    w_c         = w_c_reg;
    b_c         = b_c_reg;
    i_c         = i_c_reg;
    c=c_reg;
    compute=0;
    add_bais    = 0;
    px=p_reg;
    reset_w=0;reset_i=0;reset_b=0;reset_a=0;
    tap=0;reset_i_1=0;i_en_1=0;xxx=0;i_r_en_1=0;
    case(state)
        s6: begin
                if(start)
                    nextstate=s7;
                reset_w=1;reset_i=1;reset_b=1;
            end
        s7: begin
                w_r_en=1;i_r_en=1;
                  nextstate=s8;
                  compute=1;
            end
        s8: begin
                w_r_en=1;i_r_en=1;      
                compute=1; 
                if(c_reg==10'd782)begin
                    nextstate=s9;
                    b_r_en=1;
                    c=0;
                    
                end
                else begin
                    c=c_reg+1;
                end
            end
         s9: begin
                add_bais=1;
                reset_i=1;
                if(c_reg==10'd6)begin
                    c=0;
                    tap=1;
                    if(p_reg==63)begin
                        nextstate=s10;
                        px=0;                       
                    end
                    else begin
                        px=p_reg+1;
                        nextstate=s7;
                        
                    end
                    reset_a=1;
                end
                else begin
                    c=c_reg+1;
                end
            end
        s10: begin
                  xxx=6'd63;
                  tap=1;
                  i_en_1=1;
                  if(i_addr1==10'd63) begin
                        nextstate=s14;
                  end
            end
        s14: begin
                  nextstate=s11;
                  reset_i_1=1;
             end
        s11: begin
                w_r_en=1;i_r_en_1=1;
                  nextstate=s12;
                  compute=1;
            end
        s12: begin
                w_r_en=1;i_r_en_1=1;      
                compute=1; 
                if(c_reg==10'd62)begin
                    nextstate=s13;
                    b_r_en=1;
                    c=0;
                    
                end
                else begin
                    c=c_reg+1;
                end
            end
         s13: begin
                add_bais=1;
                reset_i_1=1;
                if(c_reg==10'd6)begin
                    c=0;
                    tap=1;
                    if(p_reg==31)begin
                        nextstate=s15; 
                        px=0;                      
                    end
                    else begin
                        px=p_reg+1;
                        nextstate=s11;
                       
                    end
                     reset_a=1;
                end
                else begin
                    c=c_reg+1;
                end
            end
         s15: begin
                    reset_i_1=1;
                    nextstate=s16;
              end
         s16: begin
                  xxx=6'd31;
                  tap=1;
                  i_en_1=1;
                  if(i_addr1==10'd31) begin
                        nextstate=s17;
                  end
              end
         s17: begin
                  reset_i_1=1;
                  nextstate=s18;
              end
        s18: begin
                i_r_en_1=1;w_r_en=1;
                  nextstate=s19;
                  compute=1;
            end
        s19: begin
                w_r_en=1;i_r_en_1=1;      
                compute=1; 
                if(c_reg==10'd30)begin
                    nextstate=s20;
                    b_r_en=1;
                    c=0; 
                end
                else begin
                    c=c_reg+1;
                end
            end
         s20: begin
                add_bais=1;
                reset_i_1=1;
                if(c_reg==10'd6)begin
                    c=0;
                    tap=1;
                    if(p_reg==15)begin
                        nextstate=s21; 
                        px=0;                      
                    end
                    else begin
                        px=p_reg+1;
                        nextstate=s18;
                       
                    end
                     reset_a=1;
                end
                else begin
                    c=c_reg+1;
                end
            end
         s21: begin
                    nextstate=s22;
                    reset_i_1=1;
              end
         s22: begin
                  xxx=6'd15;
                  tap=1;
                  i_en_1=1;
                  if(i_addr1==10'd15) begin
                        nextstate=s23;
                  end
              end
         s23: begin
                  reset_i_1=1;
                  nextstate=s24;
              end
        s24: begin
                i_r_en_1=1;w_r_en=1;
                  nextstate=s25;
                  compute=1;
            end
        s25: begin
                w_r_en=1;i_r_en_1=1;      
                compute=1; 
                if(c_reg==10'd14)begin
                    nextstate=s26;
                    b_r_en=1;
                    c=0; 
                end
                else begin
                    c=c_reg+1;
                end
            end
         s26: begin
                add_bais=1;
                reset_i_1=1;
                if(c_reg==10'd6)begin
                    c=0;
                    tap=1;
                    if(p_reg==9)begin
                        nextstate=s27; 
                        px=0;                      
                    end
                    else begin
                        px=p_reg+1;
                        nextstate=s24;
                       
                    end
                     reset_a=1;
                end
                else begin
                    c=c_reg+1;
                end
            end
           s27: begin
                    if(!start)
                        nextstate=s6;
                end
              
                    
        endcase
end
reg signed[31:0]accu,accu1,accu2,shi,p,r;
reg signed[7:0]f;

always@(posedge clk) begin
    if(reset|reset_a)begin
        accu<=0;
        p<=0;
        r<=0;
    end
    else if(compute_reg) begin
        p<=w_out_data;
        r<=i_out_data;
        accu<=accu+(w_out_data*i_out_data);
    end
end

reg signed[7:0]bl;

always@(posedge clk)begin
    
    if(add_bais==1)begin
        bl<=b_out_data;
        accu1<=accu+bl;
        accu2<=accu1+32'd64;
        shi<=accu2>>>7;
        if(shi>32'sd127)begin
            f<=8'sd127;
        end
        else if(shi<0)begin
                f<=0;
        end
        else 
                f<=shi;
    end
end
integer i;
reg signed [7:0]out[0:63];
always@(posedge clk)begin
    if(reset)begin
        for(i=0;i<=63;i=i+1)begin
            out[i]<=0;
        end
    end
    else if(tap)begin
        out[0]<=f;
        for(i=1;i<=63;i=i+1)begin
            out[i]<=out[i-1];
        end 
    end
end

//weights memory
always@(posedge clk)begin
    if(reset)begin
        w_addr<=16'd0;
    end
    else if(w_r_en)begin
        w_out_data<=weights[w_addr];
        w_addr<=w_addr+1;
    end
    else if(reset_w)
        w_addr<=0;
end
//baises memory
always@(posedge clk)begin
    if(reset)begin
        b_addr<=7'd0;
    end
    else if(b_r_en)begin
        b_out_data<=biases[b_addr];
        b_addr<=b_addr+1;
    end
    else if(reset_b) begin
        b_addr<=0;
    end
end
//picture memory
always@(posedge clk)begin
    if(reset)begin
        i_addr<=10'd0;
        i_addr1<=10'd0;
    end
    else if(i_r_en)begin
        i_out_data<=pic[i_addr];
        i_addr<=i_addr+1;
    end
    else if(reset_i) begin
        i_addr<=0;
    end
    else if(i_en_1) begin
        pic[i_addr1]<=out[xxx];
        i_addr1<=i_addr1+1;
    end
    else if(i_r_en_1)begin
        i_out_data<=pic[i_addr1];
        i_addr1<=i_addr1+1;
    end
    else if(reset_i_1) begin
        i_addr1<=0;
    end

end

    reg [7:0] max_val;
    reg [3:0]max_idx;
    always @(*) begin
        max_val = out[0];
        max_idx = 4'd0;
        
        for (i = 1; i < 10; i = i + 1) begin
            if (out[i] > max_val) begin
                max_val = out[i];
                max_idx = 4'd9 - i[3:0];
            end
        end
    end
assign mm=max_idx;
endmodule


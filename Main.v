`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 

// Design Name: 
// Module Name: Main
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


module Main(
    input clk,
    input rst_n,
    input buttom_A,
    input buttom_S,
    input buttom_W,
    input buttom_D,
    input buttom_X,
    input buttom_light,
    output reg [7:0] seg,
    output reg light,
    output reg power_on
    );

parameter state_off=1'd0,state_on=1'd1;
parameter state_standby=4'd0000,state_menu=4'd0100,state_run_one=4'd0110;
parameter state_run_two=4'd0120,state_run_thr=4'd0130,state_run_cle=4'd0140;
parameter state_exit_from_thr=4'd0131;
parameter state_search=4'd0200,state_search_runtime=4'd0210,state_search_efftime=4'd0220,state_search_altime=4'd0230;
parameter state_set_efftime_h=4'd0321,state_set_efftime_m=4'd0322,state_set_efftime_s=4'd0323;
parameter state_set_altime_h=4'd0331,state_set_altime_m = 4'd0332,state_set_altime_s = 4'd0333;

parameter rst_altime=6'd100000;  //智能提醒时间，六位分别代表时分秒
parameter rst_efftime=6'd000005;  //手势时间
parameter rst_time=6'd000000;    //初始时间
parameter rst_cnt=13'd0000000000000;  //对长按S，以及A，D按键后的手势时间计时，初始时�???
parameter cnt_S_time=13'd0000000000030; 
parameter rst_cnt_AD=13'd9000000000000; //初始设一个较大�?�表示无�???
parameter  cnt_efftime=13'd00000000050;

reg [4:0] state={state_off,4'd0000},nxt_state={state_off,4'd0000};
reg [5:0] efftime=rst_efftime,altime=rst_altime,runtime=rst_time,nowtime=rst_time;
reg [12:0] cnt_S=rst_cnt,cnt_A=rst_cnt_AD,cnt_D=rst_cnt_AD;  //count second
reg [6:0] clk_sec=7'd0000000;    //1s clk
reg [7:0] seg;
reg [2:0] buttom_effect=3'd000;  //表示按键 S（有无长按），A，D（有没有�???5s内按�??? 

//initial


//对clk监听
always @(posedge clk,negedge rst_n)begin
    if (state[4]==1'd0)begin       //关机
        if (buttom_effect[2]==1'd1)begin    //S按键长按
            cnt_S<=cnt_S+1;
            if (cnt_S==cnt_S_time)begin
                nxt_state<={state_on,state_standby};
                cnt_S<=rst_cnt;
                buttom_effect[2]<=1'd0;
            end
        end
        if (buttom_effect[1]==1'd1)begin //5s A按键
            cnt_A<=cnt_A+1;
            if(cnt_A<cnt_efftime && buttom_effect[0]==1'd1 &&cnt_A > cnt_D)begin //在有效时间内还按�??? D 键，�???�???
                nxt_state<={state_on,state_standby};
                cnt_A<=rst_cnt_AD;
                cnt_D<=rst_cnt_AD;
                buttom_effect[1]<=1'd0;
                buttom_effect[0]<=1'd0;
            end
            if(cnt_A==cnt_efftime)begin
                cnt_A<=rst_cnt_AD;
                buttom_effect[1]<=1'd0;
            end
        end
    end
    
    if (state==5'd10000)begin       //待机�??
        if (buttom_effect[2]==1'd1)begin    //S按键长按
            cnt_S<=cnt_S+1;
            if (cnt_S==cnt_S_time)begin     //达到3s，关
                nxt_state<={state_off,4'd0000};
                cnt_S<=rst_cnt;
                buttom_effect[2]<=1'd0;
            end
        end
        if (buttom_effect[0]==1'd1)begin //5s�??? D按键
            cnt_D<=cnt_D+1;
            if(cnt_D<cnt_efftime && buttom_effect[1]==1'd1 && cnt_D >cnt_A )begin //在有效时间内还按�??? A 键，关机
                nxt_state<={state_off,4'd0000};
                cnt_A<=rst_cnt_AD;              //其实在state 监视中也有这部分复原
                cnt_D<=rst_cnt_AD;
                buttom_effect[1]<=1'd0;
                buttom_effect[0]<=1'd0;
            end
            if(cnt_D==cnt_efftime)begin
                cnt_D<=rst_cnt_AD;
                buttom_effect[0]<=1'd0;
            end
        end
    end
    state<=nxt_state;
end

//�??? state 监听
always @(state)begin
    buttom_effect<=3'd000;  //清除之前的按键效果，A，D按键�???5s内按的效�???
    cnt_S<=rst_cnt;
    cnt_A<=rst_cnt_AD;
    cnt_D<=rst_cnt_AD;

    case (state)
        {5'd00000}:begin        //关机�??
            power_on<=1'd0;
            seg<=8'd00000000;
            efftime<=rst_efftime;
            altime<=rst_altime;
            nowtime<=rst_time;
            runtime<=rst_time;
        end
        {5'd10000}:begin        //待机�??
            
        end
    endcase
end

//对rst_n监听


//对按键S监听
//功能�???1.长按三秒�???关机�???2.在menu下，按S进入运行挡位2;3.在search状�?�下，按S进入设置手势时间�???4.在set中，按S表示确认，从h到m到s，最后按S确认回到查询状�??
//首先判断状，然后对应不同的功能修 nxt_state 和对应的参数
always @(posedge buttom_S)begin
    casex (state)
        {5'd00000}:begin //关机状�??
            buttom_effect[2]<=1'd1;
            cnt_S<=rst_cnt;
        end
        {5'd10000}:begin //待机状�??
            buttom_effect[2]<=1'd1;
            cnt_S<=rst_cnt;
        end
        {5'd10100}:begin //进入run模式2
            nxt_state<={1'd1,state_run_two};
        end
        {5'd10200}:begin //进入search 2
            nxt_state<={1'd1,state_search_efftime};
        end
        {5'd10321}:begin //设置效果时间
            nxt_state<={1'd1,state_set_efftime_m};
        end
        {5'd10322}:begin //设置效果时间
            nxt_state<={1'd1,state_set_efftime_s};
        end
        {5'd10323}:begin //设置效果时间
            nxt_state<={1'd1,state_search_efftime};
        end
        {5'd10331}:begin //设置警告时间
            nxt_state<={1'd1,state_set_altime_m};
        end
        {5'd10332}:begin //设置警告时间
            nxt_state<={1'd1,state_set_altime_s};
        end
        {5'd10333}:begin //设置警告时间
            nxt_state<={1'd1,state_search_altime};
        end
    endcase
end

//对按键S释放监听
always @(negedge buttom_S)begin
    buttom_effect[2]<=1'd0;
end

//对按键A监听
//功能�???1.在待机�?�关机时手势按键�???2.表示从菜单状态切换到运行挡位1�??? 
//3.表示从查询状态，到查询runtime状�?�；4.在设置时间状态，表示++�???
always @(posedge buttom_A) begin //
    case (state)
        5'd00000:begin
            buttom_effect[1]<=1'd1;
            cnt_A<=rst_cnt;
        end
        5'd10000:begin
            buttom_effect[1]<=1'd1;
            cnt_A<=rst_cnt;
        end
        5'd10100:begin
            nxt_state<={1'd1,state_run_one};
        end
        5'd10200:begin
            nxt_state<={1'd1,state_search_runtime};
        end
        5'd10321:begin    //设置手势时间（小时）
            efftime[5:4]<=efftime[5:4]+1;
            if(efftime[5:4]==2'd24)begin
                efftime[5:4]<=2'd00;
            end
        end
        5'd10322:begin
            efftime[3:2]<=efftime[3:2]+1;
            if(efftime[3:2]==2'd60)begin
                efftime[3:2]<=2'd00;
            end
        end
        {5'd10323}:begin
            efftime[1:0]<=efftime[1:0]+1;
            if(efftime[1:0]==2'd60)begin
                efftime[1:0]<=6'd00;
            end
        end
        {5'd10331}:begin    //设置提醒时间（小时）
            altime[5:4]<=altime[5:4]+1;
            if(altime[5:4]==2'd24)begin
                altime[5:4]<=2'd00;
            end
        end
        {5'd10332}:begin
            altime[3:2]<=altime[3:2]+1;
            if(altime[3:2]==2'd60)begin
                altime[3:2]<=2'd00;
            end
        end
        {5'd10333}:begin
            altime[1:0]<=altime[1:0]+1;
            if(altime[1:0]==2'd60)begin
                altime[1:0]<=2'd00;
            end
        end
    endcase
end

//对按键D监听
//功能�???1.在待机�?�关机时手势按键�???2.表示从菜单状态切换到运行挡位3�???
//3.表示从查询状态，到查询efftime状�?�；4.在设置时间状态，表示--�???
always @(posedge buttom_D) begin
    case (state)
        {5'd00000}:begin
            buttom_effect[0]<=1'd1;
            cnt_D<=rst_cnt;
        end
        {5'd10000}:begin
            buttom_effect[0]<=1'd1;
            cnt_D<=rst_cnt;
        end
        {5'd10100}:begin
            nxt_state<={1'd1,state_run_thr};
        end
        {5'd10200}:begin
            nxt_state<={1'd1,state_search_efftime};
        end
        {5'd10321}:begin    //设置手势时间（小时）
            if(efftime[5:4]==2'd00)begin
                efftime[5:4]<=2'd24;
            end
            efftime[5:4]<=efftime[5:4]-1;
        end
        {5'd10322}:begin
            if(efftime[3:2]==2'd00)begin
                efftime[3:2]<=2'd60;
            end
            efftime[3:2]<=efftime[3:2]-1;
        end
        {5'd10323}:begin
            if(efftime[1:0]==2'd00)begin
                efftime[1:0]<=2'd60;
            end
            efftime[1:0]<=efftime[1:0]-1;
        end
        {5'd10331}:begin    //设置提醒时间（小时）
            if(altime[5:4]==2'd00)begin
                altime[5:4]<=2'd24;
            end
            altime[5:4]<=altime[5:4]-1;
        end
        {5'd10332}:begin
            if(altime[3:2]==2'd00)begin
                altime[3:2]<=2'd60;
            end
            altime[3:2]<=altime[3:2]-1;
        end
        {5'd10333}:begin
            if(altime[1:0]==2'd00)begin
                altime[1:0]<=2'd60;
            end
            altime[1:0]<=altime[1:0]-1;
        end
    endcase
end

//对按键X监听
//功能�???1.菜单状�?�到自清洁状态；2.待机状�?�到查询状�?�；3.查询2�???3时进入设置状�???
always @(posedge buttom_X)begin
    case (state)
        {5'd10100}:begin
            nxt_state<={1'd1,state_run_cle};
        end
        {5'd10000}:begin
            nxt_state<={1'd1,state_search};
        end
        {5'd10210}:begin
            nxt_state<={1'd1,state_set_efftime_h};
        end
        {5'd10220}:begin
            nxt_state<={1'd1,state_set_altime_h};
        end
    endcase
end

//对按键W监听
//功能：表示菜单和返回，从挡位1�???2�???3、自清洁 回到菜单，从菜单回到待机状�?�，从查询状态回到待机状态，从待机状态到菜单状�??
always @(posedge buttom_W)begin
    case (state)
        5'd10000:begin
                nxt_state <= {1'd1,state_menu};
           end
        {5'd10110}:begin    //四个返回菜单
            nxt_state<={1'd1,state_menu};
        end
        {5'd10120}:begin
            nxt_state<={1'd1,state_menu};
        end
        {5'd10130}:begin
            nxt_state<={1'd1,state_menu};
        end
        {5'd10140}:begin
            nxt_state<={1'd1,state_menu};
        end
        {5'd10100}:begin    //两个返回待机状�??
            nxt_state<={1'd1,state_standby};    
        end 
        {5'd10200}:begin
            nxt_state<={1'd1,state_standby};
        end
        {5'd10210}:begin    //三个返回查询状�??
            nxt_state<={1'd1,state_search};     
        end
        {5'd10220}:begin
            nxt_state<={1'd1,state_search};
        end
        {5'd10230}:begin
            nxt_state<={1'd1,state_search};
        end
    endcase
end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/27 08:27:20
// Design Name: 
// Module Name: mode_switch
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


module mode_switch(input clk,rst,button_menu,button_smock1,
    button_smock2,button_smock3,button_clean,
    output [4:0] state,next_state);
reg [4:0] state,next_state;
reg [31:0] seconds;
reg [31:0] seconds_smock3;
reg countdown_active,countdown_active_smock3;  //表示倒计时？
reg smock3_once;    //表示smock3状态是否已经进入过
parameter standby=5'b00000,menu=5'b00001,smock1=5'b00010,smock2=5'b00100,smock3=5'b01000,clean=5'b10000;
parameter countdown60=6'd60,countdown180=6'd180;

always @(posedge clk,negedge rst)begin
    if(~rst)begin
        state<=standby;
        seconds<=0;
        smock3_once=1'b0;
    end else
        state<=next_state;
end
always @(posedge clk,negedge rst,countdown_active)begin
    if(rst && countdown_active && seconds!=0)begin
        seconds<=seconds-1;
    end
end
always @(posedge clk,negedge rst,countdown_active_smock3)begin
    if(rst && countdown_active_smock3 && seconds_smock3!=0)begin
        seconds_smock3<=seconds_smock3 -1;
    end
end

parameter period=100000000;
reg clkout;
reg suspend;
reg [31:0] cnt;
reg [3:0] second_1;
reg [2:0] second_10;
reg [3:0] minute_1;
reg [2:0] minute_10;
reg [3:0] hour;
always @(posedge clk,negedge rst)begin
    if(~rst)begin
      cnt<=0;
      clkout<=0;
    end else begin
      if(cnt == (period>>1)-1)begin
            clkout=~clkout;
            cnt<=0;
      end else begin
            cnt<=cnt+1;
      end
   end
end


always @(posedge clkout,negedge rst)begin
    if(~rst)begin
        second_1<=0;second_10<=0;second_10<=0;minute_1<=0;minute_10<=0;hour<=0;
    end else if(suspend)begin
                if(second_1>4'b1001)begin
                    second_1<=second_1-4'b1001;
                    second_10<=second_10+1'b1;
                end
                if(second_10>3'b110)begin
                    second_10<=second_10-3'b110;
                    minute_1<=minute_1+1'b1;
                end
                if(minute_1>4'b1001)begin
                    minute_1<=minute_1-4'b1001;
                    minute_10<=minute_10+1'b1;
                end
                if(minute_10>3'b110)begin
                    minute_10<=minute_10-3'b110;
                    hour<=hour+1'b1;
                end
         end
end

always @(state,button_menu,button_smock1,button_smock2,button_smock3,button_clean)begin
    case(state)
    standby:if(button_menu==1'b1)begin
                next_state=menu;
            end else begin
                next_state=standby;
            end
    menu:if(button_smock1==1'b1)begin
            next_state=smock1;suspend=1'b1;
         end else if(button_smock2==1'b1)begin
            next_state=smock2;suspend=1'b1;
         end else if(button_smock3==1'b1 && (~smock3_once))begin
            next_state=smock3;suspend=1'b1;
         end else if(button_clean==1'b1) begin
            next_state=clean;
         end else begin
            next_state=menu;suspend=1'b0;
         end
    smock1:if(button_menu==1'b1)begin
             next_state=standby;suspend=1'b0;
           end else if(button_smock2==1'b1)begin
             next_state=smock2;suspend=1'b1;
           end else begin
             next_state=smock1;suspend=1'b1;
           end
    smock2:if(button_menu==1'b1)begin
             next_state=standby;suspend=1'b0;
            end else if(button_smock1==1'b1)begin
             next_state=smock1;suspend=1'b1;
            end else begin
             next_state=smock2;suspend=1'b1;
            end
    smock3:if(~countdown_active_smock3) begin
             countdown_active_smock3=1'b1;
             seconds_smock3=countdown60;suspend=1'b1;
           end else if(seconds_smock3==0)begin
                countdown_active_smock3=1'b0;
                next_state=smock2;suspend=1'b1;
           end else 
            if(button_menu==1'b1)begin
             if(~countdown_active)begin
                countdown_active=1'b1;
                seconds=countdown60;suspend=1'b1;
             end else if(seconds==0)begin
                countdown_active=1'b0;
                next_state=standby;suspend=1'b0;
            end 
           end else begin
              next_state=smock3;suspend=1'b1;
            end
     clean:if(~countdown_active)begin
                  countdown_active=1'b1;
                  seconds=countdown180;suspend=1'b0;
           end else if(seconds==0)begin
                  countdown_active=1'b0;
                  next_state=standby;suspend=1'b0;
           end else begin
                next_state=clean;suspend=1'b0;
           end
     endcase
end
endmodule

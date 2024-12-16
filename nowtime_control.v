`timescale 1ns / 1ps
`include "PARAMETER.v" 
module nowtime_control(
    input clk,
    input clkout,
    input rst,
    input [23:0]nowtime,
    input save_nowtime_yet,
    output reg[23:0] new_nowtime,
);

    //将 contorl_module 中关于nowtime的控制转移到这里
    always @(posedge clkout,negedge rst)begin
        if(!rst)begin
            new_nowtime <= nowtime;
        end
        else begin
            if(state[6]==1'b1)begin
                if(nowtime[3:0]==4'b1001)begin //second ones
                    if(nowtime[7:4]==4'b0101)begin //second tens
                        if(nowtime[11:8]==4'b1001)begin //minute ones
                            if(nowtime[15:12]==4'b0101)begin  //minute tens
                                if(nowtime[19:16]==4'b1001)begin //hour ones ,9+1=10
                                    new_nowtime[23:20]<=nowtime[23:20]+4'b0001;
                                    new_nowtime[19:0]<=20'b00000000000000000000;
                                end
                                else begin
                                    if(nowtime[23:20]==4'b0010 && nowtime[19:16]==4'b0011) //23+1=0
                                        new_nowtime=24'b000000000000000000000000;
                                    else begin
                                        new_nowtime[19:16]<=nowtime[19:16]+4'b0001;
                                        new_nowtime[15:0]<=16'b0000000000000000;
                                    end
                                end
                            end
                            else begin
                                new_nowtime[15:12]<=nowtime[15:12]+4'b0001;
                                new_nowtime[11:0]<=12'b000000000000;
                            end
                        end
                        else begin
                            nowtime[11:8]<=nowtime[11:8]+4'b0001;
                            nowtime[7:0]<=8'b00000000;
                        end
                    end
                    else begin
                        nowtime[3:0]<=4'b0000;
                        nowtime[7:4]<=nowtime[7:4]+4'b0001;
                    end
                end
                else nowtime[3:0]<=nowtime[3:0]+4'b0001;
            end
            else begin
                nowtime<=24'b0;
            end

            // nowtimes
            if(save_nowtime_yet==1'b1)begin
                nowtime<=save_nowtime;
            end
        end
    end
endmodule
`timescale 1ns / 1ps
`include "PARAMETER.v" 
module worktime_control(
    input clkout,
    input rst,
    input [6:0]state,
    input suspend,
    input recover_yet,
    input [23:0]worktime,
    input clean_worktime_yet,
    output reg[23:0]new_worktime
);

    always @(posedge clkout,negedge rst)begin
        if(!rst)begin
            new_worktime<=24'b0;
        end
        else begin
            if(state[6]==1'b0)begin
                new_worktime<=0;
            end
            else if(recover_yet==1'b1)begin
                new_worktime<=24'b0;
            end
            else begin
                //suspend,countdown_storm,countdown_clean
                if(suspend==1'b1)begin
                    new_worktime[3:0]<=worktime[3:0]+4'b0001;
                    if(worktime[3:0]==4'b1010)begin
                        new_worktime[3:0]<=8'b0000;
                        new_worktime[7:4]<=worktime[7:4]+4'b0001;
                    end
                    if(worktime[7:0]==8'b01100000)begin
                        new_worktime[7:0]<=8'b00000000;
                        new_worktime[15:8]<=worktime[15:8]+8'b00000001;
                        if(worktime[15:8]==8'b01100000)begin
                            new_worktime[15:8]<=8'b00000000;
                            new_worktime[23:16]<=worktime[23:16]+8'b00000001;
                        end
                    end
                end
                else if(clean_worktime_yet==1'b1)begin
                    new_worktime<=0;
                end
            end
        end
    end
endmodule
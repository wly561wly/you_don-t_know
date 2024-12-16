`timescale 1ns / 1ps
`include "PARAMETER.v" 
module control_module(
    input [6:0]state,
    input sign_pos_A,
    input sign_pos_S,
    input sign_pos_W,
    input sign_pos_X,
    input sign_neg_X,
    input sign_pos_D,
    input switch_P,
    input light_dip,
    input rst,
    input clk,
    output reg [31:0] sign,
    output reg [6:0] nxt_state,
    output reminder,
    output opening,
    output light_on
    );

    parameter period=100000000,re_cnt=48'h000000000000;

    reg [23:0]nowtime,worktime,remindtime,switchtime;
    reg [23:0]save_nowtime,save_remindtime,save_switchtime;

    wire [47:0]cnt_5s;

    // Generate clk_100Hz
    reg clk_100Hz;
    reg [15:0] clk_100Hz_cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            clk_100Hz <= 0;
            clk_100Hz_cnt <= 0;
        end else begin
            if (clk_100Hz_cnt == 99999) begin
                clk_100Hz <= ~clk_100Hz;
                clk_100Hz_cnt <= 0;
            end else begin
                clk_100Hz_cnt <= clk_100Hz_cnt + 1;
            end
        end
    end

    reg [2:0]buttom_effect; //S,A,D
    reg [47:0]cnt_S,cnt_A,cnt_D,cnt_wait,cnt_error;

    reg clkout; //1s
    reg [31:0]cnt_clk;
    reg storm_once; //only one time for storm
    reg countdown_storm_yet,countdown_clean_yet,save_nowtime_yet,save_remindtime_yet,save_switchtime_yet;
    reg clean_worktime_yet;
    reg recover_yet;
    reg [7:0]countdown_storm;
    reg [11:0]countdown_clean;
    

    assign reminder=(clkout)&(worktime>=remindtime);//reminder for clean
    assign opening=state[6];  //opening

    reg suspend; // work or not -> worktime++
    assign light_on=(state[6])&light_dip;

    assign cnt_5s=(switchtime[23:20]*10+switchtime[19:16])*3600+(switchtime[15:12]*10+switchtime[11:8])*60+(switchtime[7:4]*10+switchtime[3:0]);

    wire [23:0]new_nowtime;
    //nowtime_control
    nowtime_control nowtime_control(
        .clk(clk),
        .clkout(clkout),
        .state(state),
        .rst(rst),
        .nowtime(nowtime),
        .save_nowtime_yet(save_nowtime_yet),
        .save_nowtime(save_nowtime),
        .new_nowtime(new_nowtime)
    );

    always @(new_nowtime)begin
        nowtime<=new_nowtime;
    end

    wire [23:0]new_worktime;
    //worktime_control
    worktime_control worktime_control(
        .clkout(clkout),
        .rst(rst),
        .state(state),
        .suspend(suspend),
        .recover_yet(recover_yet),
        .worktime(worktime),
        .clean_worktime_yet(clean_worktime_yet),
        .new_worktime(new_worktime)
    );
    always @(new_worktime)begin
        worktime<=new_worktime;
    end

    always @(posedge clkout,negedge rst)begin
        if(!rst)begin
            countdown_clean<=12'b0;
            countdown_storm<=8'b0;
        end
        else begin
            if(state[6]==1'b0)begin
                countdown_clean<=0;
                countdown_storm<=0;
            end

            if(recover_yet==1'b1)begin
                countdown_clean<=12'b0;
                countdown_storm<=8'b0;
            end
            else begin
                //suspend,countdown_storm,countdown_clean
                //counter time
                if(countdown_storm!=0)begin
                    if(state==`THREE || state==`EXIT_STROM)begin
                        if(countdown_storm[3:0]==4'b0000)begin
                            countdown_storm[3:0]<=4'b1001;
                            countdown_storm[7:4]<=countdown_storm[7:4]-4'b0001;
                        end
                        else countdown_storm[3:0]<=countdown_storm[3:0]-4'b0001;
                    end
                    else countdown_storm<=0;
                end
                if(countdown_clean!=0)begin
                    if(state==`CLEAN)begin
                        if(countdown_clean[3:0]==4'b0000)begin
                            countdown_clean[3:0]<=4'b1001;
                            if(countdown_clean[7:4]==4'b0000)begin
                                countdown_clean[7:4]<=4'b1001;
                                countdown_clean[11:8]<=countdown_clean[11:8]-4'b0001;
                            end
                            else countdown_clean[7:4]<=countdown_clean[7:4]-4'b0001;
                        end
                        else countdown_clean[3:0]<=countdown_clean[3:0]-4'b0001;
                    end
                    else countdown_clean<=0;
                end

                if(countdown_storm_yet==1'b1)begin
                    countdown_storm<=`COUNTDOWN60;
                end
                if(countdown_clean_yet==1'b1)begin
                    countdown_clean<=`COUNTDOWN180;
                end
            end
        end
    end

    //state machine
    always @(posedge clk,negedge rst) begin
        // Back to initial state
        if(!rst)begin
            clkout<=0;
            nxt_state<=`SHUTDOWN;
            switchtime<=24'b000000000000000000000101;
            remindtime<=24'b000100000000000000000000;
            buttom_effect<=3'b000;
            cnt_A <=re_cnt;
            cnt_S <=re_cnt;
            cnt_D <=re_cnt;
            cnt_wait <=re_cnt;
            cnt_clk<=0;
            storm_once<=1'b0;
            save_nowtime_yet<=1'b0;
            clean_worktime_yet<=1'b0;
            countdown_clean_yet<=1'b0;
            countdown_storm_yet<=1'b0;
            save_remindtime_yet<=1'b0;
            save_switchtime_yet<=1'b0;
            suspend<=1'b0;
            sign<={new_nowtime,`SHOW_STAN};
        end else if(state[6] && sign_pos_W && switch_P)begin
            clkout<=0;
            recover_yet<=1'b1;
            nxt_state<=`STANDBY;
            switchtime<=24'b000000000000000000000101;
            remindtime<=24'b000100000000000000000000;
            buttom_effect<=3'b000;
            save_nowtime_yet<=1'b0;
            clean_worktime_yet<=1'b0;
            countdown_clean_yet<=1'b0;
            countdown_storm_yet<=1'b0;
            save_remindtime_yet<=1'b0;
            save_switchtime_yet<=1'b0;
            suspend<=1'b0;
            sign<={new_nowtime,`SHOW_STAN};
        end else begin

            // Long push to turn pn/off
            if(sign_pos_X == 1'b1 && switch_P &&state[6]==1'b1) begin
                buttom_effect[2] <= 1'b1;
            end
            else if(sign_neg_X == 1'b1 || !switch_P || state[6]==1'b0) begin
                buttom_effect[2] <= 1'b0;
            end

            // buttom_S -> off/on
            if(buttom_effect[2]==1'b1)begin 
                cnt_S<=cnt_S+1;
                if(cnt_S>=300000000)begin // Modify time here
                    if(state[6]==1'b1)begin
                        nxt_state<=`SHUTDOWN;
                        clkout<=1'b0;
                    end
                    buttom_effect[2] <=1'b0;
                    cnt_S <=re_cnt;
                end
            end
            else begin
                if(cnt_S!=re_cnt) cnt_S<=re_cnt;
            end

            // Push A to count down
            if (buttom_effect[1] == 1'b1) begin
                cnt_A <= cnt_A + 1;
                if (cnt_A >= cnt_5s*100000000) begin
                    cnt_A <= 0;
                    buttom_effect[1] <= 1'b0;
                end
            end

            // Push D to count down
            if (buttom_effect[0] == 1'b1) begin
                cnt_wait <= cnt_wait + 1;
                if(cnt_wait == 100000000)begin
                    cnt_wait<=0;
                    cnt_D<=cnt_D+1;
                    sign <= sign-1;
                end
                if (cnt_D >= cnt_5s) begin  
                    cnt_D <= 0;
                    buttom_effect[0] <= 1'b0;
                end
            end

            //D->A, shutdown
            if(buttom_effect[0]==1'b1 && sign_pos_A && switch_P)begin
                buttom_effect[0]<=1'b0;
                nxt_state<=`SHUTDOWN;
                clkout<=1'b0;
                cnt_D<=re_cnt;
            end else if( state[6]==1'b1 && sign_pos_D && switch_P) begin //to complete
                    buttom_effect[0]<=1'b1;
                    cnt_D<=re_cnt; // Clear cnt_B
            end 

            if(cnt_clk==(period>>1)-1)begin
                clkout<=~clkout;
                cnt_clk<=0;
            end
            else begin
                cnt_clk<=cnt_clk+1;
            end

            //recover
            if(recover_yet==1'b1 && new_worktime==0 && countdown_clean==12'b0 && countdown_storm==8'b0)begin
                recover_yet<=1'b0;
            end

            //clean worktime
            if(clean_worktime_yet==1'b0 && (sign_pos_S && switch_P))begin
                clean_worktime_yet<=1'b1;
            end
            else if(clean_worktime_yet==1'b1 && new_worktime==0)begin
                clean_worktime_yet<=1'b0;
            end

            //save_nowtime
            else if(save_nowtime==new_nowtime && save_nowtime_yet==1'b1)begin
                save_nowtime_yet<=1'b0;
            end

            if(buttom_effect[0]==1'b1 && switch_P )begin
                sign<={new_nowtime,(cnt_5s-cnt_D)/10*16+(cnt_5s-cnt_D)%10};
            end
            else begin
                case(state)
                    `SHUTDOWN:begin
                        clkout<=1'b1;
                        storm_once<=1'b0;
                        suspend<=1'b0;
                        sign<={new_nowtime,`SHOW_STAN};
                        if(sign_pos_A && switch_P)begin
                            buttom_effect[1]<=1'b1;
                            cnt_A<=re_cnt;
                        end
                        else if(buttom_effect[1]==1'b1 && sign_pos_D && switch_P)begin
                            buttom_effect[1]<=1'b0;
                            nxt_state <= `STANDBY;
                            cnt_A<=re_cnt; // Clear cnt_A
                        end
                        else if(sign_pos_X && switch_P)begin
                            nxt_state<= `STANDBY;
                        end
                    end
                    `STANDBY:begin
                        suspend<=1'b0;
                        if(save_nowtime_yet==1'b1) sign<={save_nowtime,`SHOW_STAN};
                        else sign<={new_nowtime,`SHOW_STAN};
                        if(sign_pos_W && !switch_P) begin
                            nxt_state <= `MENU;
                        end else if(sign_pos_X && !switch_P) begin
                            nxt_state <= `SEARCH;
                        end
                    end
                    `MENU:begin
                        suspend<=1'b0;
                        sign<={new_nowtime,`SHOW_MENU};
                        suspend<=1'b0;
                        if(sign_pos_A && !switch_P)begin
                            nxt_state <= `ONE;
                        end else if(sign_pos_S && !switch_P)begin
                            nxt_state <= `TWO;
                        end else if(sign_pos_D && storm_once==1'b0 && !switch_P)begin
                            storm_once<=1'b1;
                            nxt_state <= `THREE;
                            countdown_storm_yet<=1'b1;
                        end else if(sign_pos_X && !switch_P)begin
                            nxt_state <= `CLEAN;
                            countdown_clean_yet<=1'b1;
                        end 
                    end
                    `ONE:begin
                        suspend<=1'b1;
                        sign<={new_nowtime,`SHOW_ONE};
                        if(sign_pos_S && !switch_P)begin
                            nxt_state <= `TWO;
                        end else if(sign_pos_W && !switch_P)begin
                            nxt_state <= `STANDBY;
                        end
                    end
                    `TWO:begin
                        suspend<=1'b1;
                        sign<={new_nowtime,`SHOW_TWO};
                        if(sign_pos_A && !switch_P)begin
                            nxt_state <= `ONE;
                        end else if(sign_pos_W && !switch_P)begin
                            nxt_state <= `STANDBY;
                        end
                    end
                    `THREE:begin
                        suspend<=1'b1;
                        if(countdown_storm_yet==1'b1)begin
                            if(countdown_storm>8'b00000000)begin
                                sign<={16'b0,countdown_storm,`SHOW_THREE};
                                countdown_storm_yet<=1'b0;
                            end
                            else sign<={24'b01100000,`SHOW_THREE};
                        end
                        else begin
                            sign<={16'b0,countdown_storm,`SHOW_THREE}; 
                            if(countdown_storm==8'b00000000)begin
                            nxt_state<=`TWO;
                        end
                        end
                        if(sign_pos_W && !switch_P)begin
                            nxt_state<=`EXIT_STROM;
                            clkout<=1'b0;
                            countdown_storm_yet<=1'b1;
                        end
                    end
                    `EXIT_STROM:begin
                        suspend<=1'b1;
                        if(countdown_storm_yet==1'b1)begin
                            if(countdown_storm>8'b00000000 && clkout==1'b1 && cnt_clk>1)begin
                                sign<={16'b0,countdown_storm,`SHOW_EXIT_STORM};
                                countdown_storm_yet<=1'b0;
                            end
                            else sign<={24'b01100000,`SHOW_EXIT_STORM};
                        end
                        else begin 
                            sign<={16'b0,countdown_storm,`SHOW_EXIT_STORM};
                            if(countdown_storm==8'b00000000)begin
                            nxt_state<=`STANDBY;
                        end
                        end
                    end
                    `CLEAN:begin
                        suspend<=1'b0;
                        if(countdown_clean_yet==1'b1)begin
                            if(countdown_clean>12'b000000000000)begin
                                sign<={12'b0,countdown_clean,`SHOW_CLEAN};
                                countdown_clean_yet<=1'b0;
                            end
                            else sign<={24'b000110000000,`SHOW_CLEAN};
                        end
                        else begin 
                            sign<={12'b0,countdown_clean,`SHOW_CLEAN};
                            if(countdown_clean==12'b000000000000)begin
                                nxt_state<=`STANDBY;
                                clean_worktime_yet<=1'b1;
                            end
                        end
                    end
                    `SEARCH:begin
                        suspend<=1'b0;
                        sign<={new_nowtime,`SHOW_SEARCH};
                        if(sign_pos_A && !switch_P)begin
                            nxt_state <= `SEARCH_NOWTIME;
                        end else if(sign_pos_X && !switch_P)begin
                            nxt_state <= `SEARCH_WORKTIME;
                        end else if(sign_pos_S && !switch_P)begin
                            nxt_state <= `SEARCH_SWITCH_TIME;
                        end else if(sign_pos_D && !switch_P)begin
                            nxt_state <= `SEARCH_REMINDTIME;
                        end else if(sign_pos_W && !switch_P)begin
                            nxt_state <= `STANDBY;
                        end
                    end
                    `SEARCH_NOWTIME:begin
                        suspend<=1'b0;
                        if(save_nowtime_yet==1'b0)save_nowtime<=new_nowtime;
                        sign<={save_nowtime,`SHOW_NOW};
                        if(sign_pos_W && !switch_P)
                            nxt_state <= `SEARCH;
                        else if(sign_pos_X && !switch_P)begin
                            nxt_state <= `SET_NOW_HOUR;
                        end
                    end
                    `SEARCH_WORKTIME:begin
                        suspend<=1'b0;
                        sign<={new_worktime,`SHOW_WORKTIME};
                        if(sign_pos_W && !switch_P)
                            nxt_state <= `SEARCH;
                    end
                    `SEARCH_SWITCH_TIME:begin
                        suspend<=1'b0;
                        if(save_switchtime_yet==1'b0)save_switchtime<=switchtime;
                        else begin
                            switchtime<=save_switchtime;
                            save_switchtime_yet<=1'b0;
                        end
                        sign<={save_switchtime,`SHOW_SWITCH};
                        if(sign_pos_W && !switch_P)
                            nxt_state <= `SEARCH;
                        else if(sign_pos_X && !switch_P)begin
                            nxt_state <= `SET_SWI_SEC;
                        end
                    end
                    `SEARCH_REMINDTIME:begin
                        suspend<=1'b0;
                        if(save_remindtime_yet==1'b0)save_remindtime<=remindtime;
                        else begin
                            remindtime<=save_remindtime;
                            save_remindtime_yet<=1'b0;
                        end
                        sign<={save_remindtime,`SHOW_REMIND};
                        if(sign_pos_W && !switch_P)
                            nxt_state <= `SEARCH;
                        else if(sign_pos_X && !switch_P)
                            nxt_state <= `SET_REMIND_HOUR;
                    end
                    `SET_NOW_HOUR:begin
                        suspend<=1'b0;
                        sign<={save_nowtime,`SHOW_SET_H};
                        if(sign_pos_A && !switch_P)begin
                            if(save_nowtime[23:16]==8'b00100011) begin
                                save_nowtime[23:16] <= 8'b00000000;
                            end
                            else if(save_nowtime[19:16]==4'b1001) begin
                                save_nowtime[19:16] <= 4'b0000;
                                save_nowtime[23:20] <= save_nowtime[23:20]+1;
                            end
                            else save_nowtime[19:16] <= save_nowtime[19:16]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_nowtime[23:16]==8'b00000000) begin
                                save_nowtime[23:16] <= 8'b00100011;
                            end
                            else if(save_nowtime[19:16]==4'b0000) begin
                                save_nowtime[19:16] <= 4'b1001;
                                save_nowtime[23:20] <= save_nowtime[23:20]-1;
                            end
                            else save_nowtime[19:16] <= save_nowtime[19:16]-1;
                        end
                        else if (sign_pos_S && !switch_P)
                            nxt_state <= `SET_NOW_MIN;
                    end
                    `SET_NOW_MIN:begin
                        suspend<=1'b0;
                        sign<={save_nowtime,`SHOW_SET_M};
                        if(sign_pos_A && !switch_P)begin
                            if(save_nowtime[15:8]==8'b01011001) begin
                                save_nowtime[15:8] <= 8'b00000000;
                            end
                            else if(save_nowtime[11:8]==4'b1001) begin
                                save_nowtime[11:8] <= 4'b0000;
                                save_nowtime[15:12] <= save_nowtime[15:12]+1;
                            end
                            else save_nowtime[11:8] <= save_nowtime[11:8]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_nowtime[15:8]==8'b00000000) begin
                                save_nowtime[15:8] <= 8'b01011001;
                            end
                            else if(save_nowtime[11:8]==4'b0000) begin
                                save_nowtime[11:8] <= 4'b1001;
                                save_nowtime[15:12] <= save_nowtime[15:12]-1;
                            end
                            else save_nowtime[11:8] <= save_nowtime[11:8]-1;
                        end
                        else if (sign_pos_S && !switch_P)
                            nxt_state <= `SET_NOW_SEC;
                    end
                    `SET_NOW_SEC:begin
                        suspend<=1'b0;
                        sign<={save_nowtime,`SHOW_SET_S};
                        if(sign_pos_A && !switch_P)begin
                            if(save_nowtime[7:0]==8'b01011001) begin
                                save_nowtime[7:0] <= 8'b00000000;
                            end
                            else if(save_nowtime[3:0]==4'b1001) begin
                                save_nowtime[3:0] <= 4'b0000;
                                save_nowtime[7:4] <= save_nowtime[7:4]+1;
                            end
                            else save_nowtime[3:0] <= save_nowtime[3:0]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_nowtime[7:0]==8'b00000000) begin
                                save_nowtime[7:0] <= 8'b01011001;
                            end
                            else if(save_nowtime[3:0]==4'b0000) begin
                                save_nowtime[3:0] <= 4'b1001;
                                save_nowtime[7:4] <= save_nowtime[7:4]-1;
                            end
                            else save_nowtime[3:0] <= save_nowtime[3:0]-1;
                        end
                        else if (sign_pos_S && !switch_P)begin
                            nxt_state <= `STANDBY;
                            save_nowtime_yet<=1'b1;
                        end
                    end
                    `SET_SWI_HOUR:begin
                        suspend<=1'b0;
                        sign<={save_switchtime,`SHOW_SET_H};
                        if(sign_pos_A && !switch_P)begin
                            if(save_switchtime[23:16]==8'b00100011) begin
                                save_switchtime[23:16] <= 8'b00000000;
                            end
                            else if(save_switchtime[19:16]==4'b1001) begin
                                save_switchtime[19:16] <= 4'b0000;
                                save_switchtime[23:20] <= save_switchtime[23:20]+1;
                            end
                            else save_switchtime[19:16] <= save_switchtime[19:16]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_switchtime[23:16]==8'b00000000) begin
                                save_switchtime[23:16] <= 8'b00100011;
                            end
                            else if(save_switchtime[19:16]==4'b0000) begin
                                save_switchtime[19:16] <= 4'b1001;
                                save_switchtime[23:20] <= save_switchtime[23:20]-1;
                            end
                            else save_switchtime[19:16] <= save_switchtime[19:16]-1;
                        end
                        else if (sign_pos_S && !switch_P)
                            nxt_state <= `SET_SWI_MIN;
                    end
                    `SET_SWI_MIN:begin
                        suspend<=1'b0;
                        sign<={save_switchtime,`SHOW_SET_M};
                        if(sign_pos_A && !switch_P)begin
                            if(save_switchtime[15:8]==8'b01011001) begin
                                save_switchtime[15:8] <= 8'b00000000;
                            end
                            else if(save_switchtime[11:8]==4'b1001) begin
                                save_switchtime[11:8] <= 4'b0000;
                                save_switchtime[15:12] <= save_switchtime[15:12]+1;
                            end
                            else save_switchtime[11:8] <= save_switchtime[11:8]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_switchtime[15:8]==8'b00000000) begin
                                save_switchtime[15:8] <= 8'b01011001;
                            end
                            else if(save_switchtime[11:8]==4'b0000) begin
                                save_switchtime[11:8] <= 4'b1001;
                                save_switchtime[15:12] <= save_switchtime[15:12]-1;
                            end
                            else save_switchtime[11:8] <= save_switchtime[11:8]-1;
                        end
                        else if (sign_pos_S && !switch_P)
                            nxt_state <= `SET_SWI_SEC;
                    end
                    `SET_SWI_SEC:begin
                        suspend<=1'b0;
                        sign<={save_switchtime,`SHOW_SET_S};
                        if(sign_pos_A && !switch_P)begin
                            if(save_switchtime[7:0]==8'b01011001) begin
                                save_switchtime[7:0] <= 8'b00000000;
                            end
                            else if(save_switchtime[3:0]==4'b1001) begin
                                save_switchtime[3:0] <= 4'b0000;
                                save_switchtime[7:4] <= save_switchtime[7:4]+1;
                            end
                            else save_switchtime[3:0] <= save_switchtime[3:0]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_switchtime[7:0]==8'b00000000) begin
                                save_switchtime[7:0] <= 8'b01011001;
                            end
                            else if(save_switchtime[3:0]==4'b0000) begin
                                save_switchtime[3:0] <= 4'b1001;
                                save_switchtime[7:4] <= save_switchtime[7:4]-1;
                            end
                            else save_switchtime[3:0] <= save_switchtime[3:0]-1;
                        end
                        else if (sign_pos_S && !switch_P)begin
                            if(save_switchtime==0)begin
                                nxt_state<=`ERROR;
                            end
                            else begin 
                                save_switchtime_yet<=1'b1;
                                nxt_state <= `SEARCH_SWITCH_TIME;
                            end
                        end
                    end
                    `SET_REMIND_HOUR:begin
                        suspend<=1'b0;
                        sign<={save_remindtime,`SHOW_SET_H};
                        if(sign_pos_A && !switch_P)begin
                            if(save_remindtime[23:16] == 8'b00100011) begin  //23+1=0
                                save_remindtime[23:16] <= 8'b00000000;
                            end
                            else if(save_remindtime[19:16]==4'b1001) begin
                                save_remindtime[19:16] <= 4'b0000;
                                save_remindtime[23:20] <= save_remindtime[23:20]+1;
                            end
                            else save_remindtime[19:16] <= save_remindtime[19:16]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_remindtime[23:16] == 8'b00000000) begin
                                save_remindtime[23:16] <= 8'b00100011;
                            end
                            else if(save_remindtime[19:16]==4'b0000) begin
                                save_remindtime[19:16] <= 4'b1001;
                                save_remindtime[23:20] <= save_remindtime[23:20]-1;
                            end
                            else save_remindtime[19:16] <= save_remindtime[19:16]-1;
                        end
                        else if (sign_pos_S && !switch_P)
                            nxt_state <= `SET_REMIND_MIN;
                    end
                    `SET_REMIND_MIN:begin
                        suspend<=1'b0;
                        sign<={save_remindtime,`SHOW_SET_M};
                        if(sign_pos_A && !switch_P)begin
                            if(save_remindtime[15:8] == 8'b01011001) begin
                                save_remindtime[15:8] <= 8'b00000000;
                            end
                            else if(save_remindtime[11:8]==4'b1001) begin
                                save_remindtime[11:8] <= 4'b0000;
                                save_remindtime[15:12] <= save_remindtime[15:12]+1;
                            end
                            else save_remindtime[11:8] <= save_remindtime[11:8]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_remindtime[15:8] == 8'b00000000) begin
                                save_remindtime[15:8] <= 8'b01011001;
                            end
                            else if(save_remindtime[11:8]==4'b0000) begin
                                save_remindtime[11:8] <= 4'b1001;
                                save_remindtime[15:12] <= save_remindtime[15:12]-1;
                            end
                            else save_remindtime[11:8] <= save_remindtime[11:8]-1;
                        end
                        else if (sign_pos_S && !switch_P)
                            nxt_state <= `SET_REMIND_SEC;
                    end
                    `SET_REMIND_SEC:begin
                        suspend<=1'b0;
                        sign<={save_remindtime,`SHOW_SET_S};
                        if(sign_pos_A && !switch_P)begin
                            if(save_remindtime[7:0] == 8'b01011001) begin
                                save_remindtime[7:0] <= 8'b00000000;
                            end
                            else if(save_remindtime[3:0]==4'b1001) begin
                                save_remindtime[3:0] <= 4'b0000;
                                save_remindtime[7:4] <= save_remindtime[7:4]+1;
                            end
                            else save_remindtime[3:0] <= save_remindtime[3:0]+1;
                        end
                        else if(sign_pos_D && !switch_P)begin
                            if(save_remindtime[7:0] == 8'b00000000) begin
                                save_remindtime[7:0] <= 8'b01011001;
                            end
                            else if(save_remindtime[3:0]==4'b0000) begin
                                save_remindtime[3:0] <= 4'b1001;
                                save_remindtime[7:4] <= save_remindtime[7:4]-1;
                            end
                            else save_remindtime[3:0] <= save_remindtime[3:0]-1;
                        end
                        else if (sign_pos_S && !switch_P)begin
                            if(save_remindtime==0)begin
                                nxt_state<=`ERROR;
                            end
                            else begin 
                                save_remindtime_yet<=1'b1;
                                nxt_state <= `SEARCH_REMINDTIME;
                            end
                        end
                    end
                    `ERROR:begin
                        suspend<=1'b0;
                        cnt_error<=cnt_error+1;
                        sign<={new_nowtime,`SHOW_ERROR};
                        if(cnt_error>=200000000)begin
                            nxt_state<=`STANDBY;
                            cnt_error<=0;
                        end
                    end
                    default:begin
                        suspend<=1'b0;
                        sign<={new_nowtime,`SHOW_STAN};
                    end
                endcase
            end
        end
    end
endmodule
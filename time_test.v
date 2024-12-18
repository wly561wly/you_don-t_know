`timescale 1ns / 1ps

//这个模块用来接受2个3bit one-hot信号，分别代表剪刀石头布
//然后使用一个按键，表示展示，按下后会在LED上显示两个人的选择，以及获胜结果
//使用三个状态，INIT,CHOICE,DISPLAY
module time_test(
    input rst,
    input clk,
    input button_A,
    input button_D,
    input button_S,
    input button_W,
    input button_X,
    input button_rst,
    output [7:0]seg_74,
    output [7:0]seg_30,
    output [7:0]tub_sel,
    output reg[4:0]button,
    output reg[2:0]light
);
    reg [1:0]state,nxt_state;
    wire btn_pos_A,btn_pos_D,btn_pos_S,btn_pos_W,btn_pos_X;
    reg clkout;
    reg [31:0]cnt_clk,cnt_s;
    parameter period=8'd50000000,counter60=24'b00000000000001100000;
    parameter INIT=2'b00,ON=2'b01,COUNTER=2'b10;

    reg [31:0]sign;
    reg [23:0]nowtime,countertime;
    //按键消抖
    Edge_detection edge_detection(
        .button_A(button_A),
        .button_D(button_D),
        .button_S(button_S),
        .button_W(button_W),
        .button_X(button_X),
        .button_rst(rst),
        .clk(clk),
        .btn_pos_A(btn_pos_A),
        .btn_pos_D(btn_pos_D),
        .btn_pos_S(btn_pos_S),
        .btn_pos_W(btn_pos_W),
        .btn_pos_X(btn_pos_X)
    );

    always @(posedge clk,negedge rst) begin
        if(~rst) begin
            clkout<=0;
            cnt_clk<=0;
        end else begin
            cnt_clk<=cnt_clk+1;;
            if(cnt_clk==period) begin
                cnt_clk<=0;
                clkout<=~clkout;
            end
        end
    end

    always @(posedge clkout,negedge rst) begin
        if(~rst) begin
            cnt_s<=0;
            button<=0;
        end else begin
            cnt_s[3:0]<=cnt_s[3:0]+1;
            if(cnt_s[3:0]==4'b1010)cnt_s[7:4]<=cnt_s[7:4]+1;
            if(cnt_s[7:4]==4'b0100)cnt_s[7:4]<=0;
            //0,2,4,6 显示cnt_s[3:0]
            //1,3,5,7 显示cnt_s[7:4]
            sign[31:28]<=cnt_s[7:4];
            sign[27:24]<=cnt_s[3:0];
            sign[23:20]<=cnt_s[7:4];
            sign[19:16]<=cnt_s[3:0];
            sign[15:12]<=cnt_s[7:4];
            sign[11:8]<=cnt_s[3:0];
            sign[7:4]<=cnt_s[7:4];
            sign[3:0]<=cnt_s[3:0];
            if(btn_pos_A)begin
                button<=5'b00001;
            end
            else if(btn_pos_D)begin
                button<=5'b00010;
            end
            else if(btn_pos_S)begin
                button<=5'b00100;
            end
            else if(btn_pos_W)begin
                button<=5'b01000;
            end
            else if(btn_pos_X)begin
                button<=5'b10000;
            end
        end
    end

    print_output print(
        .en(1'b1),
        .sign7(sign[31:28]),
        .sign6(sign[27:24]),
        .sign5(sign[23:20]),
        .sign4(sign[19:16]),
        .sign3(sign[15:12]),
        .sign2(sign[11:8]),
        .sign1(sign[7:4]),
        .sign0(sign[3:0]),
        .rst(rst),
        .clk(clk),
        .seg_74(seg_74),
        .seg_30(seg_30),
        .tub_sel(tub_sel)
    );

endmodule

module Edge_detection(
    input button_A,
    input button_D,
    input button_S,
    input button_W,
    input button_X,
    input button_rst,
    input clk,             // 输入时钟（假设为 100MHz）
    output btn_pos_A,
    output btn_pos_D,
    output btn_pos_S,
    output btn_pos_W,
    output btn_pos_X

);
    // 分频器参数
    reg [16:0] counter;      // 17位计数器，最大值为 100,000（适应 100MHz 输入时钟）
    reg clk_out;             // 分频后的时钟，1kHz
    parameter DIVISOR = 130000;  // 分频系数：100MHz 到 1kHz

    always @(posedge clk or posedge button_rst) begin
        if (!button_rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == DIVISOR - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;  // 每次计数到 DIVISOR 时反转输出时钟
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // 按键消抖寄存器
    reg [2:0] trig_A,trig_D,trig_S,trig_W,trig_X;

    always @(posedge clk_out or negedge button_rst) begin
        if(!button_rst) begin
            trig_A<=3'b000;
            trig_D<=3'b000;
            trig_S<=3'b000;
            trig_W<=3'b000;
            trig_X<=3'b000;
        end else begin
            trig_A <= {trig_A[1:0],button_A};
            trig_D <= {trig_D[1:0],button_D};
            trig_S <= {trig_S[1:0],button_S};
            trig_W <= {trig_W[1:0],button_W};
            trig_X <= {trig_X[1:0],button_X};
        end
    end

    // 输出按键状态
    assign btn_pos_A = (~trig_A[2])& trig_A[1];
    assign btn_pos_D = (~trig_D[2])& trig_D[1];
    assign btn_pos_S = (~trig_S[2])& trig_S[1];
    assign btn_pos_W = (~trig_W[2])& trig_W[1];
    assign btn_pos_X = (~trig_X[2])& trig_X[1];

endmodule

module print_output(
    input en,
    input [3:0] sign7,
    input [3:0] sign6,
    input [3:0] sign5,
    input [3:0] sign4,
    input [3:0] sign3,
    input [3:0] sign2,
    input [3:0] sign1,
    input [3:0] sign0,
    input rst,
    input clk,
    // output reg[3:0] chip_74,
    output reg[7:0] seg_74,
    // output reg[3:0] chip_30,
    output reg[7:0] seg_30,
    output reg [7:0] tub_sel// Use 8-digit instead of two 4_digit
);

    reg [24:0] clk_div; 

    parameter [7:0]digit0=8'b11111100, digit1=8'b01100000, digit2=8'b11011010, digit3=8'b11110010, digit4=8'b01100110, digit5=8'b10110110, digit6=8'b10111110, digit7=8'b11100000;
    parameter [7:0]digit8=8'b11111110, digit9=8'b11110110, digitA=8'b11101110, digitB=8'b00111110, digitC=8'b10011100, digitD=8'b01111010, digitE=8'b10011110, digitF=8'b10001110;

    // Set temp varaiables
    reg [7:0]temp7,temp6,temp5,temp4,temp3,temp2,temp1,temp0;
    
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            tub_sel <= 8'b10000000;  // Initialize with the rightmost light on
            clk_div <= 25'b0;
        end else begin
            // Set the frequency divider clk_div
            clk_div <= clk_div + 1;
            
            // Switch tub_sel while a period finished
            if (clk_div == 25'd25000) begin  // Set 1000Hz here(proper)//25000->25 help simulation
                clk_div <= 25'b0; // Reset
                tub_sel <= {tub_sel[6:0], tub_sel[7]};  // Implement digit-move operation here
            end
            case(sign0)
                4'b0000: temp0 <= digit0;
                4'b0001: temp0 <= digit1;
                4'b0010: temp0 <= digit2;
                4'b0011: temp0 <= digit3;
                4'b0100: temp0 <= digit4;
                4'b0101: temp0 <= digit5;
                4'b0110: temp0 <= digit6;
                4'b0111: temp0 <= digit7;
                4'b1000: temp0 <= digit8;
                4'b1001: temp0 <= digit9;
                4'b1010: temp0 <= digitA;
                4'b1011: temp0 <= digitB;
                4'b1100: temp0 <= digitC;
                4'b1101: temp0 <= digitD;
                4'b1110: temp0 <= digitE;
                4'b1111: temp0 <= digitF;
            endcase

            case(sign1)
                4'b0000: temp1 <= digit0;
                4'b0001: temp1 <= digit1;
                4'b0010: temp1 <= digit2;
                4'b0011: temp1 <= digit3;
                4'b0100: temp1 <= digit4;
                4'b0101: temp1 <= digit5;
                4'b0110: temp1 <= digit6;
                4'b0111: temp1 <= digit7;
                4'b1000: temp1 <= digit8;
                4'b1001: temp1 <= digit9;
                4'b1010: temp1 <= digitA;
                4'b1011: temp1 <= digitB;
                4'b1100: temp1 <= digitC;
                4'b1101: temp1 <= digitD;
                4'b1110: temp1 <= digitE;
                4'b1111: temp1 <= digitF;
            endcase

            case(sign2)
                4'b0000: temp2 <= digit0;
                4'b0001: temp2 <= digit1;
                4'b0010: temp2 <= digit2;
                4'b0011: temp2 <= digit3;
                4'b0100: temp2 <= digit4;
                4'b0101: temp2 <= digit5;
                4'b0110: temp2 <= digit6;
                4'b0111: temp2 <= digit7;
                4'b1000: temp2 <= digit8;
                4'b1001: temp2 <= digit9;
                4'b1010: temp2 <= digitA;
                4'b1011: temp2 <= digitB;
                4'b1100: temp2 <= digitC;
                4'b1101: temp2 <= digitD;
                4'b1110: temp2 <= digitE;
                4'b1111: temp2 <= digitF;
            endcase

            case(sign3)
                4'b0000: temp3 <= digit0;
                4'b0001: temp3 <= digit1;
                4'b0010: temp3 <= digit2;
                4'b0011: temp3 <= digit3;
                4'b0100: temp3 <= digit4;
                4'b0101: temp3 <= digit5;
                4'b0110: temp3 <= digit6;
                4'b0111: temp3 <= digit7;
                4'b1000: temp3 <= digit8;
                4'b1001: temp3 <= digit9;
                4'b1010: temp3 <= digitA;
                4'b1011: temp3 <= digitB;
                4'b1100: temp3 <= digitC;
                4'b1101: temp3 <= digitD;
                4'b1110: temp3 <= digitE;
                4'b1111: temp3 <= digitF;
            endcase

            case(sign4)
                4'b0000: temp4 <= digit0;
                4'b0001: temp4 <= digit1;
                4'b0010: temp4 <= digit2;
                4'b0011: temp4 <= digit3;
                4'b0100: temp4 <= digit4;
                4'b0101: temp4 <= digit5;
                4'b0110: temp4 <= digit6;
                4'b0111: temp4 <= digit7;
                4'b1000: temp4 <= digit8;
                4'b1001: temp4 <= digit9;
                4'b1010: temp4 <= digitA;
                4'b1011: temp4 <= digitB;
                4'b1100: temp4 <= digitC;
                4'b1101: temp4 <= digitD;
                4'b1110: temp4 <= digitE;
                4'b1111: temp4 <= digitF;
            endcase

            case(sign5)
                4'b0000: temp5 <= digit0;
                4'b0001: temp5 <= digit1;
                4'b0010: temp5 <= digit2;
                4'b0011: temp5 <= digit3;
                4'b0100: temp5 <= digit4;
                4'b0101: temp5 <= digit5;
                4'b0110: temp5 <= digit6;
                4'b0111: temp5 <= digit7;
                4'b1000: temp5 <= digit8;
                4'b1001: temp5 <= digit9;
                4'b1010: temp5 <= digitA;
                4'b1011: temp5 <= digitB;
                4'b1100: temp5 <= digitC;
                4'b1101: temp5 <= digitD;
                4'b1110: temp5 <= digitE;
                4'b1111: temp5 <= digitF;
            endcase

            case(sign6)
                4'b0000: temp6 <= digit0;
                4'b0001: temp6 <= digit1;
                4'b0010: temp6 <= digit2;
                4'b0011: temp6 <= digit3;
                4'b0100: temp6 <= digit4;
                4'b0101: temp6 <= digit5;
                4'b0110: temp6 <= digit6;
                4'b0111: temp6 <= digit7;
                4'b1000: temp6 <= digit8;
                4'b1001: temp6 <= digit9;
                4'b1010: temp6 <= digitA;
                4'b1011: temp6 <= digitB;
                4'b1100: temp6 <= digitC;
                4'b1101: temp6 <= digitD;
                4'b1110: temp6 <= digitE;
                4'b1111: temp6 <= digitF;
            endcase

            case(sign7)
                4'b0000: temp7 <= digit0;
                4'b0001: temp7 <= digit1;
                4'b0010: temp7 <= digit2;
                4'b0011: temp7 <= digit3;
                4'b0100: temp7 <= digit4;
                4'b0101: temp7 <= digit5;
                4'b0110: temp7 <= digit6;
                4'b0111: temp7 <= digit7;
                4'b1000: temp7 <= digit8;
                4'b1001: temp7 <= digit9;
                4'b1010: temp7 <= digitA;
                4'b1011: temp7 <= digitB;
                4'b1100: temp7 <= digitC;
                4'b1101: temp7 <= digitD;
                4'b1110: temp7 <= digitE;
                4'b1111: temp7 <= digitF;
            endcase
        end
    end



    always @(*)begin // Use * here
        case (tub_sel)
            8'b10000000: seg_74 = temp7; // 显示�?1个数码管的数�?
            8'b01000000: seg_74 = temp6; // 显示�?2个数码管的数�?
            8'b00100000: seg_74 = temp5; // 显示�?3个数码管的数�?
            8'b00010000: seg_74 = temp4; // 显示�?4个数码管的数�?
            8'b00001000: seg_30 = temp3; // 显示�?5个数码管的数�?
            8'b00000100: seg_30 = temp2; // 显示�?6个数码管的数�?
            8'b00000010: seg_30 = temp1; // 显示�?7个数码管的数�?
            8'b00000001: seg_30 = temp0; // 显示�?8个数码管的数�?
            default: begin
                seg_74 = 8'b00000000; // 默认关闭�?有数码管
                seg_30 = 8'b00000000;
            end
        endcase
    end
endmodule
`timescale 1ns / 1ps

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
    output reg[7:0] seg_74,
    output reg[7:0] seg_30,
    output reg [7:0] tub_sel
);

    reg [24:0] clk_div; 

    parameter [7:0]digit0=8'b11111100, digit1=8'b01100000, digit2=8'b11011010, digit3=8'b11110010, digit4=8'b01100110, digit5=8'b10110110, digit6=8'b10111110, digit7=8'b11100000;
    parameter [7:0]digit8=8'b11111110, digit9=8'b11110110, digitA=8'b11101110, digitB=8'b00111110, digitC=8'b10011100, digitD=8'b01111010, digitE=8'b10011110, digitF=8'b10001110;
    
    //parameter [3:0]sign7=4'b0111,sign6=4'b0110,sign5=4'b0101,sign4=4'b0100,sign3=4'b0011,sign2=4'b0010,sign1=4'b0001,sign0=4'b0000;

    // Set temp varaiables
    reg [7:0]temp7,temp6,temp5,temp4,temp3,temp2,temp1,temp0;
    
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            tub_sel <= 8'b00000001;  // Initialize with the rightmost light on
            clk_div <= 25'b0;
        end else begin
            // Set the frequency divider clk_div
            clk_div <= clk_div + 1;
            
            // Switch tub_sel while a period finished
            if (clk_div == 25'd25000) begin  // Set 1000Hz here(proper)//25000->25 help simulation
                clk_div <= 25'b0; // Reset
                tub_sel <= {tub_sel[6:0], tub_sel[7]};  // Implement digit-move operation here
            end
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
    endcase
end

    always @(*)begin // Use * here
        case (tub_sel)
            8'b10000000: seg_74 = temp7; // 显示??1个数码管的数??
            8'b01000000: seg_74 = temp6; // 显示??2个数码管的数??
            8'b00100000: seg_74 = temp5; // 显示??3个数码管的数??
            8'b00010000: seg_74 = temp4; // 显示??4个数码管的数??
            8'b00001000: seg_30 = temp3; // 显示??5个数码管的数??
            8'b00000100: seg_30 = temp2; // 显示??6个数码管的数??
            8'b00000010: seg_30 = temp1; // 显示??7个数码管的数??
            8'b00000001: seg_30 = temp0; // 显示??8个数码管的数??
            default: begin
                seg_74 = 8'b00000000; // 默认关闭??有数码管
                seg_30 = 8'b00000000;
            end
        endcase
    end
endmodule

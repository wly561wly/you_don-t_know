module SevenSegmentDisplay(
    input clk,           // 时钟信号
    input rst,           // 复位信号
    input [6:0] digit0, digit1, digit2, digit3, digit4, digit5, digit6, digit7, //八个输入数字
    output reg [7:0] tub_sel, // 片选信号，控制哪一个数码管亮
    output reg [6:0] tub_control1, tub_control2 // 控制段选信号
);

    // 数码管显示的数字（1~8）
    // reg [7:0] digits [7:0];  // 存储1~8的数码管显示值
    // initial begin
    //     digits[0] = 8'b11111100; // 1
    //     digits[1] = 8'b01100000; // 2
    //     digits[2] = 8'b11011010; // 3
    //     digits[3] = 8'b11110010; // 4
    //     digits[4] = 8'b01100110; // 5
    //     digits[5] = 8'b10110110; // 6
    //     digits[6] = 8'b10111110; // 7
    //     digits[7] = 8'b11111110; // 8
    // end

    // 控制选择的数码管的信号
    reg [1:0] counter; // 用于控制循环选择
    reg [24:0] clk_div; // 时钟分频器，用于控制频率

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            tub_sel <= 8'b00000001;  // 初始显示第一个数码管
            counter <= 2'b00;
            clk_div <= 25'b0;
        end else begin
            // 时钟分频，控制 tub_sel 的变化频率
            clk_div <= clk_div + 1;
            
            // 每当 clk_div 达到一定值时，切换 tub_sel
            if (clk_div == 25'd25000) begin  // 假设分频频率为1000Hz
                clk_div <= 25'b0; // 复位分频器
                tub_sel <= {tub_sel[6:0], tub_sel[7]};  // 循环滚动片选信号
            end
        end
    end

    // 控制 segment 显示的数字
    always @(*) begin
        case (tub_sel)
            8'b00000001: tub_control1 = digit0; // 显示第1个数码管的数字
            8'b00000010: tub_control1 = digit1; // 显示第2个数码管的数字
            8'b00000100: tub_control1 = digit2; // 显示第3个数码管的数字
            8'b00001000: tub_control1 = digit3; // 显示第4个数码管的数字
            8'b00010000: tub_control2 = digit4; // 显示第5个数码管的数字
            8'b00100000: tub_control2 = digit5; // 显示第6个数码管的数字
            8'b01000000: tub_control2 = digit6; // 显示第7个数码管的数字
            8'b10000000: tub_control2 = digit7; // 显示第8个数码管的数字
            default: begin
                tub_control1 = 7'b0000000; // 默认关闭所有数码管
                tub_control2 = 7'b0000000;
            end
        endcase
    end

endmodule





module variable_duty_cycle_wave (
    input clk,                // 100MHz 时钟信号
    input rst,                // 复位信号
    input [6:0] state,       // 输入的状态信
    output reg wave_out,      // 输出的变频方波信
    output wire en            // 使能信号（保持为高电平）
);

    assign en = 1'b1; // 始终使能

    reg wave_out_en;

    // 时钟分频参数
    reg [15:0] clk_div_counter; // 分频计数??
    reg clk_new;                // 分频后的时钟信号

    // 占空比和控制参数
    reg [6:0] counter;          // 计数器，用于生成状???周??
    reg [7:0] duty_cycle;       // 占空比（5% ?? 95%），范围 5-95
    reg direction;              // 方向控制??0 表示递减??1 表示递增
    reg [15:0] count;           // 分频器计??

    // 状???机控制
    reg [6:0] pre_state;        // 上一个状??
    reg [44:0] timer_counter;   // 定时器，控制声音输出持续时间

    // 参数
    localparam MAX_CYCLES = 50; // 每个状???的周期数（50个分频时钟周期）
    localparam MAX_DUTY = 98;   // ??大占空比??95%??
    localparam MIN_DUTY = 47;   // ??小占空比??40%??
    localparam STEP = 1;        // 每个周期递增/递减的步长（95% - 40%??/50 ?? 1

    // frequency generator
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            clk_div_counter <= 0;
            clk_new <= 0;
        end else begin
            if (clk_div_counter == count) begin
                clk_div_counter <= 0;
                clk_new <= ~clk_new; // 切换时钟频率
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            pre_state <= 7'b0;  // 初始状???为 0
            timer_counter <= 0; // 定时器清??
            wave_out_en <= 0;      // 初始不输出声??
        end else if (state != pre_state) begin
            pre_state <= state;          // 更新 pre_state
            case (state)
                7'b0000000, 7'b1000000: begin
                    count <= 200;    // 设置不同的分频周??
                    timer_counter <= 45'd150000000;  // 设置 1.5秒（200MHz 时钟下，大约 2秒的计时周期??200000000
                end
                7'b1010000, 7'b1100000, 7'b1100100, 7'b1101000, 7'b1101100: begin
                    count <= 250;
                    timer_counter <= 45'd150000000;  // 设置 1.5秒（200MHz 时钟下，大约 2秒的计时周期??200000000
                end
                7'b1010100, 7'b1011000, 7'b1011100: begin
                    count <= 300;
                    timer_counter <= 45'd150000000;  // 设置 1.5秒（200MHz 时钟下，大约 2秒的计时周期??200000000
                end
                7'b1111001, 7'b1111010, 7'b1111011, 7'b1111101, 7'b1111110, 7'b1111111: begin
                    count <= 150;
                    timer_counter <= 45'd150000000;  // 设置 1.5秒（200MHz 时钟下，大约 2秒的计时周期??200000000
                end
                7'b1011101:begin
                    count <= 250;
                    timer_counter <= 45'd6000000000;
                   end
                7'b1010010:begin
                    count <= 250;
                    timer_counter <= 45'd18000000000;
                end
                default: begin
                    count <= 100;
                    timer_counter <= 45'd150000000;  // 设置 1.5秒（200MHz 时钟下，大约 2秒的计时周期??200000000
                end
            endcase
            // 启动声音输出
            wave_out_en <= 1;
        end else if (timer_counter > 0) begin
            // 计时器减少，保持输出声音
            timer_counter <= timer_counter - 1;
            wave_out_en <= 1;  // 保持高电平输出，表示声音持续
        end else begin
            // 超过2秒后停止声音输出
            wave_out_en <= 0;
        end
    end

    // 主???辑：占空比变化和输出波形生??
    always @(posedge clk_new or negedge rst) begin
        if (~rst) begin
            counter <= 0;
            duty_cycle <= MAX_DUTY; // 初始占空比为95%
            direction <= 0;         // 初始方向为???减
        end else begin
            if (counter == MAX_CYCLES - 1) begin
                // ??50个周期调整一次占空比
                counter <= 0;

                if (direction == 0) begin
                    // 递减，占空比??95%减少??5%
                    if (duty_cycle > MIN_DUTY)
                        duty_cycle <= duty_cycle - STEP; // 每次递减1%
                    else
                        direction <= 1; // 如果占空比为5%，改变方向为递增
                end else begin
                    // 递增，占空比??5%增加??95%
                    if (duty_cycle < MAX_DUTY)
                        duty_cycle <= duty_cycle + STEP; // 每次递增1%
                    else
                        direction <= 0; // 如果占空比为95%，改变方向为递减
                end
            end else begin
                counter <= counter + 1; // 计数器???增
            end

            // 根据占空比控制输出方??
            if (counter < (duty_cycle * MAX_CYCLES) / 100 && wave_out_en) begin
                wave_out <= 1; // 高电??
            end else begin
                wave_out <= 0; // 低电??
            end
        end
    end

endmodule

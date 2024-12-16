`include "PARAMETER.v" 
module Edge_detection(
    input buttom_A,
    input buttom_S,
    input buttom_W,
    input buttom_X,
    input buttom_D,
    input buttom_rst,
    input clk,             //100MHz
    output reg sign_pos_A,
    output reg sign_pos_S,
    output reg sign_pos_W,
    output reg sign_pos_X,
    output reg sign_neg_X,
    output reg sign_pos_D
);
    reg [16:0] counter_A, counter_S_pos, counter_X_neg, counter_W, counter_X, counter_D;
    reg clk_out;             //1kHz
    parameter DIVISOR = 130000;

    reg [20:0]trig_A, trig_S, trig_W, trig_X, trig_D;

    always @(posedge clk or posedge buttom_rst) begin
        if (!buttom_rst) begin
            counter_A <= 0;
            counter_S_pos <= 0;
            counter_X_neg <= 0;
            counter_W <= 0;
            counter_X <= 0;
            counter_D <= 0;
            clk_out <= 0;
            sign_pos_A <= 0;
            sign_pos_S <= 0;
            sign_pos_W <= 0;
            sign_pos_X <= 0;
            sign_neg_X <= 0;
            sign_pos_D <= 0;
        end else begin
            //A_pos
            if (!trig_A[20]&!trig_A[19]&!trig_A[18]&trig_A[17]) begin
                counter_A <= 17'b00001;
            end else if(counter_A>0) begin
                counter_A <= counter_A + 1;
                if(counter_A>=DIVISOR) begin
                    if(trig_A[10]&trig_A[9])sign_pos_A <= 1;
                    counter_A <= 0;
                end
            end
            else begin
                counter_A <= 0;
                sign_pos_A <= 0;
            end
            //S_pos
            if(!trig_S[20]&!trig_S[19]&!trig_S[18]&trig_S[17]) begin
                counter_S_pos <= 17'b00001;
            end else if(counter_S_pos>0) begin
                counter_S_pos <= counter_S_pos + 1;
                if(counter_S_pos>=DIVISOR) begin
                    if(trig_S[10]&trig_S[9])sign_pos_S <= 1;
                    counter_S_pos <= 0;
                end
            end
            else begin
                counter_S_pos <= 0;
                sign_pos_S <= 0;
            end
            //W_pos
            if(!trig_W[20]&!trig_W[19]&!trig_W[18]&trig_W[17]) begin
                counter_W <= 17'b00001;
            end else if(counter_W>0) begin
                counter_W <= counter_W + 1;
                if(counter_W>=DIVISOR) begin
                    if(trig_W[10]&trig_W[9])sign_pos_W <= 1;
                    counter_W <= 0;
                end
            end
            else begin
                counter_W <= 0;
                sign_pos_W <= 0;
            end
            //X_pos
            if(!trig_X[20]&!trig_X[19]&!trig_X[18]&trig_X[17]) begin
                counter_X <= 17'b00001;
            end else if(counter_X>0) begin
                counter_X <= counter_X + 1;
                if(counter_X>=DIVISOR) begin
                    if(trig_X[10]&trig_X[9])sign_pos_X <= 1;
                    counter_X <= 0;
                end
            end
            else begin
                counter_X <= 0;
                sign_pos_X <= 0;
            end
            //X_neg
            if(trig_X[20]&trig_X[19]&trig_X[18]&!trig_X[17]) begin
                counter_X_neg <= 17'b00001;
            end else if(counter_X_neg>0) begin
                counter_X_neg <= counter_X_neg + 1;
                if(counter_X_neg>=DIVISOR) begin
                    if(!trig_X[10]&!trig_X[9])sign_neg_X <= 1;
                    counter_X_neg <= 0;
                end
            end
            else begin
                counter_X_neg <= 0;
                sign_neg_X <= 0;
            end
            //D_pos
            if(!trig_D[20]&!trig_D[19]&!trig_D[18]&trig_D[17]) begin
                counter_D <= 17'b00001;
            end else if(counter_D>0) begin
                counter_D <= counter_D + 1;
                if(counter_D>=DIVISOR) begin
                    if(trig_D[10]&trig_D[9])sign_pos_D <= 1;
                    counter_D <= 0;
                end
            end
            else begin
                counter_D <= 0;
                sign_pos_D <= 0;
            end
        end
    end


    always @(posedge clk or negedge buttom_rst) begin
        if(!buttom_rst) begin
            trig_A <= 21'b0;
            trig_S <= 21'b0;
            trig_W <= 21'b0;
            trig_X <= 21'b0;
            trig_D <= 21'b0;
        end
        else begin
            trig_A <= {trig_A[19:0], buttom_A};
            trig_S <= {trig_S[19:0], buttom_S};
            trig_W <= {trig_W[19:0], buttom_W};
            trig_X <= {trig_X[19:0], buttom_X};
            trig_D <= {trig_D[19:0], buttom_D};
        end
    end

endmodule
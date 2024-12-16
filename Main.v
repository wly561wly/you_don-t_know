`timescale 1ns / 1ps
`include "PARAMETER.v" 
module Main(
    input buttom_A,
    input buttom_S,
    input buttom_W,
    input buttom_X,
    input buttom_D,
    input switch_P,
    input buttom_rst,
    input clk,
    input light_dip,
    output light_on,
    output [7:0]chip,
    output [7:0]seg_74,
    output [7:0]seg_30,
    output opening,
    output reminder,
    output wave_out,
    output en 
);
    wire sign_pos_A, sign_pos_S, sign_neg_X, sign_pos_W, sign_pos_X, sign_pos_D;
    wire [31:0] sign;
    reg [6:0] state;
    wire [6:0] nxt_state;
    
    //change state
    always @(nxt_state)begin
        state = nxt_state;
    end

    //debounce module
    Edge_detection edge_detection(
        .buttom_A(buttom_A),
        .buttom_S(buttom_S),
        .buttom_W(buttom_W),
        .buttom_X(buttom_X),
        .buttom_D(buttom_D),
        .buttom_rst(buttom_rst),
        .clk(clk),
        .sign_pos_A(sign_pos_A),
        .sign_pos_S(sign_pos_S),
        .sign_pos_W(sign_pos_W),
        .sign_pos_X(sign_pos_X),
        .sign_neg_X(sign_neg_X),
        .sign_pos_D(sign_pos_D)
    );

    //control module
    control_module control_module(
        .state(state),
        .sign_pos_A(sign_pos_A),
        .sign_pos_S(sign_pos_S),
        .sign_pos_W(sign_pos_W),
        .sign_pos_X(sign_pos_X),
        .sign_neg_X(sign_neg_X),
        .sign_pos_D(sign_pos_D),
        .switch_P(switch_P),
        .light_dip(light_dip),
        .rst(buttom_rst),
        .clk(clk),
        .sign(sign),
        .nxt_state(nxt_state),
        .reminder(reminder),
        .opening(opening),
        .light_on(light_on)
    );

    // Instantiate the speaker_player module
    variable_duty_cycle_wave variable_duty_cycle_wave_inst (
        .clk(clk),              
        .rst(buttom_rst),              
        .state(state), 
        .wave_out(wave_out),      // output of the variable duty cycle wave
        .en(en)
    );
    
    //printout module
    print_output print(
        .en(opening),
        .sign7(sign[31:28]),
        .sign6(sign[27:24]),
        .sign5(sign[23:20]),
        .sign4(sign[19:16]),
        .sign3(sign[15:12]),
        .sign2(sign[11:8]),
        .sign1(sign[7:4]),
        .sign0(sign[3:0]),
        .rst(buttom_rst),
        .clk(clk),
        .seg_74(seg_74),
        .seg_30(seg_30),
        .tub_sel(chip)
    );

endmodule
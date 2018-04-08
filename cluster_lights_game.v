

// CLUSTER LIGHTS GAME: objective is to flash a series of lights to the user and ask
//                      then to solve a puzzle based on the number of lights flashing
//                      Manual player will have to tell the bomb which leds to focus 
//                      on and how to solve th code.
//                      Bomb player will have to select the switch pattern based on
//                      the LEDS

// CODES FOR GAME
//  _         _    E: count the number of LEDR's flashing at the same pace as LEDG 1
//   |   _         M: count the number of LEDR's flashing at the same pace as LEDG 4
// | |       |_|   H: go high SW[17:10] on all the LEDR's[17:10] which are at the same 
//                    pace as LEDG 0 or LEDG 3
//                    and use SW[9:0] to sum the number of LEDR's which are at the same
//                    pace as LEDG 6 and 10

//  _         _    E: count the number of LEDR's not flashing at the same pace as LEDG 1
//   |  |_   |_|   M: count the number of LEDG's flashing at the same pace as LEDR 7
// | |   _|  | |   H: count the number of LEDR's flashing at the same pace as LEDG 6 and
//                    multiply the number of LEDR's flashing at the same pace as LEDG 1

//       _         E: count the number of LEDR's flashing at the same pace as LEDG 3
// |_|  | |  | |   M: count the number of LEDR's flashing at the same pace as LEDG 6
//  _   | |  |_|   H: count the number of LEDR's flashinga the same pace as LEDG 7 and
//                    add the number of LEDG's flashing at the same pace as LEDG 6 and
//                    subtract the number of LEDG's flashing at the same pace as LEDG 3

//       _    _    E: count the number of LEDR's not flashing at the same pace as LEDG 5
// |_|  |_     |   M: count the number of LEDR's not flashing at the same pace as LEDG 7
//  _    _|   _    H: count the number of LEDR's flashing at the same pace as LEDG 5 and
//                    multiply them by the number of LEDG's flashing at the same pace as LEDG 3
//                    then add 4

module cluster_lights_game(answer, submit, clock, counter, difficulty, reset,
                           out_LEDG, out_LEDR, out_HEX1, out_HEX2, out_HEX3, out_HEX4,
                           win, lose);
    input [17:0] answer;
    input submit;
    input clock;
    input [27:0] counter;
    input [1:0] difficulty;
    input reset;

    output [7:0] out_LEDG;
    output [17:0] out_LEDR;
    output [7:0] out_HEX1;
    output [7:0] out_HEX2;
    output [7:0] out_HEX3;
    output [7:0] out_HEX4;
    output reg win;
    output reg lose;

    wire [3:0] sub_clock;
    wire [6:0] pulses;
    wire [17:0] combination;

    reg randomize;
    reg [3:0] random_indicator;

    initial randomize = 0;

    // creates 4 different clocks
    ratedivider c0(.clock(clock), .reset(1'b0),
                .divide(28'b0100011110000110100010111111), .cout(sub_clock[0]));    // 0.25 second clock
    ratedivider c1(.clock(clock), .reset(1'b0),
                .divide(28'b0001011111010111100000111111), .cout(sub_clock[1]));    //  0.5 second clock
    ratedivider c2(.clock(clock), .reset(1'b0),
                .divide(28'b0010111110101111000001111111), .cout(sub_clock[2]));    //    1 second clock
    ratedivider c3(.clock(clock), .reset(1'b0),
                .divide(28'b0101111101011110000011111111), .cout(sub_clock[3]));    //    2 second clock


    // creates 7 different rates based on the unique clocks
    count_up_to p0(.clock(sub_clock[0]), .reset(1'b0), .max(4'b0100), 
                   .pulse0_count1(1'b0), .out(pulses[0]));                         // 0.25 second counter, 1 second sync
    count_up_to p1(.clock(sub_clock[0]), .reset(1'b0), .max(4'b1000), 
                   .pulse0_count1(1'b0), .out(pulses[1]));                         // 0.25 second counter, 2 second sync
    count_up_to p2(.clock(sub_clock[1]), .reset(1'b0), .max(4'b0010), 
                   .pulse0_count1(1'b0), .out(pulses[2]));                         //  0.5 second counter, 1 second sync
    count_up_to p3(.clock(sub_clock[1]), .reset(1'b0), .max(4'b0100), 
                   .pulse0_count1(1'b0), .out(pulses[3]));                         //  0.5 second counter, 2 second sync
    count_up_to p4(.clock(sub_clock[2]), .reset(1'b0), .max(4'b0010), 
                   .pulse0_count1(1'b0), .out(pulses[4]));                         //    1 second counter, 1 second sync
    count_up_to p5(.clock(sub_clock[2]), .reset(1'b0), .max(4'b0001), 
                   .pulse0_count1(1'b0), .out(pulses[5]));                         //    1 second counter, 2 second sync
    count_up_to p6(.clock(sub_clock[3]), .reset(1'b0), .max(4'b0001), 
                   .pulse0_count1(1'b0), .out(pulses[6]));                         //    2 second counter, 2 second sync
    

    // target values
    // wires up the green LEDS
    cluster_lights_game_LEDG_maker my_LEDG(.in(random_indicator), .p(pulses),
                                           .out(out_LEDG));
    // wires up the red LEDS
    cluster_lights_game_LEDG_maker my_LEDR(.in(random_indicator), .p(pulses), 
                                           .out(out_LEDR));
    // wires up the hex symbol
    cluster_lights_game_HEX_maker my_HEX(.in(random_indicator[1:0]), 
                                         .out1(out_HEX1), .out2(out_HEX2), .out3(out_HEX3));
    // wires up the appropriate combination
    cluster_lights_game_combination_maker my_combination(.in(random_indicator), 
                                                         .out(combination));


//    reg counter_mod[1:0];
    // processes data for module
    always @ (*)
    begin
	// randomizer
        if (randomize == 1'b0) begin
//            counter_mod <= counter * 13 % 4;
            random_indicator <= {difficulty[1], difficulty[0], counter[1], counter[0]};    // diffculty + random 2 bit number
            randomize <= 1;    // only allow rate to generate once
        end	
        random_indicator <= 4'b0101;
    end

    always @ (negedge submit)
    begin
        win <= (answer == combination);
        lose <= (answer != combination);
    end

endmodule


// takes in a 4 bit indicator and makes a combination for LEDG
module cluster_lights_game_LEDG_maker(in, p, out);
    input [3:0] in;
    input [6:0] p;
    output reg [7:0] out;

    always @(*)
        begin
            case(in[3:0])
                // easy cases
                4'b01_00: out = {p[1], 1'b0, p[2], 1'b0, p[3], 1'b0, p[4], 1'b0};
                4'b01_01: out = {p[3], 1'b0, p[1], 1'b0, p[4], 1'b0, p[6], 1'b0};
                4'b01_10: out = {p[4], 1'b0, p[2], 1'b0, p[5], 1'b0, p[1], 1'b0};
                4'b01_11: out = {p[6], 1'b0, p[3], 1'b0, p[5], 1'b0, p[0], 1'b0};

                // medium cases
                4'b10_00: out = {p[6], 1'b0, p[3], 1'b0, p[4], 1'b0, p[1], 1'b0};
                4'b10_01: out = {p[3], 1'b0, p[2], 1'b0, p[4], 1'b0, p[0], 1'b0};
                4'b10_10: out = {p[2], 1'b0, p[5], 1'b0, p[6], 1'b0, p[1], 1'b0};
                4'b10_11: out = {p[1], 1'b0, p[0], 1'b0, p[3], 1'b0, p[4], 1'b0};

                // hard cases
                4'b11_00: out = {p[6], 1'b0, p[2], 1'b0, p[3], 1'b0, p[4], 1'b0};
                4'b11_01: out = {p[3], 1'b0, p[2], 1'b0, p[0], 1'b0, p[1], 1'b0};
                4'b11_10: out = {p[4], 1'b0, p[1], 1'b0, p[4], 1'b0, p[5], 1'b0};
                4'b11_11: out = {p[4], 1'b0, p[2], 1'b0, p[1], 1'b0, p[3], 1'b0};

                default out = 8'b0000_0000;
            endcase
	end
endmodule


// takes in a 4 bit indicator and makes a combination for LEDR
module cluster_lights_game_LEDR_maker(in, p, out);
    input [3:0] in;
    input [6:0] p;
    output reg [17:0] out;

    always @(*)
        begin
            case(in[3:0])
                // easy cases
                4'b01_00: out = {p[0], 1'b0, 1'b0, p[1], 1'b0, 1'b0, p[6], 1'b0, 1'b0,
                                 p[1], 1'b0, 1'b0, p[2], 1'b0, 1'b0, p[6], 1'b0, 1'b0};
                4'b01_01: out = {p[3], 1'b0, 1'b0, p[4], 1'b0, 1'b0, p[3], 1'b0, 1'b0,
                                 p[1], 1'b0, 1'b0, p[6], 1'b0, 1'b0, p[2], 1'b0, 1'b0};
                4'b01_10: out = {p[4], 1'b0, 1'b0, p[2], 1'b0, 1'b0, p[1], 1'b0, 1'b0,
                                 p[5], 1'b0, 1'b0, p[2], 1'b0, 1'b0, p[2], 1'b0, 1'b0};
                4'b01_11: out = {p[1], 1'b0, 1'b0, p[2], 1'b0, 1'b0, p[0], 1'b0, 1'b0,
                                 p[1], 1'b0, 1'b0, p[3], 1'b0, 1'b0, p[6], 1'b0, 1'b0};

                // medium cases
                4'b10_00: out = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, p[1], 1'b0,
                                 p[1], 1'b0, p[5], 1'b0, p[4], 1'b0, p[2], 1'b0, p[4]};
                4'b10_01: out = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, p[0], 1'b0,
                                 p[5], 1'b0, p[3], 1'b0, p[2], 1'b0, p[5], 1'b0, p[6]};
                4'b10_10: out = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, p[2], 1'b0,
                                 p[3], 1'b0, p[5], 1'b0, p[6], 1'b0, p[4], 1'b0, p[2]};
                4'b10_11: out = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, p[0], 1'b0,
                                 p[1], 1'b0, p[0], 1'b0, p[1], 1'b0, p[3], 1'b0, p[0]};


                // hard cases
                4'b11_00: out = {p[1], 1'b0, p[4], 1'b0, p[1], 1'b0, p[3], 1'b0, p[4],
                                 1'b0, p[5], 1'b0, p[4], 1'b0, p[0], 1'b0, p[1], 1'b0};
                4'b11_01: out = {p[6], 1'b0, p[1], 1'b0, p[3], 1'b0, p[4], 1'b0, p[6],
                                 1'b0, p[1], 1'b0, p[0], 1'b0, p[0], 1'b0, p[0], 1'b0};
                4'b11_10: out = {p[1], 1'b0, p[3], 1'b0, p[4], 1'b0, p[2], 1'b0, p[0],
                                 1'b0, p[4], 1'b0, p[6], 1'b0, p[4], 1'b0, p[1], 1'b0};
                4'b11_11: out = {p[2], 1'b0, p[6], 1'b0, p[4], 1'b0, p[1], 1'b0, p[0],
                                 1'b0, p[3], 1'b0, p[1], 1'b0, p[3], 1'b0, p[0], 1'b0};

                default out = 18'b00_0000_0000_0000_0000;

            endcase
	end
endmodule

// takes in a 2 bit indicator and makes a combination for the 3 HEXs
module cluster_lights_game_HEX_maker(in, out1, out2, out3);
    input [2:0] in;
    output reg [6:0] out1;
    output reg [6:0] out2;
    output reg [6:0] out3;

    always @(*)
        begin
            case(in[2:0])
                // easy cases
                2'b00: begin
                    out1 = 7'b1100010;
                    out2 = 7'b0111111;
                    out3 = 7'b1101000;
                end
                2'b01: begin
                    out1 = 7'b0001000;
                    out2 = 7'b0010011;
                    out3 = 7'b1101000;
                end
                2'b10: begin
                    out1 = 7'b1000001;
                    out2 = 7'b1001000;
                    out3 = 7'b0010101;
                end
                2'b11: begin
                    out1 = 7'b1110100;
                    out2 = 7'b0010010;
                    out3 = 7'b0010101;
                end

                default begin
                    out1 = 7'b0000000;
                    out2 = 7'b0000000;
                    out3 = 7'b0000000;
                end
            endcase
	end
endmodule


// takes in a 4 bit indicator and determines the appropriate answer for the cluster lights game
module cluster_lights_game_combination_maker(in,out);
    input [3:0] in;
    output reg [17:0] out;

    always @(*)
        begin
            case(in[3:0])
                // easy cases
                4'b01_00: out = 18'b00_0000_0000_0000_0000;
                4'b01_01: out = 18'b00_0000_0000_0000_0001;
                4'b01_10: out = 18'b00_0000_0000_0000_0011;
                4'b01_11: out = 18'b00_0000_0000_0000_0001;

                // medium cases
                4'b10_00: out = 18'b00_0000_0000_0000_0010;
                4'b10_01: out = 18'b00_0000_0000_0000_0000;
                4'b10_10: out = 18'b00_0000_0000_0000_0001;
                4'b10_11: out = 18'b00_0000_0000_0000_0010;

                // hard cases
                4'b11_00: out = 18'b00_0000_0000_0000_0011;
                4'b11_01: out = 18'b00_0000_0000_0000_0011;
                4'b11_10: out = 18'b00_0000_0000_0000_0010;
                4'b11_11: out = 18'b00_0000_0000_0000_0001;

                default out = 18'b00_0000_0000_0000_0000;
            endcase
	end
endmodule



module count_up_to(clock, reset, max, pulse0_count1, out);
    input clock,  reset;
    input [27:0] max;
    input pulse0_count1;
    output reg out;

    reg [27:0] curr;
    initial curr = 0;

    // counts up to max based on clock pulses
    always@ (posedge clock)
    begin
        if (reset) begin
            curr <= 0;
        end else if (curr == max - 1) begin
            curr <= 0;
        end else begin
            curr <= curr + 1;
        end
    end

    // output statement
    always @(*)
    begin
        // if tracking pulses then high when it hits max
        if (pulse0_count1 == 1'b0) begin
            out <= (curr == max - 1);
        // if not tracking pulses then output the counter
        end else begin
            out <= curr;
        end
    end


endmodule
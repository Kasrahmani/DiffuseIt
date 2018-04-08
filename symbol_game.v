// SYMBOL GAME: objective is to provide a encrypted symbol to the user and ask them so solve
//              the combination based on a linked combination in the manual
//              the difficulty will determine how many symbols have to be solved
//              Manual will have to tell the bomb which leds to focus on and how to solve th code.
//              Bomb player will have to select the LEDS based on the HEX pattern

// SYMBOLS FOR GAME
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//
//  _ 
// |_|   COMBINATION: 18'b00_0000_0000_0000_0000
// |_|
//

module symbol_game(answer, submit, clock, counter, difficulty, reset,
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
    output win;
    output lose;
	 
    wire [17:0] combination;
    wire [7:0] symbol;

    reg randomize;
    reg [2:0] random_indicator;
    reg [4:0] Y_Q, Y_D;

    initial randomize = 0;


    // FSM states
    localparam A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011, 
	            E = 3'b100, F = 3'b101, W = 3'b110, L = 3'b111;
	
    // FSM
    always @ (*)
    begin: state_table
        case (Y_Q)

            // initialize
            A: begin
                if (answer == combination) Y_D <= B;      // if correct then advance
                else Y_D <= L;                            // else you lose
            end

            B: begin
                if (answer == combination) begin
                    if (difficulty == 2'b00) Y_D <= W;    // win case for easy (2 completions)
                    else Y_D <= C;                    // if correct then advance
                end
                else Y_D <= L;                            // else you lose
            end

            C: begin
                if (answer == combination) begin
                    if (difficulty == 2'b01) Y_D <= W;    // win case for med (3 completions)
                    else Y_D <= D;                        // if correct then advance
                end
                else Y_D <= L;                            // else you lose
            end

            D: begin
                if (answer == combination) Y_D <= E;      // if correct then advance
                else Y_D <= L;                            // else you lose
            end

            E: begin
                if (answer == combination) Y_D <= W;      // win case for hard (5 completions)
                else Y_D <= L;    // else you lose
            end

            // win case
            W: begin
                Y_D <= W;
            end

            // lose case
            L: begin
                Y_D <= L;
            end
				
            default: Y_D = A;
        endcase
    end // state_table

	 
    // State Registers
    always @ (negedge submit)
    begin: state_FFs
        Y_Q <= Y_D;
    end // state_FFS


    assign out_LEDG[0] = (Y_Q == A);
    assign out_LEDG[1] = (Y_Q == B);
    assign out_LEDG[2] = (Y_Q == C);
    assign out_LEDG[3] = (Y_Q == D);
    assign out_LEDG[4] = (Y_Q == E); 
    assign out_LEDG[5] = (Y_Q == F);
    assign out_LEDG[6] = (Y_Q == W);
    assign out_LEDG[7] = (Y_Q == L);
    
	
    // processes data for module
    always @ (*)
    begin

        // resets randomizer after submission
        if (submit == 1'b0) begin
            randomize <= 0;
        end

	  // randomizer
        if (randomize == 1'b0) begin 
            random_indicator <= {difficulty[1], difficulty[0], counter[1], counter[0]};    // random 3 bit number
            randomize <= 1;    // only allow rate to generate once
        end
    end
  
    // target values
    symbol_game_symbol_maker my_symbol(.in(random_indicator), .out(symbol));
    symbol_game_combination_maker my_combination(.in(random_indicator), .out(combination));


    assign win = (Y_Q == W);
    assign lose = (Y_Q == L);
    assign out_HEX1 = symbol;

endmodule


// takes in a 3 bit indicator and makes a hex symbol
// hex symbol matches the combination in the manual
module symbol_game_symbol_maker(in, out);
    input [2:0] in;
    output reg [6:0] out;

    always @(*)
        begin
            case(in[2:0])
                3'b000: out = 7'b1101000;
                3'b001: out = 7'b1100010;
                3'b010: out = 7'b1010011;
                3'b011: out = 7'b1000001;
                3'b100: out = 7'b1110100;
                3'b101: out = 7'b0110110;
                3'b110: out = 7'b0011100;
                3'b111: out = 7'b0111010;

                default out = 7'b0000000;
            endcase
	end
endmodule


// takes in a 3 bit indicator and makes a combination
// combination matches the hex symbol in the manual
module symbol_game_combination_maker(in,out);
    input [2:0] in;
    output reg [17:0] out;

    always @(*)
        begin
            case(in[2:0])
                3'b000: out = 18'b10_0100_0110_1111_0000;
                3'b001: out = 18'b01_0110_0001_0100_1101;
                3'b010: out = 18'b00_1100_0111_1010_1010;
                3'b011: out = 18'b11_0110_0100_1100_1111;
                3'b100: out = 18'b00_1000_0110_0001_0100;
                3'b101: out = 18'b00_0111_1100_0001_0101;
                3'b110: out = 18'b01_1100_0100_1010_0110;
                3'b111: out = 18'b10_0110_0001_1100_0111;

                default out = 18'b00_0000_0000_0000_0000;
            endcase
	end
endmodule

module ratedivider(clock, reset, divide, cout);
    input clock;
    input reset;
    input [27:0] divide;
    output reg cout;
 
    reg [27:0] count; //counts upto divide
    initial count = 0; 

    // new clock based on divide where output flips at divide
    always @ (posedge clock)
    begin 
       if (!reset) begin
           if(count==divide) begin
              count <= 0;
              cout = !cout;    // output flip
           end else begin
              count <= count + 1;
              cout <= cout;
           end
       end else begin
          count <=0;
          cout <= 0;
       end
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
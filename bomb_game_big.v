module bomb_game_big(SW, KEY, CLOCK_50, LEDG, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
    
    input [17:0] SW;
    input [4:0] KEY;
    input CLOCK_50;
    output [17:0] LEDR;
    output [7:0] LEDG;
    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX2;
    output [6:0] HEX3;
    output [6:0] HEX4;
    output [6:0] HEX5;
    output [6:0] HEX6;
    output [6:0] HEX7;


    control my_game (SW[16:0], KEY[3:0], CLOCK_50, 1'b1,
                     LEDG[7:0], LEDR[17:0], 
                     HEX0[6:0], HEX1[6:0], HEX2[6:0], HEX3[6:0], HEX4[6:0], HEX5[6:0], HEX6[6:0], HEX7[6:0]);


endmodule

module control(answer, submit, clock, start,
               out_LEDG, out_LEDR, 
               out_HEX0, out_HEX1, out_HEX2, out_HEX3, out_HEX4, out_HEX5, out_HEX6, out_HEX7);
    
    input [17:0] answer;
    input [3:0] submit;
    input clock;
    input start;

    output [7:0] out_LEDG;
    output [17:0] out_LEDR;
    output [6:0] out_HEX0;
    output [6:0] out_HEX1;
    output [6:0] out_HEX2;
    output [6:0] out_HEX3;
    output [6:0] out_HEX4;
    output [6:0] out_HEX5;
    output [6:0] out_HEX6;
	 output [6:0] out_HEX7;
	 hex_display currstate(current_state, out_HEX7);
    // resets all modules
    initial reset_m = 1;
    reg reset_m;
    reg [1:0] difficulty_m;
    reg [4:0] signal;
	 
    wire time_out;
    stopwatch countdowntimer(.clock(clock), .reset(reset_m), .start(1'b1), .hex0out(out_HEX4),
                             .hex1out(out_HEX5), .hex2out(out_HEX6), .lose(time_out));
	 

    // main FSM
    reg [3:0] current_state;
    reg [3:0] next_state;
    initial current_state = 4'b0000;
    initial next_state = 4'b0000;

    localparam  MAIN_MENU = 4'b0000,
                SELECT_1  = 4'b0001,
                PUZZLE_1  = 4'b0010,
                SELECT_2  = 4'b0011,
                PUZZLE_2  = 4'b0100,
                SELECT_3  = 4'b0101,
                PUZZLE_3  = 4'b0110,
                WIN       = 4'b0111,
                LOSS      = 4'b1000;
    
    // Next state logic aka our state table
	 always@(*)
    begin: state_table 
        case (current_state)
               MAIN_MENU: next_state <= start ? SELECT_1 : MAIN_MENU; // Loop in current state until value is input

               SELECT_1: next_state = start ? PUZZLE_1 : SELECT_1; // Loop in current state until go signal goes low
					
               PUZZLE_1: 	begin
						if(win_m == 1'b1) begin
							next_state = SELECT_2;
						end
						else if(loss_m == 1'b1) begin
							next_state = LOSS;
						end
						else begin
							next_state = PUZZLE_1;
						end
					end
					
               SELECT_2: next_state = start ? PUZZLE_2 : SELECT_2; // Loop in current state until go signal goes low
					
               PUZZLE_2: 	begin
						if(win_m == 1'b1) begin
							next_state = SELECT_3;
						end
						else if(loss_m == 1'b1) begin
							next_state = LOSS;
						end
						else begin
							next_state = PUZZLE_2;
						end
               end
					
               SELECT_3: next_state = start ? PUZZLE_3 : SELECT_3; // Loop in current state until go signal goes low
					
               PUZZLE_3: 	begin
						if(win_m == 1'b1) begin
							next_state = WIN;
						end
						else if(loss_m == 1'b1) begin
							next_state = LOSS;
						end
						else begin
							next_state = PUZZLE_3;
						end
               end
					
               WIN: next_state = start ? MAIN_MENU : WIN; // Loop in current state until go signal goes low

               LOSS: next_state = start ? MAIN_MENU : MAIN_MENU; // Loop in current state until go signal goes low


            default:     next_state = MAIN_MENU;
        endcase
	end

	 
    // State Registers
    always @ (negedge submit[1])
    begin: state_FFs

        // bomb check
        if (time_out == 1 && current_state != MAIN_MENU) begin
            current_state <= LOSS;
			end
        // only enable state switching if game is done
        else if (current_state == PUZZLE_1 || 
                    current_state == PUZZLE_2 || 
                    current_state == PUZZLE_3) begin
            if (win_m == 1'b1 || loss_m == 1'b1) begin
                current_state <= next_state;
            end

        // only enable new game if all SW bits are high
        end else if (current_state == WIN ||
                     current_state == LOSS) begin
            if (answer == 17'b1_1111_1111_1111_1111) begin
                current_state <= next_state;
            end

        // if not in game you can switch states immediately
        end else begin
            current_state <= next_state;
        end

    end // state_FFS


    //puzzle chooser
    reg [4:0] total_signal;
	 // = 5'b00000;
    reg [4:0] prev;
	 // = total_signal;
    reg [4:0] current_p;
    //initial current_p = 5'b00001;


    always@(*)
    begin
        // continuously cycles through puzzles
        case (current_p)
            5'b00001: current_p = 5'b00010;
            5'b00010: current_p = 5'b00100;
            5'b00100: current_p = 5'b01000;
            5'b01000: current_p = 5'b10000;
            5'b10000: current_p = 5'b00001;

            // default reset the loop
            default: current_p = 5'b00001;
        endcase
    end

    
    // state specific cases
    always @(*)
    begin

        if (current_state == MAIN_MENU) begin    // main menu needs to select difficulty
            reset_m <= 1;
            difficulty_m <= answer[1:0];
            
            if (difficulty_m == 2'b00) begin    // min difficulty
                difficulty_m <= 2'b01;
            end
		end else if (current_state == LOSS) begin
				reset_m <= 1;

        // turns difficulty back off for all other states in the game
        end else begin
            reset_m <= 0;
        end

        if (current_state == SELECT_1 || current_state == PUZZLE_1) begin
            signal <= 5'b00010;
        end else if (current_state == SELECT_2 || current_state == PUZZLE_2) begin
            signal <= 5'b00010;
        end else if (current_state == SELECT_3 || current_state == PUZZLE_3) begin
            signal <= 5'b00100;
        end else begin
            signal <= 5'b00000;
        end
        difficulty_m <= 2'b01;
    end
    


    // wires for puzzles
    wire [17:0] answer_m;
    assign answer_m[17:0] = answer[17:0];
    wire [3:0] submit_m; 
    assign submit_m[3:0] = submit[3:0];
    wire [7:0] LEDG_m;
    assign out_LEDG[7:0] = LEDG_m[7:0];
    wire [17:0] LEDR_m;
    assign out_LEDR [17:0] = LEDR_m[17:0];
    wire [6:0] HEX1_m;
    assign out_HEX0[6:0] = HEX1_m[6:0];
    wire [6:0] HEX2_m; 
    assign out_HEX1[6:0] = HEX2_m[6:0];
    wire [6:0] HEX3_m;
    assign out_HEX2[6:0] = HEX3_m[6:0];
    wire [6:0] HEX4_m;
    assign out_HEX3[6:0] = HEX4_m[6:0];
    wire win_m;
    wire loss_m;

    wire [17:0] answer_1;
    wire [3:0] submit_1;
    wire [7:0] LEDG_1;
    wire [17:0] LEDR_1;
    wire [6:0] HEX1_1;
    wire [6:0] HEX2_1;
    wire [6:0] HEX3_1;
    wire [6:0] HEX4_1;
    wire win_1;
    wire loss_1;

    wire [17:0] answer_2;
    wire [3:0] submit_2;
    wire [7:0] LEDG_2;
    wire [17:0] LEDR_2;
    wire [6:0] HEX1_2;
    wire [6:0] HEX2_2;
    wire [6:0] HEX3_2;
    wire [6:0] HEX4_2;
    wire win_2;
    wire loss_2;

    wire [17:0] answer_3;
    wire [3:0] submit_3;
    wire [7:0] LEDG_3;
    wire [17:0] LEDR_3;
    wire [6:0] HEX1_3;
    wire [6:0] HEX2_3;
    wire [6:0] HEX3_3;
    wire [6:0] HEX4_3;
    wire win_3;
    wire loss_3;

    wire [17:0] answer_4;
    wire [3:0] submit_4;
    wire [7:0] LEDG_4;
    wire [17:0] LEDR_4;
    wire [6:0] HEX1_4;
    wire [6:0] HEX2_4;
    wire [6:0] HEX3_4;
    wire [6:0] HEX4_4;
    wire win_4;
    wire loss_4;

    wire [17:0] answer_5;
    wire [3:0] submit_5;
    wire [7:0] LEDG_5;
    wire [17:0] LEDR_5;
    wire [6:0] HEX1_5;
    wire [6:0] HEX2_5;
    wire [6:0] HEX3_5;
    wire [6:0] HEX4_5;
    wire win_5;
    wire loss_5;


    // demuxes and muxes to wire up active puzzle

    demux de_answer(answer_m, signal, 0, answer_1, answer_2, answer_3, answer_4, answer_5);
    demux de_submit(submit_m, signal, 1, submit_1, submit_2, submit_3, submit_4, submit_5);
    mux me_ledg(LEDG_m, signal, 0, LEDG_1, LEDG_2, LEDG_3, LEDG_4, LEDG_5);
    mux me_ledr(LEDR_m, signal, 0, LEDR_1, LEDR_2, LEDR_3, LEDR_4, LEDR_5);
    mux me_hex1(HEX1_m, signal, 1, HEX1_1, HEX1_2, HEX1_3, HEX1_4, HEX1_5);
    mux me_hex2(HEX2_m, signal, 1, HEX2_1, HEX2_2, HEX2_3, HEX2_4, HEX2_5);
    mux me_hex3(HEX3_m, signal, 1, HEX3_1, HEX3_2, HEX3_3, HEX3_4, HEX3_5);
    mux me_hex4(HEX4_m, signal, 1, HEX4_1, HEX4_2, HEX4_3, HEX4_4, HEX4_5);
    mux me_win (win_m, signal, 0, win_1, win_2, win_3, win_4, win_5);
    mux me_loss(loss_m, signal, 0, loss_1, loss_2, loss_3, loss_4, loss_5);


    // counter for in game puzzle randomization
    wire counter_m;
    count_up_to my_counter(clock, 1'b0, 100, 1'b1, counter_m);


    maze_top sim1(answer_1, submit_1, clock, 2'b01, 2'b01, 1'b0, 
                    LEDG_1, LEDR_1, HEX1_1, HEX2_1, HEX3_1, HEX4_1, win_1, loss_1);
						  
	 symbol_game sim2(answer_2, submit_2, clock, counter_m, 2'b01, 1'b0, 
                    LEDG_2, LEDR_2, HEX1_2, HEX2_2, HEX3_2, HEX4_2, win_2, loss_2);
					  
	 cluster_lights_game sim3(answer_3, submit_3, clock, 2'b01, 2'b01, 1'b0, 
                    LEDG_3, LEDR_3, HEX1_3, HEX2_3, HEX3_3, HEX4_3, win_3, loss_3);
						  
//    maze_game sim2(answer_2, submit_2, clock, counter_m, difficulty_m, reset_m, 
//                  LEDG_2, LEDR_2, HEX1_2, HEX2_2, HEX3_2, HEX4_2, win_2, loss_2);

//    symbol_game sim3(answer_3, submit_3, clock, counter_m, difficulty_m, reset_m,
//                   LEDG_3, LEDR_3, HEX1_3, HEX2_3, HEX3_3, HEX4_3, win_3, loss_3);

//    gates_game sim4(answer_4, submit_4, clock, counter_m, difficulty_m, reset_m, 
//                    LEDG_4, LEDR_4, HEX1_4, HEX2_4, HEX3_4, HEX4_4, win_4, loss_4);

//    cluster_lights_game sim5(answer_5, submit_5, clock, counter_m, difficulty_m, reset_m,
//                   LEDG_5, LEDR_5, HEX1_5, HEX2_5, HEX3_5, HEX4_5, win_5, loss_5);



endmodule


/*

    THE CONCEPT FOR THE DEMUX IS BEING BORROWED FROM:
    http://verilogcodes.blogspot.ca/2015/10/verilog-code-for-14-demux-using-case.html

*/

module demux(in, signal, init, out_0, out_1, out_2, out_3, out_4);
    input [17:0] in;
    input [4:0] signal;
    input init;
    output reg [17:0] out_0;
    output reg [17:0] out_1;
    output reg [17:0] out_2;
    output reg [17:0] out_3;
    output reg [17:0] out_4;

    always @ (*)
    begin

        // initializes output registers to be off
        out_0 <= init;
        out_1 <= init;
        out_2 <= init;
        out_3 <= init;
        out_4 <= init;

        // case statement to change selected register
        case(signal)
            5'b00001: out_0 <= in;
            5'b00010: out_1 <= in;
            5'b00100: out_2 <= in;
            5'b01000: out_3 <= in;
            5'b10000: out_4 <= in;

        endcase
    end

endmodule
/*

    END OF BORROWED CODE FROM:
    http://verilogcodes.blogspot.ca/2015/10/verilog-code-for-14-demux-using-case.html

*/


/*

	THE CODE BELOW IS INSPIRED BY THE DEMUX CODE

*/
module mux(allout, signal, init, in_0, in_1, in_2, in_3, in_4);
	input [17:0] in_0, in_1, in_2, in_3, in_4;
	input [4:0] signal;
	input init;
	output reg [17:0] allout;
	
	initial allout = 18'b000000000000000000; 
	
	always @(*)
	begin

/*
        // initializes output registers to be off
        in_0 <= init;
        in_1 <= init;
        in_2 <= init;
        in_3 <= init;
        in_4 <= init;
*/

		case(signal)
			5'b00001: allout <= in_0;
			5'b00010: allout <= in_1;
			5'b00100: allout <= in_2;
			5'b01000: allout <= in_3;
			5'b10000: allout <= in_4;
			
			default: allout <= 18'd0;
		endcase
	end
endmodule
/*

	INSPIRATION ENDS HERE

*/


/*

	THE BASE CODE FOR THE STOPWATCH IS BEING BORROWED FROM:
	http://simplefpga.blogspot.ca/2012/07/to-code-stopwatch-in-verilog.html
	

*/
module stopwatch(
    input clock,
    input reset,
    input start,
    output [6:0] hex0out, hex1out, hex2out,
	 output reg lose
    );
	 
	reg [3:0] seconds, ten_seconds, minutes; //registers that will hold the individual counts
	reg [27:0] ticker; //28 bits needed to count up to 49,999,999M bits
	wire click;
	 
	 
	//the mod 5M clock to generate a tick ever 0.1 second
	 
	always @ (posedge clock or posedge reset)
	begin
	 if(reset)
	 
	  ticker <= 0;
	 
	 else if(ticker == 28'd49999999) //if it reaches the desired max value reset it
	  ticker <= 0;
	 else if(start) //only start if the input is set high
	  ticker <= ticker + 1;
	end
	// click is enable
	assign click = ((ticker == 28'd49999999)?1'b1:1'b0); //click to be assigned high every 0.1 second
	initial seconds = 4'd0;
	initial ten_seconds = 4'd1;
	initial minutes = 4'd0;
	initial lose = 1'b0;
	 
	always @ (posedge clock or posedge reset)
	begin
	 if (reset)
	  begin
		seconds <= 4'd0;
		ten_seconds <= 4'd0;
		minutes <= 4'd5;
		lose <= 1'b0;
	  end
		
	 else if (click) //increment at every click
	  begin
	  if (seconds + ten_seconds + minutes == 0)
	  begin
	    lose <= 1'b1;
	  end
	  else
	  begin
		if(seconds == 4'd0) //xx9 - the 1 second digit
		begin  //if_1
		 seconds <= 4'd9;
		  
		 if (ten_seconds == 4'd0) //x59 the two digit seconds digit
		 begin  // if_2
		  ten_seconds <= 4'd5;
		  if (minutes == 4'd0) //959 - the min digit
		  begin //if_3
			lose <= 1'b1;
		  end
		  else //else_3
			minutes <= minutes - 1;
		 end
		  
		 else //else_2
		  ten_seconds <= ten_seconds - 1;
		end
		 
		else //else_1
		 seconds <= seconds - 1;
	  end
	  end
	end
	
	hex_display seconds_hex(.IN(seconds), .OUT(hex0out));
	hex_display tensecs_hex(.IN(ten_seconds), .OUT(hex1out));
	hex_display minutes_hex(.IN(minutes), .OUT(hex2out));
	 
endmodule
/*

	END OF BORROWED CODE FROM:
	http://simplefpga.blogspot.ca/2012/07/to-code-stopwatch-in-verilog.html

*/


module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule


/*

module bomb_game(SW, KEY,CLOCK_50, LEDG,LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
    input [17:0] SW;
    input [4:0] KEY;
    input CLOCK_50;
    output [17:0] LEDR;
    output[7:0] LEDG;
    output [7:0] HEX0;
    output [7:0] HEX1;
    output [7:0] HEX2;
    output [7:0] HEX3;
    output [7:0] HEX4;
    output [7:0] HEX5;
    output [7:0] HEX6;
    output [7:0] HEX7;
	 
	 
	 
	 wire [4:0] answer;
	 wire [4:0] submit;
	 wire [4:0] clock;
	 wire [4:0] counter;
	 wire [4:0] difficulty;
	 wire [4:0] enable;
	 wire [4:0] out_LEDG;
	 wire [4:0] out_LEDR;
	 wire [4:0] out_HEX1;
	 wire [4:0] out_HEX2;
	 wire [4:0] out_HEX3;
	 wire [4:0] out_HEX4;
    wire [4:0] win;
	 wire [4:0] lose;
	 
	 wire counter_m;
    count_up_to my_counter(CLOCK_50, 1'b0, 100, 1'b1, counter_m);
	 
	 
	 //symbol_game sim1(SW[17:0], KEY[3], CLOCK_50, counter_m, 2'b01, 1'b0,
    //                 LEDG[7:0], LEDR[17:0], HEX0[7:0], HEX1[7:0], HEX2[7:0], HEX4[7:0],
    //                 HEX5[0], HEX5[3]);
	 
	 cluster_lights_game sim2(SW[17:0], KEY[3], CLOCK_50, 2'b01, 2'b10, 1'b0,
                     LEDG[7:0], LEDR[17:0], HEX0[7:0], HEX1[7:0], HEX2[7:0], HEX4[7:0],
                     HEX5[0], HEX5[3]);
	 

endmodule
*/


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

module maze(SW, KEY, CLOCK_50, LEDR, LEDG,HEX0,HEX1,HEX2,HEX3);
    input [17:0] SW;
    input [3:0] KEY;
    input CLOCK_50;
    output [17:0] LEDR;
    output [7:0] LEDG;
    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX2;
    output [6:0] HEX3;
    wire [1:0] counter;
    assign counter = SW[17:16];
    wire [1:0] difficulty;
    assign difficulty = SW[15:14];
    wire reset;
    assign reset = SW[8];
    wire win;
    wire loss;
    maze_top my_maze(SW[13:0], KEY, CLOCK_50, counter, difficulty, reset, LEDG, LEDR, HEX0, HEX1, HEX2, HEX3, win, loss);
    
endmodule

module maze_top(
    input [13:0] answers,
    input [3:0] keys,
    input clk,
    input [1:0] counter,
    input [1:0] difficulty,
    input reset,
 
    output [7:0] out_ledg,
    output [17:0] out_ledr,
    output [6:0] out_HEX1,
    output [6:0] out_HEX2,
    output [6:0] out_HEX3,
    output reg [6:0] out_HEX4,
    output reg win, 
    output reg loss
);
    initial out_HEX4 = 7'b0100100;
    wire [3:0] path;
    assign path = answers[7:4];
    wire go;
    assign go = keys[3];
    reg [6:0] current_loc, next_loc; 
    reg [6:0] start_state, end_state;
     reg first;
    
     initial win = 1'b0;
    initial loss = 1'b0;
    reg randomize;
        reg [1:0] random_indicator;
    initial randomize = 1'b0;
	 
	 assign out_HEX2[0] = win;
	 assign out_HEX3[0] = loss;
	 assign out_ledr[17:11] = current_loc;
	 assign out_ledr[9:3] = next_loc;
     
    localparam  S_LOAD_A            = 5'd0,
                S_LOAD_A_WAIT       = 5'd1,
                     S_LOAD_B           = 5'd2,
                     S_LOAD_B_WAIT      = 5'd3;
    localparam S11 = 7'b0000001,
    S12 = 7'b0000010,
    S13 = 7'b0000011,
    S14 = 7'b0000100,
    S15 = 7'b0000101,
    S16 = 7'b0000110,
    S21 = 7'b0000111,
    S22 = 7'b0001000,
    S23 = 7'b0001001,
    S24 = 7'b0001010,
    S25 = 7'b0001011,
    S26 = 7'b0001100,
    S31 = 7'b0001101,
    S32 = 7'b0001110,
    S33 = 7'b0001111,
    S34 = 7'b0010000,
    S35 = 7'b0010001,
    S36 = 7'b0010010,
    S41 = 7'b0010011,
    S42 = 7'b0010100,
    S43 = 7'b0010101,
    S44 = 7'b0010110,
    S45 = 7'b0010111,
    S46 = 7'b0011000,
    S51 = 7'b0011001,
    S52 = 7'b0011010,
    S53 = 7'b0011011,
    S54 = 7'b0011100,
    S55 = 7'b0011101,
    S56 = 7'b0011110,
    S00 = 7'b0100001,
    RIGHT = 4'b0001,
    LEFT = 4'b0010,
    UP = 4'b1000,
    DOWN = 4'b0100,
    END = 4'b1111;
    
    initial first = 1'b1;
    always @ (*)
    begin
    // randomizer
        if (randomize == 1'b0) begin 
            random_indicator <= counter;    // random 2 bit number
            randomize <= 1;   
        end   
    end
    assign out_ledg[1:0] = counter;
    
	 always @(*)
    begin
	case (difficulty)
    2'b01: begin
        case (counter)
      2'b00:  begin
        start_state = S11;
        end_state = S14;
        end
		2'b01:  begin
        start_state = S15;
        end_state = S31;
        end
		2'b10:  begin
        start_state = S31;
        end_state = S14;
        end
		2'b11:  begin
        start_state = S35;
        end_state = S11;
        end 
		endcase
    end
	 
    2'b10: begin
    case(counter)
		2'b00:  begin
        start_state = S11;
        end_state = S45;
        end
		2'b01:  begin
        start_state = S15;
        end_state = S41;
        end
		2'b10:  begin
        start_state = S41;
        end_state = S15;
        end
		2'b11:  begin
        start_state = S45;
        end_state = S11;
        end
      endcase
    end
    
    2'b11: begin
    case(counter)
      2'b00:  begin
         start_state = S11;
        end_state = S56;
        end
      2'b01:  begin
        start_state = S16;
        end_state = S51;
        end
      2'b10:  begin
        start_state = S51;
        end_state = S16;
        end
      2'b11:  begin
        start_state = S56;
        end_state = S11;
        end
        endcase
    end
	 default: begin
			start_state = S11;
			end_state = S35;
	 end
endcase
     first = 1'b0;
     end 
	  
	  
    always@(path)
		
    begin: loc_table
    case(difficulty)
    2'b01: begin
        case (current_loc)
        S11:    begin
            case(path)
            RIGHT: next_loc = S12;
            default: next_loc = S00;
            endcase
        end
        S12:    begin
            case(path)
            RIGHT: next_loc = S13;
            LEFT: next_loc = S11;
            default: next_loc = S00;
            endcase
        end
        S13:    begin
            case(path)
            LEFT: next_loc = S12;
            DOWN: next_loc = S23;
            default: next_loc = S00;
            endcase
        end
        S14:    begin
            case(path)
            DOWN: next_loc = S24;
            default: next_loc = S00;
            endcase
        end
        S15:    begin
            case(path)
            DOWN: next_loc = S25;
            default: next_loc = S00;
            endcase
        end
        S21:    begin
            case(path)
            DOWN: next_loc = S31;
            RIGHT: next_loc = S22;
            default: next_loc = S00;
            endcase
        end
        S22:    begin
            case(path)
            DOWN: next_loc = S32;
            LEFT: next_loc = S21;
            RIGHT: next_loc = S23;
            default: next_loc = S00;
            endcase
        end
        S23:    begin
            case(path)
            LEFT: next_loc = S22;
            RIGHT: next_loc = S24;
            UP: next_loc = S13;
            default: next_loc = S00;
            endcase
        end
        S24:    begin
            case(path)
            LEFT: next_loc = S23;
            RIGHT: next_loc = S25;
            UP: next_loc = S14;
            default: next_loc = S00;
            endcase
        end
        S25:    begin
            case(path)
        UP: next_loc = S15;
            LEFT: next_loc = S24;
            default: next_loc = S00;
            endcase
        end 
        S31:    begin
            case(path)
            UP: next_loc = S21;
            default: next_loc = S00;
            endcase
        end
        S32:    begin
            case(path)
            UP: next_loc = S22;
            RIGHT:next_loc = S33;
            default: next_loc = S00;
            endcase
        end
        S33:    begin
            case(path)
            RIGHT: next_loc = S34;
            LEFT: next_loc = S32;
            default: next_loc = S00;
            endcase
        end
        S34:    begin
            case(path)
            LEFT: next_loc = S33;
            RIGHT: next_loc = S35;
            default: next_loc = S00;
            endcase
        end
        S35:    begin
            case(path)
            LEFT: next_loc = S34;
            default: next_loc = S00;
            endcase
        end
        S00: begin
            case(path)
            default: next_loc = S00;
            endcase
        end
        default: begin
            next_loc = start_state;
        end
    endcase
    end
    2'b10: begin
        case(current_loc)
    S11:    begin
            case(path)
            RIGHT: next_loc = S12;
            default: next_loc = S00;
            endcase
        end
    S12:    begin
            case(path)
            RIGHT: next_loc = S13;
            LEFT: next_loc = S11;
            DOWN: next_loc = S22;
            default: next_loc = S00;
            endcase
        end
    S13:    begin
            case(path)
            LEFT: next_loc = S12;
            default: next_loc = S00;
            endcase
        end
    S14:    begin
            case(path)
            DOWN: next_loc = S24;
            default: next_loc = S00;
            endcase
        end
    S15:    begin
            case(path)
            DOWN: next_loc = S25;
            default: next_loc = S00;
            endcase
        end
    S21:    begin
            case(path)
            DOWN: next_loc = S31;
            default: next_loc = S00;
            endcase
        end
    S22:    begin
            case(path)
            UP: next_loc = S12;
            DOWN: next_loc = S32;
            default: next_loc = S00;
            endcase
        end
    S23:    begin
            case(path)
            RIGHT: next_loc = S24;
            DOWN: next_loc = S33;
            default: next_loc = S00;
            endcase
        end
    S24:    begin
            case(path)
            LEFT: next_loc = S23;
            UP: next_loc = S14;
            default: next_loc = S00;
            endcase
        end
    S25:    begin
            case(path)
            UP: next_loc = S15;
            DOWN: next_loc = S35;
            default: next_loc = S00;
            endcase
        end
    S31:    begin
            case(path)
            RIGHT: next_loc = S32;
            UP: next_loc = S21;
            DOWN: next_loc = S41;
            default: next_loc = S00;
            endcase
        end
    S32:    begin
            case(path)
            LEFT: next_loc = S31;
            UP: next_loc = S22;
            DOWN: next_loc = S42;
            default: next_loc = S00;
            endcase
        end
    S33:    begin
            case(path)
            RIGHT: next_loc = S34;
            UP: next_loc = S23;
            DOWN: next_loc = S43;
            default: next_loc = S00;
            endcase
        end
    S34:    begin
            case(path)
            LEFT: next_loc = S33;
			RIGHT: next_loc = S35;
            default: next_loc = S00;
            endcase
        end
    S35:    begin
            case(path)
            LEFT: next_loc = S34;
            UP: next_loc = S25;
            default: next_loc = S00;
            endcase
        end
    S41:    begin
            case(path)
            UP: next_loc = S31;
            default: next_loc = S00;
            endcase
        end
    S42:    begin
            case(path)
            UP: next_loc = S32;
            RIGHT: next_loc = S43;
            default: next_loc = S00;
            endcase
        end
    S43:    begin
            case(path)
            LEFT: next_loc = S42;
            RIGHT: next_loc = S44;
            UP: next_loc = S33;
            default: next_loc = S00;
            endcase
        end
    S44:    begin
            case(path)
            LEFT: next_loc = S43;
            RIGHT: next_loc = S45;
            default: next_loc = S00;
            endcase
        end
    S45:    begin
            case(path)
            LEFT: next_loc = S44;
            default: next_loc = S00;
            endcase
        end
	 default: begin
				next_loc = start_state;
	 end
    endcase
    end
    2'b11: begin
        case(current_loc)
    S11:    begin
            case(path)
            RIGHT: next_loc = S12;
            default: next_loc = S00;
            endcase
        end
    S12:    begin
            case(path)
            RIGHT: next_loc = S13;
            LEFT: next_loc = S11;
            DOWN: next_loc = S22;
            default: next_loc = S00;
            endcase
        end
    S13:    begin
            case(path)
            LEFT: next_loc = S12;
            default: next_loc = S00;
            endcase
        end
    S14:    begin
            case(path)
            DOWN: next_loc = S24;
            default: next_loc = S00;
            endcase
        end
    S15:    begin
            case(path)
            DOWN: next_loc = S25;
            RIGHT: next_loc = S16;
            default: next_loc = S00;
            endcase
        end
    S16:    begin
            case(path)
            LEFT: next_loc = S15;
            default: next_loc = S00;
            endcase
        end
    S21:    begin
            case(path)
            DOWN: next_loc = S31;
            default: next_loc = S00;
            endcase
        end
    S22:    begin
            case(path)
            UP: next_loc = 12;
            DOWN: next_loc = S32;
            default: next_loc = S00;
            endcase
        end
    S23:    begin
            case(path)
            RIGHT: next_loc = S24;
            DOWN: next_loc = S33;
            default: next_loc = S00;
            endcase
        end
    S24:    begin
            case(path)
            LEFT: next_loc = S23;
            UP: next_loc = S14;
            default: next_loc = S00;
            endcase
        end
    S25:    begin
            case(path)
            UP: next_loc = S15;
            DOWN: next_loc = S35;
            RIGHT: next_loc = S26;
            default: next_loc = S00;
            endcase
        end
    S26:    begin
            case(path)
            DOWN: next_loc = S36;
            LEFT: next_loc = S25;
            default: next_loc = S00;
            endcase
        end
    S31:    begin
            case(path)
            RIGHT: next_loc = S32;
            UP: next_loc = S21;
            DOWN: next_loc = S41;
            default: next_loc = S00;
            endcase
        end
    S32:    begin
            case(path)
            LEFT: next_loc = S31;
            UP: next_loc = S22;
            DOWN: next_loc = S42;
            default: next_loc = S00;
            endcase
        end
    S33:    begin
            case(path)
            RIGHT: next_loc = S34;
            UP: next_loc = S23;
            DOWN: next_loc = S43;
            default: next_loc = S00;
            endcase
        end
    S34:    begin
            case(path)
            LEFT: next_loc = S33;
            RIGHT: next_loc = S35;
            default: next_loc = S00;
            endcase
        end
    S35:    begin
            case(path)
            LEFT: next_loc = S34;
            UP: next_loc = S25;
            DOWN: next_loc = S45;
            default: next_loc = S00;
            endcase
        end
    S36:    begin
            case(path)
            UP: next_loc = S26;
            DOWN: next_loc = S46;
            default: next_loc = S00;
            endcase
        end
    S41:    begin
            case(path)
            UP: next_loc = S31;
            default: next_loc = S00;
            endcase
        end
    S42:    begin
            case(path)
            UP: next_loc = S32;
            RIGHT: next_loc = S43;
            default: next_loc = S00;
            endcase
        end
    S43:    begin
            case(path)
            LEFT: next_loc = S42;
            RIGHT: next_loc = S44;
            UP: next_loc = S33;
            default: next_loc = S00;
            endcase
        end
    S44:    begin
            case(path)
            LEFT: next_loc = S43;
            DOWN: next_loc = S54;
            default: next_loc = S00;
            endcase
        end
    S45:    begin
            case(path)
            UP: next_loc = S35;
            default: next_loc = S00;
            endcase
        end
    S46:    begin
            case(path)
            UP: next_loc = S36;
            DOWN: next_loc = S56;
            default: next_loc = S00;
            endcase
        end
    S51:    begin
            case(path)
            RIGHT: next_loc = S52;
            default: next_loc = S00;
            endcase
        end
    S52:    begin
            case(path)
            LEFT: next_loc = S53;
            RIGHT: next_loc = S51;
            default: next_loc = S00;
            endcase
        end
    S53:    begin
            case(path)
            LEFT: next_loc = S52;
            RIGHT: next_loc = S54;
            default: next_loc = S00;
            endcase
        end
    S54:    begin
            case(path)
            RIGHT: next_loc = S55;
            LEFT: next_loc = S53;
            UP: next_loc = S44;
            default: next_loc = S00;
            endcase
        end
    S55:    begin
            case(path)
            LEFT: next_loc = S54;
            default: next_loc = S00;
            endcase
        end
    S56:    begin
            case(path)
            UP: next_loc = S46;
            default: next_loc = S00;
            endcase
        end
	 default: begin
				next_loc = start_state;
	 end
    endcase
    end
	 default: begin
				next_loc = end_state;
	 end
	 endcase
	 if (reset == 1'b1) begin
			next_loc = start_state;
	 end
    end
    initial current_loc = start_state;
    initial next_loc = start_state;
        
	always@(negedge go)
	begin: state_FFs
        if (reset == 1'b1)
        begin
            win <= 1'b0;
            loss <= 1'b0;
        
            current_loc <= start_state;
        end
        else begin 
            if (current_loc == end_state && path == END)
            begin
                win <= 1'b1;
            end
            else if (current_loc == S00 /*&& current_state == S_LOAD_A*/)
            begin   
                loss <= 1'b1;
            end
            else /*if (current_state == S_LOAD_A)*/
            begin
                current_loc <= next_loc;
            end
        end
	end
endmodule


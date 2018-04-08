
module morse_hard (SW, KEY, CLOCK_50, LEDR, LEDG, HEX3);

	input [17:0] SW;
	input [3:0] KEY;
	input CLOCK_50;
	output [17:0] LEDR;
	output [7:0]LEDG;
	output [6:0] HEX3;
	assign HEX3 = 7'b1111001;
	
	hard_morse morse_e(SW[16:0], KEY[3:0], CLOCK_50, SW[17], LEDR, LEDG[0], LEDG[5]);
	
	/*always @(difficulty[1:0])
	begin
		case(difficulty[1:0])
			// connect wires to easy morse
			2'b00: easy_morse morse_e(switches, keyselects, clk, reset, redLEDs, win, lose);
			// connect wires to medium morse
			2'b01: begin
						medium_morse morse_m(switches, keyselects, clk, reset, redLEDs, win, lose);
					 end
			// connect to hard morse
			2'b10:
			
			// connect to easy morse
			default: 
		endcase
	end
	*/
endmodule


// realistically don't need counter, difficulty, greenLEDs, hex1-4
module hard_morse (switches, keyselects, clk, reset, redLEDs, win, lose);
	// switches[2:0] are used to select letter
	// switch 3 is used as the key
	// switch 4 is used as enable for ratedivider
	// switch 5 is used as reset
	// changing all these from specifics to generics
	/* 
	input [6:0] SW;
	input CLOCK_50;
	input [3:0] KEY;
	output [5:0] LEDR;
	output [5:0] LEDG;
	*/
	
	
	input [17:0] switches;
	input clk;
	input [3:0] keyselects;
	input reset;
	output [17:0] redLEDs;
	output reg win, lose;
	
	wire [27:0] counteroutput;
	reg registerclock;
	wire [14:0] lettervalue;
	wire [14:0] lettervalue2;
	wire LEDin;
	wire LEDin2;
	
	integer randomletter;
	reg [4:0] letterinputBIN;
	reg [4:0] letterinputBIN2;
	always @(negedge keyselects[3])
	begin
		letterinputBIN <= (counteroutput * 13) % 27;
		letterinputBIN2 <= (counteroutput * 7) % 27;

		// would assigning another registe
	end
	/*
	reg [5:0] winorlose;
	initial winorlose = 5'b00000;
	assign LEDG[5:0] = winorlose;
	*/
	always @(clk)
	begin
		if (reset)
		begin
			win <= 1'b0;
			lose <= 1'b0;
		end
		
		else if (!keyselects[0])
		begin
			case(switches[4:0])
				letterinputBIN: begin
										case(switches[9:5])
											letterinputBIN2: 
											begin
												win <= 1'b1;
												lose <= 1'b0;
											end
											
											default:
											begin
												win <= 1'b0;
												lose <= 1'b1;
											end
										endcase
									 end
				
				default: begin
								win <= 1'b0;
								lose <= 1'b1;
							end
			endcase
		end
		/*
		else
		begin
			win <= 1'b0;
			lose <= 1'b0;
		end
		*/
	end
	
	lookuptablehard LUT(.IN(letterinputBIN), .OUT(lettervalue));
	lookuptablehard LUT2(.IN(letterinputBIN2), .OUT(lettervalue2));
	
	// create reg to make the below happen once
	/*
	reg randomize;
	reg answer;
	initial randomize = 1'b1;
	always @(posedge KEY[3])
	begin
		if (randomize == 1)
		begin
			answer <= letterinputBIN;
			randomize <= 0;
		end
	end
	*/
	
	//value for rate divider is 25 million -1
	//50 million cycles a second, 25 million for half second
	
	//ratedivider(.clock(CLOCK_50), .outvalue(counteroutput), .invalue(28'b0001011111010111100000111111), .clear(SW[5]), .enable(SW[4]));
	/* THE ABOVE LINE WAS WORKING WITH SWITCHES, SWITCHES HAVE BEEN CHANGED TO VALUES IN THE BOTTOM LINE!!
	*/
	ratedivider timing(.clock(clk), .outvalue(counteroutput), .invalue(28'b0001011111010111100000111111), .clear(1'b1), .enable(switches[16]));

	
	always @(*)
	begin
		if (counteroutput == 28'b0000000000000000000000000000)
			registerclock <= 1;
		else
			registerclock <= 0;
	end
	
	// register shifter(.out(LEDin), .in(1'b0), .load_val(lettervalue), .load_n(KEY[3]), .shift(1'b1), .clk(registerclock), .reset(SW[5]));
	/*
	// THE ABOVE LINE WAS WORKING WITH SWITCHES, SWITCHES HAVE BEEN CHANGED TO VALUES IN THE BOTTOM LINE!!!!!!!!
	*/
	wire alwayson;
	assign alwayson = 1'b1;
	// changed load from KEY3 to KEY2
	registerhard shifter(.out(LEDin), .in(1'b0), .load_val(lettervalue), .load_n(keyselects[2]), .shift(1'b1), .clk(registerclock), .reset(alwayson));
	registerhard shifter2(.out(LEDin2), .in(1'b0), .load_val(lettervalue2), .load_n(keyselects[2]), .shift(1'b1), .clk(registerclock), .reset(alwayson));

	
	assign redLEDs[0] = LEDin;
	assign redLEDs[1] = LEDin2;
//	assign redLEDs[2] = win;
//	assign redLEDs[3] = lose;
endmodule



module lookuptablehard(IN, OUT);
	input [4:0] IN;
	output reg [14:0] OUT;
	
	always @(IN[4:0])
	begin
		case(IN[4:0])
			5'b00000: OUT = 15'b000000000111010; //A
			5'b00001: OUT = 15'b000001010101110; //B
			5'b00010: OUT = 15'b000101110101110; //C
			5'b00011: OUT = 15'b000000010101110; //D
			5'b00100: OUT = 15'b000000000000010; //E
			5'b00101: OUT = 15'b000001011101010; //F
			5'b00110: OUT = 15'b000001011101110; //G
			5'b00111: OUT = 15'b000000010101010; //H
			5'b01000: OUT = 15'b000000000001010; //I
			5'b01001: OUT = 15'b011101110111010; //J
			5'b01010: OUT = 15'b000001110101110; //K
			5'b01011: OUT = 15'b000001010111010; //L
			5'b01100: OUT = 15'b000000011101110; //M
			5'b01101: OUT = 15'b000000000101110; //N
			5'b01110: OUT = 15'b000111011101110; //O
			5'b01111: OUT = 15'b000101110111010; //P
			5'b10000: OUT = 15'b011101011101110; //Q
			5'b10001: OUT = 15'b000000010111010; //R
			5'b10010: OUT = 15'b000000000101010; //S
			5'b10011: OUT = 15'b000000000001110; //T
			5'b10100: OUT = 15'b000000011101010; //U
			5'b10101: OUT = 15'b000001110101010; //V
			5'b10110: OUT = 15'b000001110111010; //W
			5'b10111: OUT = 15'b000111010101110; //X
			5'b11000: OUT = 15'b011101110101110; //Y
			5'b11001: OUT = 15'b000101011101110; //Z

			default: OUT = 15'b000000000111010;
		endcase
	end
endmodule



module registerhard(out, in, load_val, load_n, shift, clk, reset);
	input [14:0] load_val;
	input in, load_n, shift, clk, reset;
	output out;
	wire[14:0] sOut;
	// make output equal to sOut[0]
	// don't forget to flip the morse code around 
	// ie A is 12'b000000011101 instead of 12'b101110000000
	assign out = sOut[0];

	shifterbit shift14(.out(sOut[14]), .in(in), .load_val(load_val[14]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift13(.out(sOut[13]), .in(sOut[14]), .load_val(load_val[13]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift12(.out(sOut[12]), .in(sOut[13]), .load_val(load_val[12]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));	
	shifterbit shift11(.out(sOut[11]), .in(sOut[12]), .load_val(load_val[11]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift10(.out(sOut[10]), .in(sOut[11]), .load_val(load_val[10]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift9(.out(sOut[9]), .in(sOut[10]), .load_val(load_val[9]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift8(.out(sOut[8]), .in(sOut[9]), .load_val(load_val[8]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift7(.out(sOut[7]), .in(sOut[8]), .load_val(load_val[7]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift6(.out(sOut[6]), .in(sOut[7]), .load_val(load_val[6]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift5(.out(sOut[5]), .in(sOut[6]), .load_val(load_val[5]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift4(.out(sOut[4]), .in(sOut[5]), .load_val(load_val[4]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift3(.out(sOut[3]), .in(sOut[4]), .load_val(load_val[3]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift2(.out(sOut[2]), .in(sOut[3]), .load_val(load_val[2]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift1(.out(sOut[1]), .in(sOut[2]), .load_val(load_val[1]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	shifterbit shift0(.out(sOut[0]), .in(sOut[1]), .load_val(load_val[0]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));
	
	
endmodule


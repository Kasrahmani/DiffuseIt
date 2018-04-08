module morse_hhard(CLOCK_50, LEDR, LEDG, SW, KEY,);
	// switches[2:0] are used to select letter
	// switch 3 is used as the key
	// switch 4 is used as enable for ratedivider
	// switch 5 is used as reset
	// changing all these from specifics to generics
	 
	input [17:0] SW;
	input CLOCK_50;
	input [3:0] KEY;
	output [5:0] LEDR;
	output [5:0] LEDG;
	
	/*
	input [17:0] switches;
	input clk;
	input [3:0] keyselects;
	input reset;
	output [17:0] redLEDs;
	output reg win, lose;
	*/
	wire [27:0] counteroutput;
	reg registerclock;
	wire [12:0] lettervalue;
	wire [12:0] lettervalue2;
	wire LEDin1;
	wire LEDin2;
	
	integer randomletter;
	reg [2:0] letterinputBIN;
	reg [2:0] letterinputBIN2;
	always @(negedge KEY[3])
	begin
		letterinputBIN <= (counteroutput * 13) % 8;
		letterinputBIN2 <= (counteroutput * 7) % 8;
		// would assigning another registe
	end
	
	reg [5:0] winorlose;
	initial winorlose = 5'b00000;
	assign LEDG[5:0] = winorlose;
	
	always @(CLOCK_50)
	begin
		if(!KEY[0])
		begin
			case(SW[2:0])
				letterinputBIN: begin 
										if (SW[17:15] == letterinputBIN2) winorlose <= 5'b00001;
										else winorlose <= 5'b10000;
									 end
				
				default: winorlose <= 5'b10000;
			endcase
		end
		
		else
		begin
			winorlose <= 5'b00000;
		end
	end
	
	lookuptable LUT(.IN(letterinputBIN), .OUT(lettervalue));
	lookuptable LUT2(.IN(letterinputBIN2), .OUT(lettervalue2));
	
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
	ratedivider(.clock(CLOCK_50), .outvalue(counteroutput), .invalue(28'b0001011111010111100000111111), .clear(1'b1), .enable(SW[12]));

	
	always @(*)
	begin
		if (counteroutput == 28'b0000000000000000000000000000)
			registerclock <= 1;
		else
			registerclock <= 0;
	end
	
	// register shifter(.out(LEDin1), .in(1'b0), .load_val(lettervalue), .load_n(KEY[3]), .shift(1'b1), .clk(registerclock), .reset(SW[5]));
	/*
	// THE ABOVE LINE WAS WORKING WITH SWITCHES, SWITCHES HAVE BEEN CHANGED TO VALUES IN THE BOTTOM LINE!!!!!!!!
	*/
	wire alwayson;
	assign alwayson = 1'b1;
	// changed load from KEY3 to KEY2
	register shifter(.out(LEDin1), .in(1'b0), .load_val(lettervalue), .load_n(KEY[2]), .shift(1'b1), .clk(registerclock), .reset(alwayson));
	register shifter2(.out(LEDin2), .in(1'b0), .load_val(lettervalue2), .load_n(KEY[2]), .shift(1'b1), .clk(registerclock), .reset(alwayson));
	
	assign LEDR[0] = LEDin1;
	assign LEDR[1] = LEDin2;
endmodule


module lookuptable(IN, OUT);
	input [2:0] IN;
	output reg [12:0] OUT;
	
	always @(IN[2:0])
	begin
		case(IN[2:0])
			3'b000: OUT = 13'b0000000111010;
			3'b001: OUT = 13'b0001010101110;
			3'b010: OUT = 13'b0101110101110;
			3'b011: OUT = 13'b0000010101110;
			3'b100: OUT = 13'b0000000000010;
			3'b101: OUT = 13'b0001011101010;
			3'b110: OUT = 13'b0001011101110;
			3'b111: OUT = 13'b0000010101010;
			
			default: OUT = 13'b0000000111010;
		endcase
	end
endmodule


module ratedivider(clock, outvalue, invalue, clear, enable);
	input [27:0] invalue;
	input clear, enable, clock;
	output reg [27:0] outvalue;
	
	always @(posedge clock)
	begin
		if (clear == 1'b0)
			outvalue <= 0;
		else if (outvalue == 28'b0000000000000000000000000000)
			outvalue <= invalue;
		else if (enable == 1'b1)
			outvalue <= outvalue - 1;
	end
endmodule


module register(out, in, load_val, load_n, shift, clk, reset);
	input [12:0] load_val;
	input in, load_n, shift, clk, reset;
	output out;
	wire[12:0] sOut;
	// make output equal to sOut[0]
	// don't forget to flip the morse code around 
	// ie A is 12'b000000011101 instead of 12'b101110000000
	assign out = sOut[0];
	
	shifterbit shift12(.out(sOut[12]), .in(in), .load_val(load_val[12]), .load_n(load_n), .shift(shift), .clk(clk), .reset(reset));	
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

module mux2to1(x, y, s, m);
    input x; //selected when s is 0
    input y; //selected when s is 1
    input s; //select signal
    output m; //output
  
    assign m = s & y | ~s & x;
    // OR
    // assign m = s ? y : x;

endmodule

module flipflop(q, d, clock, reset_n);
	input d;
	input clock, reset_n;
	output reg q;
	
	always @(posedge clock)
	begin
		if(reset_n == 1'b0)
			q <=0;
		else
			q <=d;
	end
endmodule

module shifterbit(out, in, load_val, load_n, shift, clk, reset);
	input clk, in, reset, load_n, shift, reset, load_val;
	output out;
	wire data_to_mux1, data_to_dff;
	
	mux2to1 mux0(.x(out), .y(in), .s(shift), .m(data_to_mux1));
	mux2to1 mux1(.x(load_val), .y(data_to_mux1), .s(load_n), .m(data_to_dff));
	
	flipflop F0(.d(data_to_dff), .q(out), .clock(clk), .reset_n(reset));
endmodule
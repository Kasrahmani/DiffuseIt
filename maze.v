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
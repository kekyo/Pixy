module Core(
//	input STEP,
	input STEPEN,
	output SRAMCS0,
	output SRAMCS1,
	output PROMCS0,
	output PROMCS1,
	output RUN
);

wire STEPEN;
wire SRAMCS0;
wire SRAMCS1;
wire PROMCS0;
wire PROMCS1;
wire RUN;

assign SRAMCS0 = 1'h1;
assign SRAMCS1 = 1'h1;
assign PROMCS0 = 1'h1;
assign PROMCS1 = 1'h1;
assign RUN = STEPEN;


//wire IA;
//wire IB;
//assign IA = IN_A & ~IN_B;
//assign IB = ~IN_A & IN_B;
//assign O = IA | IB;

endmodule
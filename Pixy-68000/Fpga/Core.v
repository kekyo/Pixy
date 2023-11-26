module Core(
	input STEPEN,
	output SRAMCS0,
	output SRAMCS1,
	output PROMCS0,
	output PROMCS1,
	output RUN
);

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
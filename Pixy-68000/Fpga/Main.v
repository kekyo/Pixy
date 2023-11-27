module Main(
	input MCLK,
	input AS,
	input UDS,
	input LDS,
	output SRAMCS0,
	output SRAMCS1,
	output PROMCS0,
	output PROMCS1,
	output OE,
	output CPUCLK,
	output RUN,
	output RESET,
	output HALT,
	output IPL0,
	output IPL1,
	output IPL2,
	output AVEC,
	output BR,
	output DTACK,
	output BERR
);

wire TEMP;

ClockDivider CD(
	.CLK_IN(MCLK),
	.CLK_OUT(CPUCLK));
	
BusControl BC(
	.CPUCLK_IN(CPUCLK),
	.RESET(RESET),
	.HALT(HALT));
	
Core C(
	.SRAMCS0(SRAMCS0),
	.SRAMCS1(SRAMCS1),
	.PROMCS0(PROMCS0),
	.PROMCS1(PROMCS1));
	
assign IPL0 = 'd1;
assign IPL1 = 'd1;
assign IPL2 = 'd1;
assign AVEC = 'd1;
assign BR = 'd1;
assign OE = 'd1;

assign DTACK = ~(~AS & (~UDS | ~LDS));
//assign DTACK = 'd1;

assign BERR = 'd1;

endmodule

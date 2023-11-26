module Main(
	input MCLK,
	input STEPEN,
	output SRAMCS0,
	output SRAMCS1,
	output PROMCS0,
	output PROMCS1,
	output CPUCLK,
	output RUN
);

ClockDivider Clock(
	.MCLK(MCLK),
	.CPUCLK(CPUCLK));
	
Core C(
	.STEPEN(STEPEN),
	.SRAMCS0(SRAMCS0),
	.SRAMCS1(SRAMCS1),
	.PROMCS0(PROMCS0),
	.PROMCS1(PROMCS1),
	.RUN(RUN));

endmodule

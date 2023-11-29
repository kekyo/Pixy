module Main(
	input MCLK,
	input AS_n,
	input UDS_n,
	input LDS_n,
	output CPUCLK,
	output RUN,
	output RESET_n,
	output HALT_n,
	output IPL0_n,
	output IPL1_n,
	output IPL2_n,
	output AVEC_n,
	output BR_n,
	output DTACK_n,
	output BERR_n,
	output SRAMCS0_n,
	output SRAMCS1_n,
	output PROMCS0_n,
	output PROMCS1_n,
	output OE_n
);

wire AS = ~AS_n;
wire LDS = ~LDS_n;
wire UDS = ~UDS_n;
wire RESET;
wire HALT;
wire DTACK;
wire BERR;
wire BR;
wire IPL0;
wire IPL1;
wire IPL2;
wire AVEC;
wire SRAMCS0;
wire SRAMCS1;
wire PROMCS0;
wire PROMCS1;
wire OE;

ClockDivider CD(
	.CLK_IN(MCLK),
	.CLK_OUT(CPUCLK));
	
BusControl BC(
	.CPUCLK_IN(CPUCLK),
	.RESET(RESET),
	.HALT(HALT));

assign DTACK = AS & (UDS | LDS);

assign BERR = 0;
assign BR = 0;
assign IPL0 = 0;
assign IPL1 = 0;
assign IPL2 = 0;
assign AVEC = 0;
assign SRAMCS0 = 0;
assign SRAMCS1 = 0;
assign PROMCS0 = 0;
assign PROMCS1 = 0;
assign OE = 0;

assign RESET_n = ~RESET;
assign HALT_n = ~HALT;
assign DTACK_n = ~DTACK;
assign BERR_n = ~BERR;
assign BR_n = ~BR;
assign IPL0_n = ~IPL0;
assign IPL1_n = ~IPL1;
assign IPL2_n = ~IPL2;
assign AVEC_n = ~AVEC;
assign SRAMCS0_n = ~SRAMCS0;
assign SRAMCS1_n = ~SRAMCS1;
assign PROMCS0_n = ~PROMCS0;
assign PROMCS1_n = ~PROMCS0;
assign OE_n = ~OE;

endmodule

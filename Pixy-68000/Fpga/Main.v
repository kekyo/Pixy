module Main(
	input MCLK,
	input AS_n,
	input UDS_n,
	input LDS_n,
	input SPICLK,
	input SPISS_n,
	input STEPEN_n,
	input STEP_n,
	input A0, input A1, input A2, input A3,
	input A4, input A5, input A6, input A7,
	input A8, input A9, input A10, input A11,
	input A12, input A13, input A14, input A15,
	input A16, input A17, input A18, input A19,
	input A20, input A21, input A22, input A23,
	input D0, input D1, input D2, input D3,
	input D4, input D5, input D6, input D7,
	input D8, input D9, input D10, input D11,
	input D12, input D13, input D14, input D15,
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
	output OE_n,
	output SPISO
);

wire SPISS = ~SPISS_n;
wire AS = ~AS_n;
wire UDS = ~UDS_n;
wire LDS = ~LDS_n;
wire STEPEN = ~STEPEN_n;
wire STEP = ~STEP_n;
wire [23:0] ADDR = { A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23 };
wire [15:0] DATA = { D0, D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15 };
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
	.STEPEN_IN(STEPEN),
	.STEP_IN(STEP),
	.AS_IN(AS),
	.UDS_IN(UDS),
	.LDS_IN(LDS),
	.RESET(RESET),
	.HALT(HALT),
	.RUN(RUN),
	.DTACK(DTACK));
	
Monitor M(
	.SPICLK_IN(SPICLK),
	.SPISS_IN(SPISS),
	.ADDR_IN(ADDR),
	.DATA_IN(DATA),
	.SPISO(SPISO));

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

assign DTACK_n = ~DTACK;
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

module Main(
	input MCLK,
	input AS_n,
	input RW,
	input UDS_n,
	input LDS_n,
	input SPICLK,
	input SPISS_n,
	input SPISI,
	input STEPEN_n,
	input STEP_n,
	input FC0, input FC1, input FC2,
	input A0, input A1, input A2, input A3,
	input A4, input A5, input A6, input A7,
	input A8, input A9, input A10, input A11,
	input A12, input A13, input A14, input A15,
	input A16, input A17, input A18, input A19,
	input A20, input A21, input A22, input A23,
	inout D0, inout D1, inout D2, inout D3,
	inout D4, inout D5, inout D6, inout D7,
	inout D8, inout D9, inout D10, inout D11,
	inout D12, inout D13, inout D14, inout D15,
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
	output PROMCS0_n,
	output PROMCS1_n,
	output SRAMCS0_n,
	output SRAMCS1_n,
	output OE_n,
	output SPISO
);

wire SPISS = ~SPISS_n;
wire AS = ~AS_n;
wire UDS = ~UDS_n;
wire LDS = ~LDS_n;
wire WR = ~RW;
wire STEPEN = ~STEPEN_n;
wire STEP = ~STEP_n;
wire [2:0] FC = { FC2, FC1, FC0 };
wire [23:0] ADDR = { A23, A22, A21, A20, A19, A18, A17, A16, A15, A14, A13, A12, A11, A10, A9, A8, A7, A6, A5, A4, A3, A2, A1, A0 };
wire [15:0] DATA = { D15, D14, D13, D12, D11, D10, D9, D8, D7, D6, D5, D4, D3, D2, D1, D0 };
wire RESET;
wire HALT;
wire DTACK;
wire BERR;
wire BR;
wire [2:0] IPL;
wire AVEC;
wire PROMCS0;
wire PROMCS1;
wire SRAMCS0;
wire SRAMCS1;
wire OE;
wire [3:0] OUTPUT_SIGNAL;
wire [3:0] INPUT_SIGNAL;
wire UART_SEND_TRIGGER;
wire [7:0] UART_SEND_BYTE;
wire UART_SEND_BUSY;
wire UART_RECEIVED;
wire [7:0] UART_RECEIVE_BYTE;
wire UART_RECEIVE_CAPTURE;

ClockDivider CD(
	.MCLK_IN(MCLK),
	.CPUCLK(CPUCLK));
	
Reset R(
	.MCLK_IN(MCLK),
	.RESET(RESET),
	.HALT(HALT),
	.RUN(RUN));

BusControl BC(
	.MCLK_IN(MCLK),
	.CPUCLK_IN(CPUCLK),
	.STEPEN_IN(STEPEN),
	.STEP_IN(STEP),
	.RUN_IN(RUN),
	.AS_IN(AS),
	.WR_IN(WR),
	.UDS_IN(UDS),
	.LDS_IN(LDS),
	.STATUS_CODE_IN(FC),
	.INPUT_SIGNAL_IN(INPUT_SIGNAL),
	.UART_SEND_BUSY_IN(UART_SEND_BUSY),
	.UART_RECEIVED_IN(UART_RECEIVED),
	.UART_RECEIVE_BYTE_IN(UART_RECEIVE_BYTE),
	.ADDR_IN(ADDR),
	.DATA(DATA),
	.DATA_ACK(DTACK),
	.INT_AUTOVEC_ACK(AVEC),
	.BUS_ERROR(BERR),
	.INT_LEVEL(IPL),
	.PROM_CS0(PROMCS0),
	.PROM_CS1(PROMCS1),
	.SRAM_CS0(SRAMCS0),
	.SRAM_CS1(SRAMCS1),
	.OUTPUT_ENABLE(OE),
	.OUTPUT_SIGNAL(OUTPUT_SIGNAL),
	.UART_SEND_TRIGGER(UART_SEND_TRIGGER),
	.UART_SEND_BYTE(UART_SEND_BYTE),
	.UART_RECEIVE_CAPTURE(UART_RECEIVE_CAPTURE));
	
Monitor M(
	.MCLK_IN(MCLK),
	.RUN_IN(RUN),
	.SPICLK_IN(SPICLK),
	.SPISS_IN(SPISS),
	.SPISI_IN(SPISI),
	.ADDR_IN(ADDR),
	.DATA_IN(DATA),
	.OUTPUT_SIGNAL_IN(OUTPUT_SIGNAL),
	.UART_SEND_TRIGGER_IN(UART_SEND_TRIGGER),
	.UART_SEND_BYTE_IN(UART_SEND_BYTE),
	.UART_RECEIVE_CAPTURE_IN(UART_RECEIVE_CAPTURE),
	.INPUT_SIGNAL(INPUT_SIGNAL),
	.SPISO(SPISO),
	.UART_SEND_BUSY(UART_SEND_BUSY),
	.UART_RECEIVED(UART_RECEIVED),
	.UART_RECEIVE_BYTE(UART_RECEIVE_BYTE));

assign BR = 0;

assign DTACK_n = ~DTACK;
assign RESET_n = ~RESET;
assign HALT_n = ~HALT;
assign DTACK_n = ~DTACK;
assign BERR_n = ~BERR;
assign BR_n = ~BR;
assign IPL0_n = ~IPL[0];
assign IPL1_n = ~IPL[1];
assign IPL2_n = ~IPL[2];
assign AVEC_n = ~AVEC;
assign SRAMCS0_n = ~SRAMCS0;
assign SRAMCS1_n = ~SRAMCS1;
assign PROMCS0_n = ~PROMCS0;
assign PROMCS1_n = ~PROMCS1;
assign OE_n = ~OE;

endmodule

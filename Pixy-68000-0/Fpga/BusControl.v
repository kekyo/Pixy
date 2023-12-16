module BusControl(
	input MCLK_IN,
	input STEPEN_IN,
	input STEP_IN,
	input RUN_IN,
	input AS_IN,
	input WR_IN,
	input UDS_IN,
	input LDS_IN,
	input [3:0] INPUT_SIGNAL_IN,
	input [23:0] ADDR_IN,
	inout [15:0] DATA,
	output reg DTACK,
	output PROMCS0,
	output PROMCS1,
	output SRAMCS0,
	output SRAMCS1,
	output OE,
	output reg [3:0] OUTPUT_SIGNAL);

////////////////////////////////////////////////////

// Bootstrap read from PROM area.
reg BOOTSTRAPPED;

////////////////////////////////////////////////////

// Booting Read                  Write
// +---------------+            +---------------+
// |               | 0x00ffffff |               |
// | PROM (Flash)  |            | PROM (Flash)  |
// |               | 0x00f00000 |               |
// +---------------+            +---------------+
// |   (nothing)   |            |   (nothing)   | 
// +---------------+            +---------------+
// |   I/O         | 0x00100001 |   I/O         | 
// +---------------+            +---------------+
// |               | 0x000fffff |               |
// | PROM (Flash)  |            | SRAM          |
// |               | 0x00000000 |               |
// +---------------+            +---------------+

// Booted Read/Write
// +---------------+
// |               | 0x00ffffff
// | PROM (Flash)  |
// |               | 0x00f00000
// +---------------+
// |   (nothing)   |
// +---------------+
// |   I/O         | 0x00100001
// +---------------+
// |               | 0x000fffff
// | SRAM          |
// |               | 0x00000000
// +---------------+

// Address decoder.
wire ADDRLOWER = ADDR_IN[23:20] == 4'b0000;
wire ADDRIO = ADDR_IN[23:20] == 4'b0001;
wire ADDRUPPER = ADDR_IN[23:20] == 4'b1111;

wire WRBOOTSTRAPPED = WR_IN | BOOTSTRAPPED;
wire PROMCS = ADDRUPPER | (~WRBOOTSTRAPPED & ADDRLOWER);
wire SRAMCS = WRBOOTSTRAPPED & ADDRLOWER;

////////////////////////////////////////////////////

// Address request signal.
wire ASREQ = RUN_IN & AS_IN;

// Data request signal.
wire DTREQ = RUN_IN & AS_IN & (UDS_IN | LDS_IN);

// Write data request in lower area.
wire WRLOWERREQ = DTREQ & WR_IN;

// Exit from bootstrap mode.
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		BOOTSTRAPPED <= 1'b0;
	end else if (WRLOWERREQ & ADDRLOWER) begin
		BOOTSTRAPPED <= 1'b1;
	end
end

////////////////////////////////////////////////////

// Flash PROM.
assign PROMCS0 = ASREQ & PROMCS & UDS_IN;    // EVEN
assign PROMCS1 = ASREQ & PROMCS & LDS_IN;    // ODD

// SRAM.
assign SRAMCS0 = ASREQ & SRAMCS & UDS_IN;    // EVEN
assign SRAMCS1 = ASREQ & SRAMCS & LDS_IN;    // ODD

// Output enable.
assign OE = ASREQ & (PROMCS | SRAMCS) & ~WR_IN;

////////////////////////////////////////////////////

wire ADDRSIGNAL = DTREQ & LDS_IN & ADDRIO & (ADDR_IN[19:0] == 20'b1);
reg SIGNAL_READING;

// Output signal port. (0x00100001, bit7-4)
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		OUTPUT_SIGNAL <= 4'b0;
		SIGNAL_READING <= 1'b0;
	end else if (ADDRSIGNAL) begin
		if (WR_IN) begin
			OUTPUT_SIGNAL <= DATA[7:4];
			SIGNAL_READING <= 1'b0;
		end else begin
			SIGNAL_READING <= 1'b1;
		end
	end else begin
		SIGNAL_READING <= 1'b0;
	end
end

// I/O signal port. (Input signal is lower bit3-0)
assign DATA[15:0] = SIGNAL_READING ? { 8'b0, OUTPUT_SIGNAL, INPUT_SIGNAL_IN } : 16'bz;

////////////////////////////////////////////////////

// Stepper pause state.
reg PAUSE_STATE;

// DTACK control with stepper.
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		PAUSE_STATE <= 1'b0;
	// Not under pause.
	end else if (~PAUSE_STATE) begin
		// Inactivated DTREQ.
		if (~DTREQ) begin
			// Negate DTACK.
			DTACK <= 1'b0;
		// Activated DTREQ and into stepper mode.
		end else if (STEPEN_IN) begin
			// Pressed step switch.
			if (STEP_IN) begin
				// Assert DTACK.
				DTACK <= 1'b1;
				// Send to next state.
				PAUSE_STATE <= 1'b1;
			// Not clicked step switch.
			end else begin
				// Negate DTACK.
				DTACK <= 1'b0;
			end
		// Activated DTREQ and not into stepper mode.
		end else begin
			// Assert DTACK.
			DTACK <= 1'b1;
		end
	// Pausing.
	end else begin
		// Inactivated DTREQ.
		if (~DTREQ) begin
			// Negate DTACK.
			DTACK <= 1'b0;
		end
		// Released step switch.
		if (~DTACK & ~STEP_IN) begin
			// Send to first state.
			PAUSE_STATE <= 1'b0;
		end
	end
end

endmodule

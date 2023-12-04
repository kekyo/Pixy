module BusControl(
    input CPUCLK_IN,
	input STEPEN_IN,
	input STEP_IN,
	input AS_IN,
	input WR_IN,
	input UDS_IN,
	input LDS_IN,
	input [23:0] ADDR_IN,
    output reg RESET,
	output reg HALT,
	output reg RUN,
	output reg DTACK,
	output PROMCS0,
	output PROMCS1,
	output SRAMCS0,
	output SRAMCS1,
	output OE);

////////////////////////////////////////////////////

// Reset waiting counter.
reg [13:0] RESET_COUNT;
// Stepper pause state.
reg PAUSE_STATE;
// Bootstrap read from PROM area.
reg BOOTSTRAPPED;

////////////////////////////////////////////////////

// Reset control.
always @ (posedge CPUCLK_IN) begin
    if (RESET_COUNT == 'd10000) begin    // 10us/100kHz=10000 --> 100ms
		RESET <= 1'd0;
		HALT <= 1'd0;
		RUN <= 1'd1;
    end else begin
		RESET <= 1'd1;
		HALT <= 1'd1;
		RUN <= 1'd0;
		RESET_COUNT <= RESET_COUNT + 14'd1;
    end
end

////////////////////////////////////////////////////

// Booting Read                  Write
// +---------------+            +---------------+
// |               | 0x00ffffff |               |
// | PROM (Flash)  |            | PROM (Flash)  |
// |               | 0x00f00000 |               |
// +---------------+            +---------------+
// |   (nothing)   |            |   (nothing)   | 
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
// |               | 0x000fffff
// | SRAM          |
// |               | 0x00000000
// +---------------+

// Address decoder.
wire ADDRLOWER = ADDR_IN[23:20] == 4'b0000;
wire ADDRUPPER = ADDR_IN[23:20] == 4'b1111;
wire WRBOOTSTRAPPED = WR_IN | BOOTSTRAPPED;
wire PROMCS = ADDRUPPER | (~WRBOOTSTRAPPED & ADDRLOWER);
wire SRAMCS = WRBOOTSTRAPPED & ADDRLOWER;

////////////////////////////////////////////////////

// Address request signal.
wire ASREQ = RUN & AS_IN;

// Data request signal.
wire DTREQ = RUN & AS_IN & (UDS_IN | LDS_IN);

// Write data request in lower area.
wire WRLOWERREQ = DTREQ & WR_IN & ADDRLOWER;

// Exit from bootstrap mode.
always @ (posedge WRLOWERREQ, negedge RUN) begin
	if (~RUN) begin
		BOOTSTRAPPED <= 1'd0;
	end else begin
		BOOTSTRAPPED <= 1'd1;
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

// DTACK control with stepper.
always @ (posedge CPUCLK_IN) begin
	// Not under pause.
	if (PAUSE_STATE == 1'd0) begin
		// Inactivated DTREQ.
		if (DTREQ == 1'd0) begin
			// Negate DTACK.
			DTACK <= 1'd0;
		// Activated DTREQ and into stepper mode.
		end else if (STEPEN_IN == 1'd1) begin
			// Pressed step switch.
			if (STEP_IN == 1'd1) begin
				// Assert DTACK.
				DTACK <= 1'd1;
				// Send to next state.
				PAUSE_STATE <= 1'd1;
			// Not clicked step switch.
			end else begin
				// Negate DTACK.
				DTACK <= 1'd0;
			end
		// Activated DTREQ and not into stepper mode.
		end else begin
			// Assert DTACK.
			DTACK <= 1'd1;
		end
	// Pausing.
	end else begin
		// Inactivated DTREQ.
		if (DTREQ == 1'd0) begin
			// Negate DTACK.
			DTACK <= 1'd0;
		end
		// Released step switch.
		if (DTACK == 1'd0 & STEP_IN == 1'd0) begin
			// Send to first state.
			PAUSE_STATE <= 1'd0;
		end
	end
end

endmodule

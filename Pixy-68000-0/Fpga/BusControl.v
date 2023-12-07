module BusControl(
    input CPUCLK_IN,
	input STEPEN_IN,
	input STEP_IN,
	input AS_IN,
	input WR_IN,
	input UDS_IN,
	input LDS_IN,
	input [23:0] ADDR_IN,
	input [15:0] DATA_IN,
    output reg RESET,
	output reg HALT,
	output reg RUN,
	output reg DTACK,
	output PROMCS0,
	output PROMCS1,
	output SRAMCS0,
	output SRAMCS1,
	output OE,
	output reg [7:0] OUTPUT_SIGNAL);

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
		RESET <= 1'b0;
		HALT <= 1'b0;
		RUN <= 1'b1;
    end else begin
		RESET <= 1'b1;
		HALT <= 1'b1;
		RUN <= 1'b0;
		RESET_COUNT <= RESET_COUNT + 14'b1;
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
wire ASREQ = RUN & AS_IN;

// Data request signal.
wire DTREQ = RUN & AS_IN & (UDS_IN | LDS_IN);

// Write data request in lower area.
wire WRLOWERREQ = DTREQ & WR_IN;

// Exit from bootstrap mode.
always @ (posedge WRLOWERREQ, negedge RUN) begin
	if (~RUN) begin
		BOOTSTRAPPED <= 1'b0;
	end else if (ADDRLOWER) begin
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

// Output signal port. (0x00100001)
wire OUTPUT_SIGNAL_REQ = DTREQ & LDS_IN & WR_IN;

always @ (posedge OUTPUT_SIGNAL_REQ, negedge RUN) begin
	if (~RUN) begin
		OUTPUT_SIGNAL <= 8'b0;
	end else if (ADDRIO & (ADDR_IN[19:0] == 20'b1)) begin
		OUTPUT_SIGNAL <= DATA_IN[7:0];
	end
end

////////////////////////////////////////////////////

// DTACK control with stepper.
always @ (posedge CPUCLK_IN) begin
	// Not under pause.
	if (PAUSE_STATE == 1'b0) begin
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

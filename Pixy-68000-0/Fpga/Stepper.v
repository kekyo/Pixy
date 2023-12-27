module Stepper(
	input MCLK_IN,
	input CPUCLK_IN,
	input RUN_IN,
	input STEPEN_IN,
	input STEP_IN,
	input ENABLE_IN,
	output reg ENABLE_EXECUTE);

////////////////////////////////////////////////////

// Stepper pause state.
reg PAUSE_STATE;

// DTACK control with stepper.
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		PAUSE_STATE <= 1'b0;
		ENABLE_EXECUTE <= 1'b0;
	// Not under pause.
	end else if (~PAUSE_STATE) begin
		// Inactivated EXECUTE.
		if (~ENABLE_IN) begin
			// Negate EXECUTE.
			ENABLE_EXECUTE <= 1'b0;
		// Activated REQ and into stepper mode.
		end else if (STEPEN_IN) begin
			// Pressed step switch.
			if (STEP_IN) begin
				// Assert EXECUTE.
				ENABLE_EXECUTE <= 1'b1;
				// Send to next state.
				PAUSE_STATE <= 1'b1;
			// Not clicked step switch.
			end else begin
				// Negate EXECUTE.
				ENABLE_EXECUTE <= 1'b0;
			end
		// Activated REQ and not into stepper mode.
		end else begin
			// Assert ACK.
			ENABLE_EXECUTE <= 1'b1;
		end
	// Pausing.
	end else begin
		// Inactivated EXECUTE.
		if (~ENABLE_IN) begin
			// Negate ACK.
			ENABLE_EXECUTE <= 1'b0;
		end
		// Released step switch.
		if (~ENABLE_EXECUTE & ~STEP_IN) begin
			// Send to first state.
			PAUSE_STATE <= 1'b0;
		end
	end
end

endmodule

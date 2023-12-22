module Stepper(
	input MCLK_IN,
	input RUN_IN,
	input STEPEN_IN,
	input STEP_IN,
	input REQ_IN,
	output reg ACK);

////////////////////////////////////////////////////

// Stepper pause state.
reg PAUSE_STATE;

// DTACK control with stepper.
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		PAUSE_STATE <= 1'b0;
	// Not under pause.
	end else if (~PAUSE_STATE) begin
		// Inactivated REQ.
		if (~REQ_IN) begin
			// Negate ACK.
			ACK <= 1'b0;
		// Activated REQ and into stepper mode.
		end else if (STEPEN_IN) begin
			// Pressed step switch.
			if (STEP_IN) begin
				// Assert ACK.
				ACK <= 1'b1;
				// Send to next state.
				PAUSE_STATE <= 1'b1;
			// Not clicked step switch.
			end else begin
				// Negate ACK.
				ACK <= 1'b0;
			end
		// Activated REQ and not into stepper mode.
		end else begin
			// Assert ACK.
			ACK <= 1'b1;
		end
	// Pausing.
	end else begin
		// Inactivated REQ.
		if (~REQ_IN) begin
			// Negate ACK.
			ACK <= 1'b0;
		end
		// Released step switch.
		if (~ACK & ~STEP_IN) begin
			// Send to first state.
			PAUSE_STATE <= 1'b0;
		end
	end
end

endmodule

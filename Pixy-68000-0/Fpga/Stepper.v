module Stepper(
	input MCLK_IN,
	input CPUCLK_IN,
	input RUN_IN,
	input STEPEN_IN,
	input STEP_IN,
	input ENABLE_IN,
	output reg ENABLE_EXECUTE);

////////////////////////////////////////////////////

// Avoid STEP switch chattering.

reg FILTER_STATE;
reg [11:0] FILTER_COUNT;
wire FILTERED_STEP = FILTER_STATE;

always @(negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		FILTER_STATE <= 1'b0;
		FILTER_COUNT <= 12'd0;
	end else begin
		case (FILTER_STATE)
			1'b0:begin
				if (STEP_IN) begin
					if (FILTER_COUNT == 12'd4095) begin
						FILTER_COUNT <= 12'd0;
						FILTER_STATE <= 2'b1;
					end else begin
						FILTER_COUNT <= FILTER_COUNT + 12'd1;
					end
				end else begin
					FILTER_COUNT <= 12'd0;
				end
			end
			1'b1:begin
				if (~STEP_IN) begin
					if (FILTER_COUNT == 12'd4095) begin
						FILTER_COUNT <= 12'd0;
						FILTER_STATE <= 1'b0;
					end else begin
						FILTER_COUNT <= FILTER_COUNT + 12'd1;
					end
				end else begin
					FILTER_COUNT <= 12'd0;
				end
			end
		endcase
	end
end

//--------------------------------

reg PAUSE_STATE;

// DTACK control with stepper.
always @ (posedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		PAUSE_STATE <= 1'b0;
		ENABLE_EXECUTE <= 1'b0;
	end else begin
		case (PAUSE_STATE)
			// Not under pause.
			1'b0:begin
				// Not STEPIN mode.
				if (~STEPEN_IN) begin
					// Always passthrough ENABLE.
					ENABLE_EXECUTE <= ENABLE_IN;
				// STEP switch on.
				end else if (FILTERED_STEP) begin
					// Assert EXECUTE.
					ENABLE_EXECUTE <= 1'b1;
					// Send to next state.
					PAUSE_STATE <= 1'b1;
				// Released STEP switch.
				end else begin
					// Negate EXECUTE.
					ENABLE_EXECUTE <= 1'b0;
				end
			end
			// Pausing.
			1'b1:begin
				// Inactivated ENABLE.
				if (~ENABLE_IN) begin
					// Negate EXECUTE.
					ENABLE_EXECUTE <= 1'b0;
					// Released step switch.
					if (~FILTERED_STEP) begin
						// Send to first state.
						PAUSE_STATE <= 1'b0;
					end
				// Released step switch.
				end else if (~ENABLE_EXECUTE & ~FILTERED_STEP) begin
					// Negate EXECUTE.
					ENABLE_EXECUTE <= 1'b0;
					// Send to first state.
					PAUSE_STATE <= 1'b0;
				end
			end
		endcase
	end
end

endmodule

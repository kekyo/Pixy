module Monitor(
	input SPICLK_IN,
	input SPISS_IN,
	input [23:0] ADDR_IN,
	input [15:0] DATA_IN,
	input [7:0] OUTPUT_SIGNAL_IN,
	output SPISO
);

////////////////////////////////////////////////////

// SPI state.
reg [5:0] SPI_STATE;

// SPI bit shift buffer.
reg [47:0] BUFFER;

////////////////////////////////////////////////////

always @ (posedge SPICLK_IN, negedge SPISS_IN) begin
	if (SPISS_IN == 1'd0) begin
		BUFFER[47] <= 1'bz;
		SPI_STATE <= 6'd0;
	end else if (SPI_STATE == 0) begin
		BUFFER <= { ADDR_IN, DATA_IN, OUTPUT_SIGNAL_IN };
		SPI_STATE <= SPI_STATE + 6'd1;
	end else if (SPI_STATE != 49) begin
	    BUFFER <= { BUFFER[46:0], 1'd0 };
		SPI_STATE <= SPI_STATE + 6'd1;
	end else begin
		BUFFER[47] <= 1'd0;
		SPI_STATE <= 6'd0;
	end
end

assign SPISO = BUFFER[47];

endmodule

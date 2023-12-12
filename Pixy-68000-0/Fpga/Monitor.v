module Monitor(
	input SPICLK_IN,
	input SPISI_IN,
	input SPISS_IN,
	input [23:0] ADDR_IN,
	input [15:0] DATA_IN,
	input [3:0] OUTPUT_SIGNAL_IN,
	output reg [3:0] INPUT_SIGNAL,
	output SPISO
);

////////////////////////////////////////////////////

// SPI state.
reg [5:0] SPI_STATE;

// SPI sender bit shift buffer.
reg [47:0] SEND_BUFFER;

// SPI receiver bit shift buffer.
reg [7:0] RECEIVE_BUFFER;

////////////////////////////////////////////////////

always @ (posedge SPICLK_IN, negedge SPISS_IN) begin
	if (SPISS_IN == 1'd0) begin
		SEND_BUFFER[47] <= 1'bz;
		SPI_STATE <= 6'd0;
	end else if (SPI_STATE == 0) begin
		// Little endian, LSB first format.
		SEND_BUFFER <= { 4'b0, OUTPUT_SIGNAL_IN, DATA_IN, ADDR_IN };
		SPI_STATE <= SPI_STATE + 6'd1;
	end else if (SPI_STATE != 6'd49) begin
	    SEND_BUFFER <= { 1'b0, SEND_BUFFER[47:1] };
		SPI_STATE <= SPI_STATE + 6'd1;
	end else begin
		SEND_BUFFER[0] <= 1'b0;
		SPI_STATE <= 6'd0;
	end
end

assign SPISO = SEND_BUFFER[0];

always @ (negedge SPICLK_IN, negedge SPISS_IN) begin
	if (SPISS_IN == 1'd0) begin
		RECEIVE_BUFFER <= 8'b0;
	end else if (SPI_STATE == 6'd0) begin
		RECEIVE_BUFFER <= 8'b0;
	end else if (SPI_STATE < 6'd8) begin
		RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
	end else if (SPI_STATE == 6'd8) begin
		// <= { SPISI_IN, RECEIVE_BUFFER[7:1] }[3:0]
		INPUT_SIGNAL <= RECEIVE_BUFFER[4:1];
    end
end

endmodule

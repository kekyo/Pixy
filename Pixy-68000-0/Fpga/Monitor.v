module Monitor(
	input MCLK_IN,
	input SPICLK_IN,
	input SPISI_IN,
	input SPISS_IN,
	input [23:0] ADDR_IN,
	input [15:0] DATA_IN,
	input [3:0] OUTPUT_SIGNAL_IN,
	output reg [3:0] INPUT_SIGNAL,
	output SPISO);

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
	end else begin
		case (SPI_STATE)
			// Start.
			6'd0:begin
				// Little endian, LSB first format.
				SEND_BUFFER <= { 4'b0, OUTPUT_SIGNAL_IN, DATA_IN, ADDR_IN };
				SPI_STATE <= SPI_STATE + 6'd1;
			end
			// End.
			6'd49:begin
				SEND_BUFFER[0] <= 1'b0;
				SPI_STATE <= 6'd0;
			end
			// Shifting.
			default:begin
				SEND_BUFFER <= { 1'b0, SEND_BUFFER[47:1] };
				SPI_STATE <= SPI_STATE + 6'd1;
			end
		endcase
	end
end

assign SPISO = SEND_BUFFER[0];

always @ (negedge SPICLK_IN, negedge SPISS_IN) begin
	if (SPISS_IN == 1'd0) begin
		RECEIVE_BUFFER <= 8'b0;
	end else begin
		case (SPI_STATE)
			// Start.
			6'd0:
				RECEIVE_BUFFER <= 8'b0;
			// Shift in the bits.
			6'd1:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			6'd2:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			6'd3:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			6'd4:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			6'd5:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			6'd6:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			6'd7:
				RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[7:1] };
			// End.
			6'd8:begin
				// All bits received, apply to INPUT_SIGNAL.
				// <= { SPISI_IN, RECEIVE_BUFFER[7:1] }[3:0]
				INPUT_SIGNAL <= RECEIVE_BUFFER[4:1];
			end
		endcase
    end
end

endmodule

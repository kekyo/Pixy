module Monitor(
	input MCLK_IN,
	input RUN_IN,
	input SPICLK_IN,
	input SPISI_IN,
	input SPISS_IN,
	input [23:0] ADDR_IN,
	input [15:0] DATA_IN,
	input [3:0] OUTPUT_SIGNAL_IN,
	input UART_SEND_TRIGGER_IN,
	input [7:0] UART_SEND_BYTE_IN,
	input UART_RECEIVE_CAPTURE_IN,
	output reg [3:0] INPUT_SIGNAL,
	output SPISO,
	output UART_SEND_BUSY,
	output UART_RECEIVED,
	output reg [7:0] UART_RECEIVE_BYTE);

////////////////////////////////////////////////////

reg [7:0] UART_SEND_BYTE;
reg UART_SEND_TRIGGER;
reg UART_SENT_TRIGGER;

always @ (posedge UART_SEND_TRIGGER_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_SEND_TRIGGER <= UART_SENT_TRIGGER;
		UART_SEND_BYTE <= 8'b0;
	end else begin
		UART_SEND_BYTE = UART_SEND_BYTE_IN;      // Sequence 1
		UART_SEND_TRIGGER = ~UART_SEND_TRIGGER;  // Sequence 2
	end
end

reg UART_RECEIVED_TRIGGER;
reg UART_CAPTURED_TRIGGER;

always @ (posedge UART_RECEIVE_CAPTURE_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_CAPTURED_TRIGGER <= UART_RECEIVED_TRIGGER;
	end else begin
		UART_CAPTURED_TRIGGER = ~UART_CAPTURED_TRIGGER;
	end
end

////////////////////////////////////////////////////

// SPI is MODE1, LSB first, Little endian.

// SPI state.
reg [5:0] SPI_STATE;

////////////////////////////////////////////////////

// SPI sender bit shift buffer.
reg [55:0] SEND_BUFFER;
reg SEND_BUSY;

always @ (posedge SPICLK_IN, negedge SPISS_IN) begin
	if (~SPISS_IN) begin
		SEND_BUFFER[0] <= 1'bz;
		SPI_STATE <= 6'd0;
	end else begin
		case (SPI_STATE)
			// Start.
			6'd0:begin
				if (UART_SEND_TRIGGER != UART_SENT_TRIGGER) begin
					// Little endian, LSB first format.
					// MSB  ------------------------------------------------------------------------------------------------------------  LSB
					//      | UART_SEND_BYTE[7:0] | 0 | 0 | RECV_BUSY | SEND_DATA(1)    | OUTPUT_SIGNAL[3:0] | DATA[15:0] | ADDR[23:0] |  ====>
					//      ------------------------------------------------------------------------------------------------------------
					SEND_BUFFER = { UART_SEND_BYTE, 2'b00, UART_RECEIVED, 1'b1, OUTPUT_SIGNAL_IN, DATA_IN, ADDR_IN };   // Sequence 1
					UART_SENT_TRIGGER = ~UART_SENT_TRIGGER;   // Sequence 2
				end else begin
					// Little endian, LSB first format.
					// MSB  ------------------------------------------------------------------------------------------------------------  LSB
					//      | UART_SEND_BYTE[7:0] | 0 | 0 | RECV_BUSY | NO_SEND_DATA(0) | OUTPUT_SIGNAL[3:0] | DATA[15:0] | ADDR[23:0] |  ====>
					//      ------------------------------------------------------------------------------------------------------------
					SEND_BUFFER <= { UART_SEND_BYTE, 2'b00, UART_RECEIVED, 1'b0, OUTPUT_SIGNAL_IN, DATA_IN, ADDR_IN };
				end
				SPI_STATE <= SPI_STATE + 6'd1;
			end
			// Shifting.
			default:begin
				SEND_BUFFER <= { 1'b0, SEND_BUFFER[55:1] };
				SPI_STATE <= SPI_STATE + 6'd1;
			end
		endcase
	end
end

assign SPISO = SEND_BUFFER[0];
assign UART_SEND_BUSY = (UART_SEND_TRIGGER ^ UART_SENT_TRIGGER) | SEND_BUSY;

////////////////////////////////////////////////////

// SPI receiver bit shift buffer.
reg [15:0] RECEIVE_BUFFER;

always @ (negedge SPICLK_IN, negedge SPISS_IN) begin
	if (~SPISS_IN) begin
		RECEIVE_BUFFER <= 8'b0;
	end else begin
		case (SPI_STATE)
			// Start.
			6'd0:begin
				RECEIVE_BUFFER <= 8'b0;
			end
			// End.
			6'd16:begin
				// All bits received, apply to INPUT_SIGNAL.
				//  MSB  -------------------------------------------------------------------------------------------  LSB
				// ====> | UART_RECEIVE_BYTE[7:0] | 0 | 0 | SEND_BUSY(0/1) | RECEIVE_DATA(0/1) | INPUT_SIGNAL[3:0] |
				//       -------------------------------------------------------------------------------------------
				// <= { SPISI_IN, RECEIVE_BUFFER[7:1] }[3:0]
				INPUT_SIGNAL <= RECEIVE_BUFFER[4:1];
				UART_RECEIVE_BYTE = { SPISI_IN, RECEIVE_BUFFER[15:9] };   // Sequence 1
				if (RECEIVE_BUFFER[5]) begin   // RECEIVE_DATA
					UART_RECEIVED_TRIGGER = ~UART_RECEIVED_TRIGGER;       // Sequence 2
				end
				SEND_BUSY = RECEIVE_BUFFER[6];    // SEND_BUSY            // Sequence 3
			end
			default:begin
				// Shift in the bits.
				if (SPI_STATE < 6'd16) begin
					RECEIVE_BUFFER <= { SPISI_IN, RECEIVE_BUFFER[15:1] };
				end
			end
		endcase
    end
end

assign UART_RECEIVED = UART_RECEIVED_TRIGGER ^ UART_CAPTURED_TRIGGER;

endmodule

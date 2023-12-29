module BusControl(
	input MCLK_IN,
	input CPUCLK_IN,
	input STEPEN_IN,
	input STEP_IN,
	input RUN_IN,
	input AS_IN,
	input WR_IN,
	input UDS_IN,
	input LDS_IN,
	input [2:0] MPU_STATUS_CODE_IN,
	input [3:0] INPUT_SIGNAL_IN,
	input UART_SEND_BUSY_IN,
	input UART_RECEIVED_IN,
	input [7:0] UART_RECEIVE_BYTE_IN,
	input [23:0] ADDR_IN,
	inout [15:0] DATA,
	output DATA_ACK,
	output INT_AUTOVEC_ACK,
	output BUS_ERROR_ACK,
	output [2:0] INT_LEVEL,
	output reg PROM_CS0,
	output reg PROM_CS1,
	output reg SRAM_CS0,
	output reg SRAM_CS1,
	output reg OUTPUT_ENABLE,
	output reg [3:0] OUTPUT_SIGNAL,
	output reg UART_SEND_TRIGGER,
	output reg [7:0] UART_SEND_BYTE,
	output reg UART_RECEIVE_CAPTURE);

////////////////////////////////////////////////////

// Booting Read                  Write
// +---------------+            +---------------+
// |               | 0x00ffffff |               |
// | PROM (Flash)  |            | PROM (Flash)  |
// |               | 0x00f00000 |               |
// +---------------+            +---------------+
// |   (nothing)   |            |   (nothing)   | 
// +---------------+            +---------------+
// | SPI UART RECV | 0x00100007 | SPI UART RECV |
// | SPI UART SEND | 0x00100005 | SPI UART SEND |
// | SPI UART CONT | 0x00100003 | SPI UART CONT |
// | SPI Signal    | 0x00100001 | SPI Signal    | 
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
// | SPI UART RECV | 0x00100007
// | SPI UART SEND | 0x00100005
// | SPI UART CONT | 0x00100003
// | SPI Signal    | 0x00100001
// +---------------+
// |               | 0x000fffff
// | SRAM          |
// |               | 0x00000000
// +---------------+

// Address decoder.
wire ADDRLOWER = ADDR_IN[23:20] == 4'b0000;
wire ADDRIO = ADDR_IN[23:20] == 20'b0001;
wire ADDRUPPER = ADDR_IN[23:20] == 4'b1111;

wire INT_ACK_CODE = MPU_STATUS_CODE_IN == 3'b111;

////////////////////////////////////////////////////

wire MEMORY_DATA_STROBE = LDS_IN | UDS_IN;

// Bootstrap read from lower address area.
reg BOOTSTRAPPED;

// Flash ROM & SRAM access.
always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		PROM_CS0 <= 1'b0;
		PROM_CS1 <= 1'b0;
		SRAM_CS0 <= 1'b0;
		SRAM_CS1 <= 1'b0;
		OUTPUT_ENABLE <= 1'b0;
		BOOTSTRAPPED <= 1'b0;
	end else if (AS_IN & MEMORY_DATA_STROBE & ~INT_ACK_CODE) begin
		// Lower address (0x00000000 - 0x000fffff)
		if (ADDRLOWER) begin
			// SRAM (Bootstrapped or write)
			if (BOOTSTRAPPED | WR_IN) begin
				SRAM_CS0 <= UDS_IN;
				SRAM_CS1 <= LDS_IN;
				OUTPUT_ENABLE <= ~WR_IN;
				PROM_CS0 <= 1'b0;
				PROM_CS1 <= 1'b0;
				// Exit from bootstrap mode when write to SRAM.
				BOOTSTRAPPED <= 1'b1;
			// Flash ROM (Bootstrapping)
			end else begin
				PROM_CS0 <= UDS_IN;
				PROM_CS1 <= LDS_IN;
				OUTPUT_ENABLE <= ~WR_IN;
				SRAM_CS0 <= 1'b0;
				SRAM_CS1 <= 1'b0;
			end
		// Upper address (0x00f00000 - 0x00ffffff, Flash ROM.)
		end else if (ADDRUPPER) begin
			PROM_CS0 <= UDS_IN;
			PROM_CS1 <= LDS_IN;
			OUTPUT_ENABLE <= ~WR_IN;
			SRAM_CS0 <= 1'b0;
			SRAM_CS1 <= 1'b0;
		end else begin
			PROM_CS0 <= 1'b0;
			PROM_CS1 <= 1'b0;
			SRAM_CS0 <= 1'b0;
			SRAM_CS1 <= 1'b0;
			OUTPUT_ENABLE <= 1'b0;
		end
	end else begin
		PROM_CS0 <= 1'b0;
		PROM_CS1 <= 1'b0;
		SRAM_CS0 <= 1'b0;
		SRAM_CS1 <= 1'b0;
		OUTPUT_ENABLE <= 1'b0;
	end
end

////////////////////////////////////////////////////

wire ADDRIOSPI = ADDRIO & (ADDR_IN[19:4] == 16'b0000000000000000);
wire IO_DATA_STROBE = LDS_IN & ~UDS_IN;

//---------------------

wire ADDRSIGNAL = ADDRIOSPI & (ADDR_IN[3:0] == 4'b0001);
reg SIGNAL_CS;
reg SIGNAL_READING;

// SPI signal port. (0x00100001)
always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		OUTPUT_SIGNAL <= 4'b0;
		SIGNAL_CS <= 1'b0;
		SIGNAL_READING <= 1'b0;
	end else if (AS_IN & IO_DATA_STROBE & ~INT_ACK_CODE) begin
		if (ADDRSIGNAL) begin
			if (WR_IN) begin
				SIGNAL_READING = 1'b0;      // Sequence 0
				OUTPUT_SIGNAL = DATA[7:4];  // Sequnece 1
			end else begin
				SIGNAL_READING = 1'b1;
			end
			SIGNAL_CS = 1'b1;
		end else begin
			SIGNAL_CS <= 1'b0;
			SIGNAL_READING <= 1'b0;
		end
	end else begin
		SIGNAL_CS <= 1'b0;
		SIGNAL_READING <= 1'b0;
	end
end

// Read SPI signal port.
assign DATA[7:0] = SIGNAL_READING ? { OUTPUT_SIGNAL, INPUT_SIGNAL_IN } : 8'bz;

//---------------------

wire ADDRUARTCONT = ADDRIOSPI & (ADDR_IN[3:0] == 4'b0011);
reg UART_CONTROL_CS;
reg UART_CONTROL_READING;
reg UART_ENABLE_RECEIVE_INT;
reg UART_ENABLE_SEND_INT;

// SPI UART control port. (0x00100003)
// MSB (bit7) -------------------------------------------------------------------- LSB (bit0)
//            | 0 | 0 | 0 | 0 | EN_RECV_INT | EN_SEND_INT | RECEIVED | SEND_BUSY |
//            --------------------------------------------------------------------
always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_CONTROL_CS <= 1'b0;
		UART_CONTROL_READING <= 1'b0;
	end else if (AS_IN & IO_DATA_STROBE & ~INT_ACK_CODE) begin
		if (ADDRUARTCONT) begin
			if (WR_IN) begin
				UART_CONTROL_READING = 1'b0;         // Sequence 1
				UART_ENABLE_SEND_INT = DATA[2];      // Sequence 2
				UART_ENABLE_RECEIVE_INT = DATA[3];   // Sequnece 3
				UART_CONTROL_CS = 1'b1;              // Sequence 4
			end else begin
				UART_CONTROL_READING = 1'b1;         // Sequnece 1
				UART_CONTROL_CS = 1'b1;              // Sequnece 2
			end
		end else begin
			UART_CONTROL_CS <= 1'b0;
			UART_CONTROL_READING <= 1'b0;
		end
	end else begin
		UART_CONTROL_CS <= 1'b0;
		UART_CONTROL_READING <= 1'b0;
	end
end

// Read SPI UART control port.
assign DATA[7:0] = UART_CONTROL_READING ? { 4'b0, UART_ENABLE_RECEIVE_INT, UART_ENABLE_SEND_INT, UART_RECEIVED_IN, UART_SEND_BUSY_IN } : 8'bz;

//---------------------

wire ADDRUARTSEND = ADDRIOSPI & (ADDR_IN[3:0] == 4'b0101);
reg UART_SEND_CS;
reg UART_SEND_READING;

// SPI UART send byte port. (0x00100005)
always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_SEND_BYTE <= 8'b0;
		UART_SEND_TRIGGER <= 1'b0;
		UART_SEND_CS <= 1'b0;
		UART_SEND_READING <= 1'b0;
	end else if (AS_IN & IO_DATA_STROBE & ~INT_ACK_CODE) begin
		if (ADDRUARTSEND) begin
			if (WR_IN) begin
				UART_SEND_READING = 1'b0;     // Sequence 1
				UART_SEND_BYTE = DATA[7:0];   // Sequence 2
				UART_SEND_TRIGGER = 1'b1;     // Sequence 3
				UART_SEND_CS = 1'b1;          // Sequence 4
			end else begin
				UART_SEND_TRIGGER <= 1'b0;
				UART_SEND_READING = 1'b1;     // Sequence 1
				UART_SEND_CS = 1'b1;          // Sequence 2
			end
		end else begin
			UART_SEND_TRIGGER <= 1'b0;
			UART_SEND_CS <= 1'b0;
			UART_SEND_READING <= 1'b0;
		end
	end else begin
		UART_SEND_TRIGGER <= 1'b0;
		UART_SEND_CS <= 1'b0;
		UART_SEND_READING <= 1'b0;
	end
end

// Read SPI UART send byte port.
assign DATA[7:0] = UART_SEND_READING ? UART_SEND_BYTE : 8'bz;

//---------------------

wire ADDRUARTRECV = ADDRIOSPI & (ADDR_IN[3:0] == 4'b0111);
reg UART_RECEIVE_CS;
reg UART_RECEIVE_NOT_SELECTED;

// SPI UART receive byte port. (0x00100007)
always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_RECEIVE_CAPTURE <= 1'b0;
		UART_RECEIVE_CS <= 1'b0;
	end else if (AS_IN & IO_DATA_STROBE & ~INT_ACK_CODE) begin
		if (ADDRUARTRECV) begin
			// Write is invalid.
			if (WR_IN) begin
				UART_RECEIVE_CS <= 1'b0;
				UART_RECEIVE_CAPTURE <= 1'b0;
			end else begin
				UART_RECEIVE_CAPTURE = 1'b1;   // Sequence 1
				UART_RECEIVE_CS = 1'b1;        // Sequnece 2
			end
		end else begin
			UART_RECEIVE_CS <= 1'b0;
			UART_RECEIVE_CAPTURE <= 1'b0;
		end
	end else begin
		UART_RECEIVE_CS <= 1'b0;
		UART_RECEIVE_CAPTURE <= 1'b0;
	end
end

// Read SPI UART receive byte port.
assign DATA[7:0] = UART_RECEIVE_CAPTURE ? UART_RECEIVE_BYTE_IN : 8'bz;

//---------------------

// SPI UART interrupt requests.
reg UART_RECEIVE_INT_REQ;
reg UART_SEND_INT_REQ;

always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_RECEIVE_INT_REQ <= 1'b0;
		UART_SEND_INT_REQ <= 1'b0;
	end else begin
		UART_RECEIVE_INT_REQ <= UART_ENABLE_RECEIVE_INT & UART_RECEIVED_IN;
		UART_SEND_INT_REQ <= UART_ENABLE_SEND_INT & ~UART_SEND_BUSY_IN;
		//UART_SEND_INT_REQ <= UART_ENABLE_SEND_INT & ~UART_SEND_TRIGGER;
	end
end

////////////////////////////////////////////////////

// Interrupt level encoder.

// INT1, b001 : (Timer, reserved)
// INT2, b010 : SPI UART send.
// INT3, b011 : SPI UART received.
// INT4, b100 : (Reserved)
// INT5, b101 : (Reserved)
// INT6, b110 : (Reserved)
// INT7, b111 : (Reserved)

assign INT_LEVEL[0] = UART_RECEIVE_INT_REQ;
assign INT_LEVEL[1] = UART_SEND_INT_REQ || UART_RECEIVE_INT_REQ;
assign INT_LEVEL[2] = 1'b0;

wire INT_DATA_STROBE = UDS_IN & LDS_IN;
wire [2:0] INT_ACK_LEVEL = ADDR_IN[3:1];    // { A3, A2, A1 }

reg INT_VALID;

// Interrupt acknowledge.
always @ (negedge CPUCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		INT_VALID <= 1'b0;
	end else if (AS_IN & INT_DATA_STROBE & INT_ACK_CODE) begin
		case (INT_ACK_LEVEL)
			3'b010:begin    // INT2: SPI UART send.
				INT_VALID <= 1'b1;
			end
			3'b011:begin    // INT3: SPI UART received.
				INT_VALID <= 1'b1;
			end
			default:begin
				INT_VALID <= 1'b0;
			end
		endcase
	end else begin
		INT_VALID <= 1'b0;
	end
end

////////////////////////////////////////////////////

// Data acknowledge.
wire ADDR_VALID = PROM_CS0 | PROM_CS1 | SRAM_CS0 | SRAM_CS1 | SIGNAL_CS | UART_CONTROL_CS | UART_SEND_CS | UART_RECEIVE_CS;
wire REQ_VALID = ADDR_VALID | INT_VALID;

// Handles step execution mode.
wire ENABLE_EXECUTE;

Stepper S(
	.MCLK_IN(MCLK_IN),
	.CPUCLK_IN(CPUCLK_IN),
	.RUN_IN(RUN_IN),
	.STEPEN_IN(STEPEN_IN),
	.STEP_IN(STEP_IN),
	.ENABLE_IN(REQ_VALID),
	.ENABLE_EXECUTE(ENABLE_EXECUTE));

// DTACK
assign DATA_ACK = ENABLE_EXECUTE & ADDR_VALID;

// AVEC
assign INT_AUTOVEC_ACK = ENABLE_EXECUTE & INT_VALID;

// BERR
assign BUS_ERROR_ACK = (LDS_IN | UDS_IN) & ~REQ_VALID;

endmodule

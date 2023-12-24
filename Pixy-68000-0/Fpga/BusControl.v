module BusControl(
	input MCLK_IN,
	input STEPEN_IN,
	input STEP_IN,
	input RUN_IN,
	input AS_IN,
	input WR_IN,
	input UDS_IN,
	input LDS_IN,
	input [3:0] INPUT_SIGNAL_IN,
	input UART_SEND_BUSY_IN,
	input UART_RECEIVED_IN,
	input [7:0] UART_RECEIVE_BYTE_IN,
	input [23:0] ADDR_IN,
	inout [15:0] DATA,
	output DTACK,
	output DTERROR,
	output reg PROMCS0,
	output reg PROMCS1,
	output reg SRAMCS0,
	output reg SRAMCS1,
	output reg OE,
	output reg [3:0] OUTPUT_SIGNAL,
	output reg UART_SEND_TRIGGER,
	output reg [7:0] UART_SEND_BYTE,
	output reg UART_RECEIVE_CAPTURE);

////////////////////////////////////////////////////

// Bootstrap read from PROM area.
reg BOOTSTRAPPED;

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
// | SPI UART ST   | 0x00100003 | SPI UART ST   |
// |  Signal I/O   | 0x00100001 |  Signal I/O   | 
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
// | SPI UART ST   | 0x00100003
// |  Signal I/O   | 0x00100001
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
wire ASREQ = RUN_IN & AS_IN;

// Data request signal.
wire DTREQ = RUN_IN & AS_IN & (UDS_IN | LDS_IN);

// Write data request in lower area.
wire WRLOWERREQ = DTREQ & WR_IN;

// Exit from bootstrap mode.
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		BOOTSTRAPPED <= 1'b0;
	end else if (WRLOWERREQ & ADDRLOWER) begin
		BOOTSTRAPPED <= 1'b1;
	end
end

////////////////////////////////////////////////////

// Flash ROM & SRAM access.
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		PROMCS0 <= 1'b0;
		PROMCS1 <= 1'b0;
		SRAMCS0 <= 1'b0;
		SRAMCS1 <= 1'b0;
		OE <= 1'b0;
	// Flash PROM.
	end else if (ASREQ & PROMCS) begin
		PROMCS0 <= UDS_IN;    // EVEN
		PROMCS1 <= LDS_IN;    // ODD
		OE <= ~WR_IN;
		SRAMCS0 <= 1'b0;
		SRAMCS1 <= 1'b0;
	// SRAM.
	end else if (ASREQ & SRAMCS) begin
		SRAMCS0 <= UDS_IN;    // EVEN
		SRAMCS1 <= LDS_IN;    // ODD
		OE <= ~WR_IN;
		PROMCS0 <= 1'b0;
		PROMCS1 <= 1'b0;
	end else begin
		PROMCS0 <= 1'b0;
		PROMCS1 <= 1'b0;
		SRAMCS0 <= 1'b0;
		SRAMCS1 <= 1'b0;
		OE <= 1'b0;
	end
end

////////////////////////////////////////////////////

wire ADDRIOUPPER = DTREQ & LDS_IN & ADDRIO & (ADDR_IN[19:4] == 16'b0);

//---------------------

wire ADDRSIGNAL = ADDRIOUPPER & (ADDR_IN[3:0] == 4'b0001);
reg SIGNAL_READING;

// Output signal port. (0x00100001, bit7-4)
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		OUTPUT_SIGNAL <= 4'b0;
		SIGNAL_READING <= 1'b0;
	end else if (ADDRSIGNAL) begin
		if (WR_IN) begin
			OUTPUT_SIGNAL <= DATA[7:4];
			SIGNAL_READING <= 1'b0;
		end else begin
			SIGNAL_READING <= 1'b1;
		end
	end else begin
		SIGNAL_READING <= 1'b0;
	end
end

// I/O signal port. (Input signal is lower bit3-0)
assign DATA[7:0] = SIGNAL_READING ? { OUTPUT_SIGNAL, INPUT_SIGNAL_IN } : 8'bz;

//---------------------

wire ADDRUARTST = ADDRIOUPPER & (ADDR_IN[3:0] == 4'b0011);
reg UART_ST_READING;

// Input UART status port. (0x00100003)
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_ST_READING <= 1'b0;
	end else if (ADDRUARTST) begin
		if (~WR_IN) begin
			UART_ST_READING <= 1'b1;
		end
	end else begin
		UART_ST_READING <= 1'b0;
	end
end

// Input UART status port.
assign DATA[7:0] = UART_ST_READING ? { 6'b0, UART_RECEIVED_IN, UART_SEND_BUSY_IN } : 8'bz;

//---------------------

wire ADDRUARTSEND = ADDRIOUPPER & (ADDR_IN[3:0] == 4'b0101);
reg UART_SEND_READING;

// I/O UART send byte port. (0x00100005)
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_SEND_BYTE <= 8'b0;
		UART_SEND_TRIGGER <= 1'b0;
		UART_SEND_READING <= 1'b0;
	end else if (ADDRUARTSEND) begin
		if (WR_IN) begin
			UART_SEND_BYTE <= DATA[7:0];
			UART_SEND_TRIGGER <= 1'b1;
			UART_SEND_READING <= 1'b0;
		end else begin
			UART_SEND_TRIGGER <= 1'b0;
			UART_SEND_READING <= 1'b1;
		end
	end else begin
		UART_SEND_TRIGGER <= 1'b0;
		UART_SEND_READING <= 1'b0;
	end
end

// I/O UART send byte port.
assign DATA[7:0] = UART_SEND_READING ? UART_SEND_BYTE : 8'bz;

//---------------------

wire ADDRUARTRECV = ADDRIOUPPER & (ADDR_IN[3:0] == 4'b0111);

// I/O UART receive byte port. (0x00100007)
always @ (negedge MCLK_IN, negedge RUN_IN) begin
	if (~RUN_IN) begin
		UART_RECEIVE_CAPTURE <= 1'b0;
	end else if (ADDRUARTRECV) begin
		if (~WR_IN) begin
			UART_RECEIVE_CAPTURE <= 1'b1;
		end
	end else begin
		UART_RECEIVE_CAPTURE <= 1'b0;
	end
end

// I/O UART receive byte port.
assign DATA[7:0] = UART_RECEIVE_CAPTURE ? UART_RECEIVE_BYTE_IN : 8'bz;

////////////////////////////////////////////////////

// Bus error.
wire ADDR_VALID = PROMCS0 | PROMCS1 | SRAMCS0 | SRAMCS1 | ADDRSIGNAL | ADDRUARTST | ADDRUARTSEND | ADDRUARTRECV;
wire REQ_VALID = DTREQ & ADDR_VALID;

assign DTERROR = DTREQ & ~ADDR_VALID;

////////////////////////////////////////////////////

Stepper S(
	.MCLK_IN(MCLK_IN),
	.RUN_IN(RUN_IN),
	.STEPEN_IN(STEPEN_IN),
	.STEP_IN(STEP_IN),
	.REQ_IN(REQ_VALID),
	.ACK(DTACK));

endmodule

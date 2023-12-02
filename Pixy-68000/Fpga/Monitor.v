module Monitor(
	input SPICLK_IN,
	input SPISS_IN,
	input [23:0] ADDR_IN,
	input [15:0] DATA_IN,
	output reg SPISO
);

reg [5:0] STATE;
reg [39:0] BUFFER;

always @ (posedge SPICLK_IN, negedge SPISS_IN) begin
	if (SPISS_IN == 1'd0) begin
		SPISO = 1'bz;
		STATE <= 6'd0;
	end else if (STATE == 0) begin
		BUFFER = { ADDR_IN, DATA_IN };
		SPISO = BUFFER[39];
		//SPISO = 1'd1;
		STATE <= STATE + 6'd1;
	end else if (STATE != 40) begin
		SPISO = BUFFER[39];
		//SPISO = 1'd1;
		STATE <= STATE + 6'd1;
	end else begin
		SPISO = 1'd0;
		STATE <= 6'd0;
	end
	BUFFER = { BUFFER[38:0], 1'd0 };
end

endmodule

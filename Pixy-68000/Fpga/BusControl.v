module BusControl(
    input CPUCLK_IN,
	input STEPEN_IN,
	input STEP_IN,
	input AS_IN,
	input UDS_IN,
	input LDS_IN,
    output reg RESET,
	output reg HALT,
	output reg RUN,
	output DTACK);

wire TEMP;
reg [13:0] COUNT;

always @ (posedge CPUCLK_IN) begin
    if (COUNT == 'd10000) begin    // 10us/100kHz=10000 --> 100ms
		RESET <= 1'd1;
		HALT <= 1'd1;
		RUN <= 1'd1;
    end else begin
		RESET <= 1'd0;
		HALT <= 1'd0;
		RUN <= 1'd0;
		COUNT <= COUNT + 14'd1;
    end
end

always @ (posedge STEP_IN) begin
end

assign DTACK = RUN & ~STEPEN_IN & AS_IN & (UDS_IN | LDS_IN);

endmodule

module Reset(
    input CPUCLK_IN,
    output reg RESET,
	output reg HALT,
	output reg RUN);

////////////////////////////////////////////////////

// Reset waiting counter.
reg [15:0] RESET_COUNT;

////////////////////////////////////////////////////

// Reset control.
always @ (posedge CPUCLK_IN) begin
    if (RESET_COUNT == 16'd50000) begin    // 2us/0.5MHz=50000 --> 100ms
    //if (RESET_COUNT == 16'd10000) begin    // 10us/100kHz=10000 --> 100ms
		RESET <= 1'b0;
		HALT <= 1'b0;
		RUN <= 1'b1;
    end else begin
		RESET <= 1'b1;
		HALT <= 1'b1;
		RUN <= 1'b0;
		RESET_COUNT <= RESET_COUNT + 16'b1;
    end
end

endmodule

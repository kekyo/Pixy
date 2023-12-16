module Reset(
    input MCLK_IN,
    output reg RESET,
	output reg HALT,
	output reg RUN);

////////////////////////////////////////////////////

// Reset waiting counter.
reg [16:0] RESET_COUNT;

////////////////////////////////////////////////////

// Reset control.
always @ (posedge MCLK_IN) begin
    if (RESET_COUNT == 17'd100000) begin    // 1us/1MHz=100000 --> 100ms
		RESET <= 1'b0;
		HALT <= 1'b0;
		RUN <= 1'b1;
    end else begin
		RESET <= 1'b1;
		HALT <= 1'b1;
		RUN <= 1'b0;
		RESET_COUNT <= RESET_COUNT + 17'b1;
    end
end

endmodule

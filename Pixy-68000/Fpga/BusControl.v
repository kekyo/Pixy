module BusControl(
    input CPUCLK_IN,
    output reg RESET,
	output reg HALT);

wire TEMP;
reg [13:0] COUNT;

always @ (posedge CPUCLK_IN) begin
    if (COUNT == 'd10000) begin    // 10us/100kHz=10000 --> 100ms
		RESET <= 1;
		HALT <= 1;
    end else begin
		RESET <= 0;
		HALT <= 0;
		COUNT <= COUNT + 1;
    end
end

endmodule

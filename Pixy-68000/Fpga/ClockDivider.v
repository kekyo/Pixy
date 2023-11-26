module ClockDivider(
    input MCLK,
    output CPUCLK);

wire MCLK;
wire CPUCLK;
reg [7:0] COUNT;

always @ (posedge MCLK) begin
    COUNT <= COUNT + 1;
end

assign CPUCLK = COUNT[7];

endmodule

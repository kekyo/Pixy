module ClockDivider(
    input MCLK_IN,
    output reg CPUCLK);

/////////////////////////////////////////////

reg [3:0] COUNT;

// CLK_IN=40MHz  (25ns)
always @ (posedge MCLK_IN) begin
    COUNT = COUNT + 4'd1;
    if (COUNT == 4'd1) begin
        COUNT <= 4'd0;
        CPUCLK <= ~CPUCLK;
    end
end

endmodule

module ClockDivider(
    input MCLK_IN,
    output reg CPUCLK,
    output reg TIMERCLK);

/////////////////////////////////////////////

reg [2:0] DIV_COUNT;

// CLK_IN=40MHz  (25ns)
always @ (posedge MCLK_IN) begin
    if (DIV_COUNT == 3'd0) begin
        DIV_COUNT <= 3'd0;     // 20MHz = 2 * 25ns
        CPUCLK <= ~CPUCLK;
    end else begin
        DIV_COUNT <= DIV_COUNT - 3'd1;
    end
end

/////////////////////////////////////////////

reg [4:0] TIMER_COUNT;

// CLK_IN=40MHz  (25ns)
always @ (posedge MCLK_IN) begin
    if (TIMER_COUNT == 5'd0) begin
        TIMER_COUNT <= 5'd20;    // 1MHz = 40 * 25ns
        TIMERCLK <= ~TIMERCLK;
    end else begin
        TIMER_COUNT <= TIMER_COUNT - 5'd1;
    end
end

endmodule

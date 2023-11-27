module ClockDivider(
    input CLK_IN,
    output CLK_OUT);

reg LAST;
reg [8:0] COUNT;

// CLK_IN=40MHz
always @ (posedge CLK_IN) begin
    if (COUNT == 'd399) begin   // 10us/100kHz=199
        LAST <= ~LAST;
        COUNT <= 0;
    end else begin
        COUNT <= COUNT + 1;
    end
end

assign CLK_OUT = LAST;

endmodule

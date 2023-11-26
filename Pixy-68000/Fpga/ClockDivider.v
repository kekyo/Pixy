module ClockDivider(
    input CLK_IN,
    output CLK_OUT);

reg LAST;
reg [8:0] COUNT;

always @ (posedge CLK_IN) begin
    if (COUNT == 'd399) begin   // 20us/50kHz
        LAST <= ~LAST;
        COUNT <= 0;
    end else begin
        COUNT <= COUNT + 9'd1;
    end
end

assign CLK_OUT = LAST;

endmodule

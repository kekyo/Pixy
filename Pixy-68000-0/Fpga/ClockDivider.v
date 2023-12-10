module ClockDivider(
    input CLK_IN,
    output reg CLK_OUT);

/////////////////////////////////////////////

// CLK_IN=40MHz  (25ns)
always @ (posedge CLK_IN) begin
	CLK_OUT <= ~CLK_OUT;  // 50ns/20MHz
end

/////////////////////////////////////////////

//reg [7:0] COUNT;

// For slower, testing purpose.
// CLK_IN=40MHz  (25ns)
//always @ (posedge CLK_IN) begin
//    if (COUNT == 'd39) begin   // 2us/0.5MHz
    //if (COUNT == 'd199) begin   // 10us/100kHz
//        CLK_OUT <= ~CLK_OUT;
//        COUNT <= 0;
//    end else begin
//        COUNT <= COUNT + 9'd1;
//    end
//end

endmodule

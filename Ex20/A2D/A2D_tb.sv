module A2D_tb();

logic clk, rst_n, SS_n, SCLK, MOSI, MISO;
logic nxt;
logic [11:0] lft_ld, rght_ld, steer_pot, batt;

A2D_Intf iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .nxt(nxt),
    .lft_ld(lft_ld),
    .rght_ld(rght_ld),
    .steer_pot(steer_pot),
    .batt(batt),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO)
);

ADC128S ADC(
    .clk(clk),
    .rst_n(rst_n),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO)
);

initial begin

    clk = 0;
    rst_n = 0;

    nxt = 0;

    @(posedge clk);

    rst_n = 1;

    @(posedge clk);

    nxt = 1;

    @(posedge clk);



end

always #10 clk = ~clk;

endmodule
module piezo_drv_tb();

logic batt_low;
logic too_fast;
logic en_steer;
logic clk;
logic rst_n;
logic piezo;
logic piezo_n;

piezo_drv #(.FAST_SIM(1)) iDUT(
    .batt_low(batt_low),
    .too_fast(too_fast),
    .en_steer(en_steer),
    .clk(clk),
    .rst_n(rst_n),
    .piezo(piezo),
    .piezo_n(piezo_n)
);

initial begin

    clk = 0;
    rst_n = 0;

    @(posedge clk);

    rst_n = 1;
    // batt_low = 0;
    // too_fast = 0;
    // en_steer = 1;


    batt_low = 1;
    too_fast = 0;
    en_steer = 0;

    


end

always #20000000 clk <= ~clk; // 50 MHz

endmodule
module inertial_integrator_tb();
    
    localparam PTCH_RT_OFFSET = 16'h0050;

    logic clk;
    logic rst_n;
    logic vld;
    logic signed [15:0] ptch_rt;
    logic signed [15:0] AZ;
    logic signed [15:0] ptch;
    logic signed [15:0] prev_ptch;
    logic err;

    // instantiate DUT
    inertial_integrator iDUT(
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch_rt(ptch_rt),
        .AZ(AZ),
        .ptch(ptch)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        vld = 0;
        ptch_rt = PTCH_RT_OFFSET;
        AZ = 16'h0000;
        err = 0;

    @(posedge clk);             // hold reset for one rising edge 
    @(negedge clk) rst_n = 1;   // release on negedge 

    /*
    After reset has deasserted, apply ptch_rt = (16’h1000 + PTCH_RT_OFFSET) and AZ = 16’h0000. 
    Ensure vld is held high. Maintain this stimulus for 500 clocks. 
    The ptch output should be moving negative since we integrate the negative of ptch_rt.
    */
    ptch_rt = 16'h1000 + PTCH_RT_OFFSET;
    vld = 1;
    repeat(500) @(posedge clk);
    @(negedge clk);
    if (ptch >= 0) begin
        $display("Error: ptch output should be moving negative, is %d", ptch);
        err = 1;
    end
    
    /*
    Zero out the pitch rate by applying a value of ptch_rt = PTCH_RT_OFFSET.
    Hold for 1000 clocks. Due to the fusion with the AZ reading of 0, 
    You should see ptch reading trending slowly back towards 0.
    */
    prev_ptch = ptch;
    ptch_rt = PTCH_RT_OFFSET;
    repeat(1000) @(posedge clk);
    @(negedge clk);
    if (!((ptch > prev_ptch) && (ptch < 0))) begin
        $display("Error: ptch should trend from %d to 0, is %d", prev_ptch, ptch);
        err = 1;
    end 

    /*
    Set ptch_rt = (PTCH_RT_OFFSET – 16’h1000) for 500 clocks. 
    The ptch output should trend steeply into positive territory.
    */
    ptch_rt = PTCH_RT_OFFSET - 16'h1000;
    repeat(500) @(posedge clk);
    @(negedge clk);
    if (ptch <= 0) begin
      $display("Error: ptch should be positive, is %d", ptch);
      err = 1;
    end

    /*
    Zero out the pitch rate by setting ptch_rt = PTCH_RT_OFFSET, and hold for 1000 clocks. 
    The ptch output should be trending slowly back toward zero.
    */
    prev_ptch = ptch;
    ptch_rt = PTCH_RT_OFFSET;
    repeat(1000) @(posedge clk);
    @(negedge clk);
    if (!((ptch < prev_ptch) && (ptch > 0))) begin
        $display("Error: ptch should trend from %d to 0, is %d", prev_ptch, ptch);
        err = 1;
    end

    /*
    AZ = 16’h0800. When ptch gets down to about 100, 
    it should level off as the ptch calculated from AZ should match that from fusion 
    and the offset should start toggling back and forth from -1024 to +1024.
    */
    AZ = 16'h0800;
    repeat(1000) @(posedge clk);
    @(negedge clk);
    if ((ptch < iDUT.ptch_acc - 1) || (ptch > iDUT.ptch_acc + 1)) begin
        $display("Error: ptch should settle at %d, is %d", iDUT.ptch_acc, ptch);
        err = 1;
    end

    if (!err)
        $display("All tests passed");

    $stop();
    end

    always #5 clk = ~clk;

endmodule
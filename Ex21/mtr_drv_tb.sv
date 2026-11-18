module mtr_drv_tb();

    logic clk,rst_n;
    logic [11:0] lft_spd, rght_spd;	// 12-bit signed (negative is reverse)
    logic OVR_I_lft, OVR_I_rght;
    logic PWM1_lft, PWM2_lft, PWM1_rght, PWM2_rght;
    logic OVR_I_shtdwn;


    mtr_drv iDUT(clk,rst_n,lft_spd,rght_spd,OVR_I_lft,OVR_I_rght,PWM1_lft,
               PWM2_lft,PWM1_rght,PWM2_rght,OVR_I_shtdwn);

    
    initial begin
        rst_n = 1'b0;
        OVR_I_lft = 1'b0;
        OVR_I_rght = 1'b0;
        lft_spd = 12'd0;
        rght_spd = 12'd0;

        repeat(3) @(negedge clk);
        rst_n = 1;
        lft_spd = 12'h200;
        rght_spd = 12'hE00;

        @(posedge iDUT.PWM_synch);
        @(negedge clk);

        //Inside window lft test
        for (int i = 0; i < 45; i++) begin
            @(posedge iDUT.PWM_synch);

            //Left blanking window
            wait (iDUT.ovr_I_blank_L == 1'b1);
            @(negedge clk);

            //Assert OVR_I_lft inside window
            OVR_I_lft = 1'b1;
            repeat(3) @(posedge clk);
            OVR_I_lft = 1'b1;

            if (OVR_I_shtdwn !== 1'b0) begin
                $display("FAILED: OVR_I_shtdwn asserted in lft blanking window");
                $stop();
            end
        end

        @(posedge iDUT.PWM_synch);
        @(negedge clk);

        //Inside window rght test
        for (int i = 0; i < 45; i++) begin
            @(posedge iDUT.PWM_synch);

            //Right blanking window
            wait (iDUT.ovr_I_blank_R == 1'b1);
            @(negedge clk);

            //Assert OVR_I_rght inside window
            OVR_I_rght = 1'b1;
            repeat(3) @(posedge clk);
            OVR_I_rght = 1'b1;

            if (OVR_I_shtdwn !== 1'b0) begin
                $display("FAILED: OVR_I_shtdwn asserted in rght blanking window");
                $stop();
            end
        end

        @(posedge iDUT.PWM_synch);
        @(negedge clk);

        for (int i = 0; i < 45; i++) begin
            
            @(posedge iDUT.PWM_synch);

            wait ((iDUT.ovr_I_blank_L == 1'b0) && (iDUT.ovr_I_blank_R));
            @(negedge clk);

            //Alternate rght and lft OVR signals outside window
            if (i%2 == 0) begin
                OVR_I_lft = 1'b1;
                repeat(3) @(negedge clk);
                OVR_I_lft = 1'b0;
            end else begin
                OVR_I_rght = 1'b1;
                repeat(3) @(negedge clk);
                OVR_I_rght = 1'b0;
            end
        end

        repeat (5) @(negedge clk);

        if (OVR_I_shtdwn !== 1'b1) begin
            $display("FAILED: OVR_I_shtdwn should be asserted when OVR_I.. asserted outside of window");
            $stop();
        end

        $display("YAHOO! All tests passed!");
        $stop();

    end


    initial begin
        clk = 1'b0;
    end
    always #5 clk = ~clk;





endmodule
module A2D_Intf(
    input clk,
    input rst_n,
    output lft_ld[11:0],
    output rght_ld[11:0],
    output steer_pot[11:0],
    output batt[11:0],
    output SS_n,
    output SCLK,
    output MOSI,
    input MISO
);

    //Note: channel is represented as 2 bits where
    //Channel 0: 2'b00
    //Channel 4: 2'b01
    //Channel 5: 2'b10
    //Channel 6: 2'b11
    logic [1:0] channel;

    always_ff(@posedge clk) begin
        if (!rst_n) begin
            channel <= 2'b00;
        end
        else if (update) begin
            //Loop back around
            if (channel == 2'b11) begin
                channel <= 2'b00;
            end
            //Update normally
            else begin
                channel <= channel + 1;
            end
        end
    end



endmodule
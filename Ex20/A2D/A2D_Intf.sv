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

    logic [15:0] wt_data;



    //Note: channel is mapped to the 2 bits of robin_cnt
    //Channel 0: 2'b00
    //Channel 4: 2'b01
    //Channel 5: 2'b10
    //Channel 6: 2'b11
    logic [1:0] robin_cnt;

    always_ff(@posedge clk) begin
        if (!rst_n) begin
            robin_cnt <= 2'b00;
        end
        else if (update) begin
            //Loop back around
            if (robin_cnt == 2'b11) begin
                robin_cnt <= 2'b00;
            end
            //Update normally
            else begin
                robin_cnt <= robin_cnt + 1;
            end
        end
    end


    //Channel combinational logic
    logic lft_ld_en, rght_ld_en, steer_pot_en, batt_en;
    logic [2:0] channel;

    always_comb begin

        lft_ld_en = 1'b0;
        rght_ld_en = 1'b0;
        steer_pot_en = 1'b0;
        batt_en = 1'b0;

        channel = 3'b000; //Default channel

        if (update) begin

            case(robin_cnt)
                2'b00:
                    channel = 3'b000;
                    lft_ld_en = 1'b1;
                2'b01:
                    channel = 3'b100;
                    rght_ld_en = 1'b1;
                2'b10:
                    channel = 3'b101;
                    steer_pot_en = 1'b1;
                2'b11:
                    channel = 3'b110;
                    batt_en = 1'b1;
            endcase
        end

        //Create wt_data bus TODO: Not finished
        wt_data[13:11] = channel;
    end


    //TODO: How to get rd_data?



endmodule
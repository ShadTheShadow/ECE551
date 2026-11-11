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

    //SPI signals
    logic [15:0] wt_data;
    logic [15:0] rd_data;

    //FSM signals
    logic update;
    logic done;



    //Note: channel is mapped to the 2 bits of robin_cnt
    //Channel 0: 2'b00
    //Channel 4: 2'b01
    //Channel 5: 2'b10
    //Channel 6: 2'b11
    logic [1:0] robin_cnt;

    always_ff @(posedge clk) begin
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
    logic lft_ld_en;
    logic rght_ld_en;
    logic steer_pot_en;
    logic batt_en;
    logic [2:0] channel;

    always_comb begin

        lft_ld_en = 1'b0;
        rght_ld_en = 1'b0;
        steer_pot_en = 1'b0;
        batt_en = 1'b0;

        channel = 3'b000; //Default channel

        if (update) begin

            case(robin_cnt)
                2'b00: begin
                    channel = 3'b000;
                    lft_ld_en = 1'b1;
                end
                2'b01: begin
                    channel = 3'b100;
                    rght_ld_en = 1'b1;
                end
                2'b10: begin
                    channel = 3'b101;
                    steer_pot_en = 1'b1;
                end
                2'b11: begin
                    channel = 3'b110;
                    batt_en = 1'b1;
                end
            endcase
        end

        //wt_data bus -> SPI
        wt_data = {2'b00,channel[2:0],11'h00}
    end



    logic [11:0] lft_ld;
    logic [11:0] rght_ld;
    logic [11:0] steer_pot;
    logic [11:0] batt;


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            lft_ld <= 11'd0;
        end
        else if (lft_ld_en) begin
            lft_ld <= rd_data[11:0];
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rght_ld <= 11'd0;
        end
        else if (rght_ld_en) begin
            rght_ld <= rd_data[11:0];
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            steer_pot <= 11'd0;
        end
        else if (steer_pot_en) begin
            steer_pot <= rd_data[11:0];
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            batt <= 11'd0;
        end
        else if (batt_en) begin
            batt <= rd_data[11:0];
        end
    end


endmodule
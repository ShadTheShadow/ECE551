`default_nettype none

module A2D_Intf(
    input wire clk,
    input wire rst_n,
    input wire nxt,
    output reg [11:0] lft_ld,
    output reg [11:0] rght_ld,
    output reg [11:0] steer_pot,
    output reg [11:0] batt,
    output wire SS_n,
    output wire SCLK,
    output wire MOSI,
    input wire MISO
);

    //SPI signals
    logic [15:0] wt_data, rd_data;
    logic wrt;                      // Input signals
     //FSM signals
    logic update;
    logic done;

    // SPI Instance
    SPI_main SPI(
        .clk(clk),
        .rst_n(rst_n),
        .MISO(MISO),
        .wrt(wrt),
        .wrt_data(wt_data),

        .done(done),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .rd_data(rd_data)
    );

    //Note: channel is mapped to the 2 bits of robin_cnt
    //Channel 0: 2'b00
    //Channel 4: 2'b01
    //Channel 5: 2'b10
    //Channel 6: 2'b11
    logic [1:0] robin_cnt, robin_cnt_nxt;

    assign robin_cnt_nxt = robin_cnt + 1;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            robin_cnt <= 2'b00;
        end
        else if (update) begin
            robin_cnt <= robin_cnt_nxt;
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

        case(robin_cnt)
            2'b00: begin
                channel = 3'b000;
                lft_ld_en = update;
            end
            2'b01: begin
                channel = 3'b100;
                rght_ld_en = update;
            end
            2'b10: begin
                channel = 3'b101;
                steer_pot_en = update;
            end
            2'b11: begin
                channel = 3'b110;
                batt_en = update;
            end
        endcase

        //wt_data bus -> SPI
        wt_data = {2'b00,channel[2:0],11'h00};
    end


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

    // FSM Definition 😊

    typedef enum {IDLE, CHANNEL, BUFF, READ} state_t;

    state_t state, nxt_state;

    // State Machine Register
    always_ff @(posedge clk) begin

        if (~rst_n) begin

            state <= IDLE;

        end else begin

            state <= nxt_state;

        end

    end

    // State Machine Next State
    always_comb begin

        // Zero, prevent latch
        update = 0;     // Update registers
        wrt = 0;        // Write SPI

        case (state)

            IDLE: begin

                if (nxt) begin

                    nxt_state = CHANNEL; 
                    wrt = 1;  

                end else begin

                    nxt_state = IDLE;

                end

            end

            CHANNEL: begin

                if (~done) begin

                    nxt_state = CHANNEL;

                end else begin

                    nxt_state = BUFF;
                    

                end

            end

            BUFF: begin

                wrt = 1;
                nxt_state = READ;

            end

            READ: begin

                if (~done) begin

                    nxt_state = READ;

                end else begin

                    nxt_state = IDLE;
                    update = 1;

                end

            end

            default nxt_state = IDLE;

        endcase

    end

endmodule
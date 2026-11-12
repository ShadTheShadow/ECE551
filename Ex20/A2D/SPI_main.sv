module SPI_main(
    input   logic clk,
    input   logic rst_n,
    input   logic MISO,
    input   logic wrt,
    input   logic [15:0] wrt_data,
    
    output  logic done,
    output  logic SS_n,
    output  logic SCLK,
    output  logic MOSI,
    output  logic [15:0] rd_data
);

// Logic Definition //

// SCLK signals:
logic [3:0] SCLK_div, SCLK_nxt; 

// SCLK decode:
logic smpl;
logic shft_imm; // FSM input

// Shift Register:
logic MISO_smpl, MISO_smpl_nxt, init;
logic [15:0] shft_reg, shft_reg_nxt;

// Front Porch
logic [1:0] SCLK_cnt;
logic fr_porch;

// Bit Counter:
logic [3:0] bit_ctr, bit_ctr_nxt;
logic done15; // FSM input

// FSM

typedef enum logic [1:0] {WAIT, INIT, TRANSMIT} state_t;
localparam SCLK_INIT = 4'b1011;
state_t state, nxt_state;
logic set_done, ld_SCLK, shft; // FSM Output


// SCLK definition //

assign SCLK_nxt = (ld_SCLK) ? SCLK_INIT : SCLK_div + 1;

always_ff @(posedge clk) begin

    SCLK_div <= SCLK_nxt;

end

// Front Porch Logic

always_ff @(posedge clk) begin

    if (wrt) begin

        SCLK_cnt = 0;

    end else if (SCLK) begin

        SCLK_cnt = SCLK_cnt + 1;

    end

    // else keep value

end

// Front porch after 2 cycles of sh_imm (also sclk)
assign fr_porch = ~(SCLK_cnt == 2'b1);

// Decode SCLK_div //

assign smpl = &{SCLK_div[3:1], ~SCLK_div[0]}; // at SCLK Rising next clk
assign shft_imm = &SCLK_div; // at SCLK falling next clk

always_ff @(posedge clk) begin

    SCLK = shft_imm || SS_n;

end

// Shift Register //

assign MISO_smpl_nxt = (smpl) ? MISO : MISO_smpl;

// MISO Sample Register
always_ff @(posedge clk) begin

    MISO_smpl <= MISO_smpl_nxt;

end

// Shift Register Input Select
always_comb begin

    casez ({init, shft})

        2'b00: begin // Do not shift, no init

            shft_reg_nxt = shft_reg;

        end

        2'b01: begin // No init, Shift

            shft_reg_nxt = {shft_reg[14:0], MISO_smpl};

        end

        default: begin // Init (2'b1x)

            shft_reg_nxt = wrt_data;

        end

    endcase

end

// Shift Register FF
always_ff @(posedge clk) begin

    shft_reg <= shft_reg_nxt;

end

assign MOSI = shft_reg[15]; // MSB of shift reg is MOSI

// Bit Counter //

assign bit_ctr_nxt = (init) ? 4'b0000 : (shft) ? bit_ctr + 1 : bit_ctr;

always_ff @(posedge clk) begin

    bit_ctr <= bit_ctr_nxt;

end

assign done15 = &bit_ctr;

// SPI FSM //

// SM FF
always_ff @(posedge clk) begin

    if (!rst_n) begin

        state <= WAIT;

    end else begin
    
        state <= nxt_state;

    end

end

// SM Logic
always_comb begin

    // Default to prevent latch
    set_done = 0;
    shft = 0;
    ld_SCLK = 0;
    init = 0;

    case (state)

        WAIT: begin

            set_done = 1;

            if (wrt) begin

                ld_SCLK = 1;
                init = 1;
                nxt_state = INIT;

            end else begin

                nxt_state = WAIT;

            end

        end

        INIT: begin

            if (SS_n) begin

                init = 1;

            end else begin
                
                nxt_state = TRANSMIT;

            end

        end

        TRANSMIT: begin
            
            if (shft_imm) begin

                shft = 1;

                if (done15) begin

                    set_done = 1;
                    nxt_state = WAIT;

                end else begin

                    nxt_state = TRANSMIT;

                end

            end else begin

                nxt_state = TRANSMIT;

            end

        end

        default: nxt_state = WAIT;

    endcase

end

// SR-FF for Done

always_ff @(posedge clk) begin

    if (!rst_n) begin

        done <= 0;

    end else begin

        if (init) begin

            done <= 0;

        end else if (set_done) begin

            done <= 1;

        end

    end

end

// SR-FF for SS_n

always_ff @(posedge clk) begin

    if (!rst_n) begin

        SS_n <= 1; // Reset to 1

    end else begin

        if (init) begin

            SS_n <= 0; // Init transmission

        end else if (set_done) begin

            SS_n <= 1; // End of transmission

        end

    end

end

assign rd_data = shft_reg;

endmodule
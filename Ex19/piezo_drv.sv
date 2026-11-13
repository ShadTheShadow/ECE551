`default_nettype none

module piezo_drv
#(parameter FAST_SIM = 0)
(
    input wire batt_low,
    input wire too_fast,
    input wire en_steer,
    input wire clk,
    input wire rst_n,
    output wire piezo,
    output wire piezo_n
);

//If FAST_SIM=1
        //3s/64
        //Notes should be 1/64 of normal length
        //All frequencies x64

    //Normal op,  en_steer
        //Charge every 3s

    //Too fast
        //Highest priority, plat first three ntotes continuously

    //batt_low && !too_fast
        //Backwards charge fanfare every 3s, regardless of en_steer

    //No inputs asserted
        //Silent


    //FSM
    typedef enum logic [3:0] {IDLE, WAIT_3, NOTE1, NOTE2, NOTE3, NOTE4, NOTE5, NOTE6} state_t;

    state_t state, nxt_state;

    // FSM Control Signals
    reg ld_note;

    // Signal Definitions
    reg [23:0] note_dur_tmr;
    wire [23:0] note_dur_nxt;
    wire note_dur_done;

    reg [25:0] note_freq_tmr;
    wire [25:0] note_freq_tmr_nxt;

    reg [17:0] curr_note_freq;
    wire [17:0] nxt_note_freq;  

    reg [23:0] tmr_3sec;
    wire [23:0] tmr_3sec_nxt;
    wire tmr_3sec_done;

    //State control
    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    localparam G6 = 18'd1568;
    localparam C7 = 18'd2093; // 2093 Hz = 24 Clock Cycles @ 50MHz
    localparam E7 = 18'd2637; // 2637 Hz = 19 Clock Cycles @ 50MHz
    localparam G7 = 18'd3136; // 3136 Hz = 16 Clock Cycles @ 50 MHz

    localparam EIGHTH =     {4'b0100, {20{1'b0}}}; // 2^23
    localparam DOTTED =     {4'b0110, {20{1'b0}}}; // 2^23 + 2^22
    localparam SIXTEENTH =  {4'b0010, {20{1'b0}}}; // 2^22
    localparam HALF =       {4'b1000, {20{1'b0}}}; // 2^24

    reg [17:0] note_freq; // TODO FIND BITWIDTH
    reg [23:0] note_dur;

    logic ld_tmr;

    always_comb begin

        note_freq = 0;
        note_dur = 0;
        ld_tmr = 0;
        ld_note = 0;

        nxt_state = IDLE;

        case(state)

            // Each state loads the next note
            // and then transitions to that note's state
            IDLE: begin
                if (too_fast) begin

                    note_freq = G6;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    
                    nxt_state = NOTE1;

                end else if (batt_low) begin

                    note_freq = G7;
                    note_dur = HALF;
                    ld_note = 1;

                    nxt_state = NOTE1;

                end else if (en_steer) begin

                    note_freq = G6;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    nxt_state = NOTE1;

                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end

            end
            WAIT_3: begin

                
                if (~tmr_3sec_done) begin

                    nxt_state = WAIT_3;
                    
                end else if (too_fast) begin

                    note_freq = G6;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    
                    nxt_state = NOTE1;

                end else if (batt_low) begin

                    note_freq = G7;
                    note_dur = HALF;
                    ld_note = 1;

                    nxt_state = NOTE1;

                end else if (en_steer) begin

                    note_freq = G6;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    nxt_state = NOTE1;

                end else begin

                    ld_note = 1;

                    nxt_state = IDLE;
                    
                end

            end
            NOTE1 : begin
                
                if (~note_dur_done) begin

                    nxt_state = NOTE1;

                end else if (too_fast) begin

                    note_freq = C7;
                    note_dur = EIGHTH;
                    ld_note = 1;

                    nxt_state = NOTE2;
                    
                end else if (batt_low) begin

                    note_freq = E7;
                    note_dur = EIGHTH;
                    ld_note = 1;

                    nxt_state = NOTE2;
                    
                end else if (en_steer) begin

                    note_freq = C7;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    nxt_state = NOTE2;
                    
                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end
                
            end
            NOTE2 : begin
                
                if (~note_dur_done) begin

                    nxt_state = NOTE2;

                end else if (too_fast) begin

                    note_freq = E7;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    nxt_state = NOTE3;
                    
                end else if (batt_low) begin

                    note_freq = G7;
                    note_dur = HALF;
                    ld_note = 1;

                    nxt_state = NOTE3;
                    
                end else if (en_steer) begin

                    note_freq = E7;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    nxt_state = NOTE3;
                    
                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end

            end
            NOTE3 : begin

                if (~note_dur_done) begin

                    nxt_state = NOTE3;

                end else if (too_fast) begin

                    note_freq = G6;
                    note_dur = EIGHTH;
                    ld_note = 1;
                    
                    nxt_state = NOTE1;
                    
                end else if (batt_low) begin

                    note_freq = E7;
                    note_dur = EIGHTH;
                    ld_note = 1;

                    nxt_state = NOTE4;
                    
                end else if (en_steer) begin

                    note_freq = G7;
                    note_dur = DOTTED;
                    ld_note = 1;
                    nxt_state = NOTE4;
                    
                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end
                
            end
            NOTE4 : begin

                if (~note_dur_done) begin

                    nxt_state = NOTE4;

                end else if (batt_low) begin

                    note_freq = C7;
                    note_dur = EIGHTH;
                    ld_note = 1;

                    nxt_state = NOTE5;
                    
                end else if (en_steer) begin

                    note_freq = E7;
                    note_dur = SIXTEENTH;
                    ld_note = 1;
                    nxt_state = NOTE5;
                    
                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end
              
            end
            NOTE5 : begin

                if (~note_dur_done) begin

                    nxt_state = NOTE5;

                end else if (batt_low) begin

                    note_freq = G6;
                    note_dur = EIGHTH;
                    ld_note = 1;

                    nxt_state = NOTE6;
                    
                end else if (en_steer) begin

                    note_freq = G7;
                    note_dur = HALF;
                    ld_note = 1;

                    nxt_state = NOTE6;
                    
                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end
        
            end
            NOTE6 : begin

                if (~note_dur_done) begin

                    nxt_state = NOTE6;

                end else if (batt_low) begin

                    nxt_state = WAIT_3;
                    ld_note = 1;
                    ld_tmr = 1;
                    
                end else if (en_steer) begin

                    nxt_state = WAIT_3;
                    ld_note = 1;
                    ld_tmr = 1;
                    
                end else begin

                    ld_note = 1;
                    nxt_state = IDLE;

                end
            
            end

            default: nxt_state = IDLE; 

        endcase

    end

    //Notes
    //Treat triplets as eighth notes

    // Counters

// FPGA is 50 mhz

localparam TMR_3SEC = 18'd150000000; // 50MHz * 3 for 3 seconds
localparam FPGA_FREQ = 50000000; // 50MHZ

generate

    if (FAST_SIM) begin

        wire [23:0] note_dur_scaled = (note_dur / 64);

        assign note_dur_nxt = (ld_note) ? note_dur_scaled : (|note_dur_tmr) ? note_dur_tmr - 1 : 0;

    end else begin

        assign note_dur_nxt = (ld_note) ? note_dur : (|note_dur_tmr) ? note_dur_tmr - 1 : 0;

    end

endgenerate

assign note_dur_done = ~(|note_dur_tmr);

// Note Duration Timer //
always_ff @(posedge clk) begin
    
    if (~rst_n) begin

        note_dur_tmr <= 0;
        
    end else begin

        note_dur_tmr <= note_dur_nxt;

    end

end

// Frequency Timer //

generate

    if (FAST_SIM) begin
        // Frequency is multiplied by 64 for FAST_SIM

        wire [25:0] note_freq_scaled = (curr_note_freq * 64);

        assign note_freq_tmr_nxt = ((note_freq_tmr > FPGA_FREQ) ? 0 : note_freq_tmr + note_freq_scaled);

    end else begin
        // Add frequency until note_freq_tmr > FPGA_FREQ
        assign note_freq_tmr_nxt = ((note_freq_tmr > FPGA_FREQ) ? 0 : note_freq_tmr + curr_note_freq);

    end

endgenerate

assign nxt_note_freq = (ld_note) ? note_freq : curr_note_freq;

// Note Frequency Register
always_ff @(posedge clk) begin
    
    if (~rst_n) begin

        curr_note_freq <= 0;

    end else begin

        curr_note_freq <= nxt_note_freq;

    end

end

// Frequency Timer
always_ff @(posedge clk) begin

    if (~rst_n) begin

        note_freq_tmr <= 0;

    end else begin

        note_freq_tmr <= note_freq_tmr_nxt;

    end

end

// Wait 3 Seconds Timer
always_ff @(posedge clk) begin

    if (~rst_n) begin

        tmr_3sec <= 0;

    end else begin

        tmr_3sec <= tmr_3sec_nxt;

    end

end

// 3 Second Timer //

generate

    if (FAST_SIM) begin

        wire [23:0] ld_tmr_3sec_scaled = (TMR_3SEC / 6);

        assign tmr_3sec_nxt = (ld_tmr) ? ld_tmr_3sec_scaled : (|tmr_3sec) ? tmr_3sec - 1 : 0;

    end else begin

        assign tmr_3sec_nxt = (ld_tmr) ? TMR_3SEC : (|tmr_3sec) ? tmr_3sec - 1 : 0;

    end

endgenerate

assign tmr_3sec_done = ~(|tmr_3sec); // All bits 0

//assign ld_note = ~(|note_dur_tmr); // Load new note when dur timer is 0

assign piezo = (note_freq_tmr > 25000);
assign piezo_n = ~piezo;

endmodule
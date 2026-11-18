module PWM11(
    input clk,
    input rst_n,
    input [10:0] duty,
    output reg PWM1,
    output reg PWM2,
    output PWM_synch,
    output ovr_I_blank
);


    localparam [10:0] NONOVERLAP = 11'h040;

    logic [10:0] cnt = 11'h000;


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
        end
        else begin
            cnt <= cnt + 1;
        end
    end 


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            PWM2 <= 1'b0;
        end
        else if (&cnt) begin
            PWM2 <= 1'b0;
        end
        else if (cnt>=(duty+NONOVERLAP)) begin
            PWM2 <= 1'b1;
        end
    end


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            PWM1 <= 1'b0;
        end
        else if (cnt>=duty) begin
            PWM1 <= 1'b0;
        end
        else if (cnt>=NONOVERLAP) begin
            PWM1 <= 1'b1;
        end
    end


    assign PWM_synch = ~|cnt;

    assign ovr_I_blank = ((NONOVERLAP<cnt && cnt<NONOVERLAP+128) || ((NONOVERLAP+duty)<cnt && cnt <(NONOVERLAP+duty+128)));





endmodule
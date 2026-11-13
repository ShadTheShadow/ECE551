module rst_synch(
    input clk,
    input RST_n,
    output reg rst_n
);

    logic w0;

    always_ff @(negedge clk) begin
        if(!RST_n) begin
            w0 <= 1'b0;
        end
        else begin
            w0 <= 1'b1;
        end
    end

    always_ff @(negedge clk) begin
        if(!RST_n) begin
            rst_n <= 1'b0;
        end
        else begin
            rst_n <= w0;
        end
    end


endmodule
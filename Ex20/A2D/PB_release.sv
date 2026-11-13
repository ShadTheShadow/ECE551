module PB_release(
    input clk,
    input rst_n,
    input PB,
    output released
);

    logic w0, w1, w2;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            w0 <= 1'b0;
        end
        else begin
            w0 <= PB;
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            w1 <= 1'b0;
        end
        else begin
            w1 <= w0;
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            w2 <= 1'b0;
        end
        else begin
            w2 <= w1;
        end
    end

    assign released = ~w2 && w1;


endmodule
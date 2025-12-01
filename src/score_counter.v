// =============================================================
// score_counter.v — BCD-räknare (00..99) som ökar på eat_evt
// =============================================================
module score_counter(
    input  wire clk_pix,
    input  wire reset_n,
    input  wire eat_evt,        // puls från collision
    output reg  [3:0] tens = 4'd0,
    output reg  [3:0] ones = 4'd0
);
    always @(posedge clk_pix) begin
        if (!reset_n) begin
            ones <= 4'd0;
            tens <= 4'd0;
        end else if (eat_evt) begin
            if (ones == 4'd9) begin
                ones <= 4'd0;
                tens <= (tens == 4'd9) ? 4'd0 : (tens + 4'd1);
            end else begin
                ones <= ones + 4'd1;
            end
        end
    end
endmodule

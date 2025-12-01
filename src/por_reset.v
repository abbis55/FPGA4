// Enkel power-on-reset: håller reset_n låg en liten stund efter power-up
module por_reset #(
    parameter integer BITS = 20  // ~ (2^BITS)/clk_pix sekunder
) (
    input  wire clk,            // använd clk_pix
    output reg  reset_n = 1'b0
);
  reg [BITS:0] cnt = {(BITS + 1) {1'b0}};

  always @(posedge clk) begin
    if (!reset_n) begin
      cnt <= cnt + 1'b1;
      if (cnt[BITS]) reset_n <= 1'b1;  // släpp reset efter en stund
    end
  end
endmodule

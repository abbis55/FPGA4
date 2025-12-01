// Ger en 1-cykel bred puls "tick" STEP_HZ gånger per sekund
module game_tick #(
    parameter integer STEP_HZ = 5,          // t.ex. 5 steg/s
    parameter integer CLK_HZ  = 25_000_000  // pixelklockan (clk_pix) ≈ 25 MHz
) (
    input  wire clk,      // mata in clk_pix här
    output reg  tick = 0
);
  localparam integer DIV = CLK_HZ / STEP_HZ;
  reg [$clog2(DIV)-1:0] cnt = 0;

  always @(posedge clk) begin
    tick <= 1'b0;
    if (cnt == DIV - 1) begin
      cnt  <= 0;
      tick <= 1'b1;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end
endmodule

// lfsr_random.v – 16-bit LFSR, frihjulande på clk_pix
module lfsr_random(
  input  wire       clk,
  input  wire       reset_n,
  output reg [15:0] rnd = 16'hACE1   // <- icke-noll startvärde
);
  wire feedback = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10]; // taps för x^16 + x^14 + x^13 + x^11 + 1
  always @(posedge clk) begin
    if (!reset_n)
      rnd <= 16'hACE1;          // viktigt: INTE 0
    else
      rnd <= {rnd[14:0], feedback};
  end
endmodule

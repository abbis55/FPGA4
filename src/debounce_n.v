module debounce_n #(
    parameter integer CNT_MAX = 250_000  // ~10 ms @ 25 MHz
) (
    input  wire clk,     // använd clk_pix
    input  wire in_n,    // rå knapp, aktiv-låg
    output reg  out_n = 1'b1  // debouncad nivå, aktiv-låg
);
  // 2-stegs synk för metastabilitet
  reg s0 = 1'b1, s1 = 1'b1;
  always @(posedge clk) begin
    s0 <= in_n;
    s1 <= s0;
  end

  // räknare: uppdatera ut först när ingången varit stabil tillräckligt länge
  reg [$clog2(CNT_MAX):0] cnt = 0;
  always @(posedge clk) begin
    if (s1 == out_n) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1'b1;
      if (cnt == CNT_MAX) begin
        out_n <= s1;
        cnt   <= 0;
      end
    end
  end
endmodule

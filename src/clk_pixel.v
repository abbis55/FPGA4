module clk_pixel (
    input  wire clk50,       // 50 MHz från DE10-Lite
    output reg  clk_pix = 0
);
  always @(posedge clk50) clk_pix <= ~clk_pix;
endmodule

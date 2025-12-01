module vga_640x480 (
    input  wire       clk_pix,
    output reg  [9:0] x = 0,       // 0..799
    output reg  [9:0] y = 0,       // 0..524
    output wire       hsync,
    output wire       vsync,
    output wire       displayArea
);
  localparam H_VISIBLE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48, H_TOTAL = 800;
  localparam V_VISIBLE = 480, V_FP = 10, V_SYNC = 2, V_BP = 33, V_TOTAL = 525;

  always @(posedge clk_pix) begin
    if (x == H_TOTAL - 1) begin
      x <= 0;
      y <= (y == V_TOTAL - 1) ? 0 : y + 1;
    end else begin
      x <= x + 1;
    end
  end

  assign hsync = ~((x >= H_VISIBLE + H_FP) && (x < H_VISIBLE + H_FP + H_SYNC));  // negativ
  assign vsync = ~((y >= V_VISIBLE + V_FP) && (y < V_VISIBLE + V_FP + V_SYNC));  // negativ
  assign displayArea = (x < H_VISIBLE) && (y < V_VISIBLE);
endmodule

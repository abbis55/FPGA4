// snake_head.v — håller koll på ormens huvud och flyttar på tick
/* module snake_head #(
  parameter integer CELL = 10
)(
  input  wire       clk_pix,
  input  wire       tick,
  input  wire       reset_n,        // aktiv låg reset (kan kopplas till 1'b1)
  input  wire [1:0] dir,            // 0=UP,1=LEFT,2=DOWN,3=RIGHT
  output reg  [9:0] x = 10'd320,
  output reg  [9:0] y = 10'd240
);

  // Spelplan: 640x480 med 10 px border => 10..620 och 10..460
  localparam integer X_MIN = 10;
  localparam integer X_MAX = 630-10;  // 620
  localparam integer Y_MIN = 10;
  localparam integer Y_MAX = 470-10;  // 460

  always @(posedge clk_pix) begin
    if (!reset_n) begin
      x <= 10'd320;
      y <= 10'd240;
    end else if (tick) begin
      case (dir)
        2'd0: y <= (y <= Y_MIN) ? Y_MAX : (y - CELL);  // UP
        2'd1: x <= (x <= X_MIN) ? X_MAX : (x - CELL);  // LEFT
        2'd2: y <= (y >= Y_MAX) ? Y_MIN : (y + CELL);  // DOWN
        2'd3: x <= (x >= X_MAX) ? X_MIN : (x + CELL);  // RIGHT
        default: ; // behåll
      endcase
    end
  end

endmodule */

// =============================================================
// snake_render_segments.v — Renderar head/body/apple/border
// Tar latchede koordinater och ger pixelmasker för VGA-mixern
// =============================================================
module snake_render_segments #(
    parameter integer CELL     = 10,
    parameter integer GRID_W   = 64,
    parameter integer GRID_H   = 48,
    parameter integer MAX_LEN  = 33,  // = MAX_BODY+1 (i din top: 32+1)
    parameter integer BORDER_X = 10,
    parameter integer BORDER_Y = 10
) (
    input wire       disp,  // displayArea från VGA
    input wire [9:0] x,     // VGA x
    input wire [8:0] y,     // VGA y

    // Latchede värden från top (frame_start-latch)
    input wire [9:0] head_x_d,
    input wire [8:0] head_y_d,
    input wire [9:0] apple_x_d,
    input wire [8:0] apple_y_d,
    input wire [7:0] snake_len_d,
    input wire [MAX_LEN*10-1:0] body_bus_x_d,
    input wire [MAX_LEN*9 -1:0] body_bus_y_d,

    // Pixelmasker (till färgmixern i top)
    output wire head_px,
    output wire body_px,
    output wire apple_px,
    output wire border_px
);
  // Härledda konstanter (spelplan)
localparam [9:0] MAX_X = 10'd620; // vid GRID_W=64, CELL=10
localparam [8:0] MAX_Y = 9'd460;  // vid GRID_H=48, CELL=10


  // Hjälp att bredda Y till 10 bit för +CELL
  wire [9:0] hy10 = {1'b0, head_y_d};
  wire [9:0] ay10 = {1'b0, apple_y_d};
  wire [9:0] y10 = {1'b0, y};

  // Huvud
  assign head_px = disp &&
                     (x >= head_x_d) && (x < head_x_d + CELL) &&
                     (y10 >= hy10)   && (y10 < hy10 + CELL);

  // Kroppen: OR över segment 1..snake_len_d-1 (konstant loopgräns, gatas invändigt)
  integer k;
  reg body_hit_cell;
  always @* begin
    body_hit_cell = 1'b0;
    for (k = 1; k < MAX_LEN; k = k + 1) begin
      if (k < snake_len_d) begin
        body_hit_cell = body_hit_cell |
                    ( (x >= body_bus_x_d[(MAX_LEN-k)*10-1 -: 10]) &&
                      (x <  body_bus_x_d[(MAX_LEN-k)*10-1 -: 10] + CELL) &&
                      (y10 >= {1'b0, body_bus_y_d[(MAX_LEN-k)*9-1 -: 9]}) &&
                      (y10 <  {1'b0, body_bus_y_d[(MAX_LEN-k)*9-1 -: 9]} + CELL) );
      end
    end
  end
  assign body_px = disp && body_hit_cell;

  // Äpple
  assign apple_px = disp &&
                      (x >= apple_x_d) && (x < apple_x_d + CELL) &&
                      (y10 >= ay10)    && (y10 < ay10 + CELL);

  // Vit ram
  assign border_px =
        disp && (
            (x < BORDER_X) ||
            (x >= MAX_X + CELL) ||
            (y <  BORDER_Y) ||
            (y >= MAX_Y + CELL)
        );

endmodule

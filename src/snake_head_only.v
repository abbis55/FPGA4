// ===========================================================
//  snake_head_only.v — Minimal ormhuvud-modul
//  Startar i mitten av spelplanen och flyttar sig med tick
// ===========================================================

/* module snake_head_only #(
  parameter integer CELL     = 10,
  parameter integer GRID_W   = 64,   // 640 / 10
  parameter integer GRID_H   = 48    // 480 / 10
)(
  input  wire       clk_pix,   // pixelklocka (~25 MHz)
  input  wire       tick,      // spel-tick (ex. 5 Hz)
  input  wire       reset_n,   // aktiv låg reset
  input  wire [1:0] dir,       // 0=UP, 1=LEFT, 2=DOWN, 3=RIGHT
  output reg  [9:0] head_x,    // huvudets X-position
  output reg  [8:0] head_y,     // huvudets Y-position
  output wire       moved_once_out // -> blir 1 efter första rörelsen
);

  // --- Spelplanens gränser (10 px border)
  localparam [9:0] BORDER_X = 10'd10;
  localparam [8:0] BORDER_Y = 9'd10;
  localparam [9:0] MAX_X    = 10'd630;  // 640 - 10
  localparam [8:0] MAX_Y    = 9'd470;   // 480 - 10

  // --- Startposition: exakt mitten av skärmen
  localparam [9:0] START_X0 = 10'd310;
  localparam [8:0] START_Y0 = 9'd230;

  // --- Inre register för att undvika hopp på reset
  reg [1:0] dir_r = 2'd3;  // default höger
  reg       init_done = 1'b0;



  reg moved_once = 1'b0;  // start = false
assign moved_once_out = moved_once; // (om du vill skicka ut till apple_simple)


  always @(posedge clk_pix) begin
    if (!reset_n) begin
      head_x    <= START_X0;
      head_y    <= START_Y0;
      dir_r     <= 2'd3;      // höger
      init_done <= 1'b0;
      moved_once <= 1'b0;
    end 
    else if (!init_done) begin
      // första aktiva cykeln efter reset
      head_x    <= START_X0;
      head_y    <= START_Y0;
      init_done <= 1'b1;
      moved_once <= 1'b0;
    end
    else if (tick) begin
      dir_r <= dir;  // uppdatera riktning bara vid tick

      case (dir_r)
        2'd0: head_y <= (head_y <= BORDER_Y) ? BORDER_Y : (head_y - CELL); // UP
        2'd1: head_x <= (head_x <= BORDER_X) ? BORDER_X : (head_x - CELL); // LEFT
        2'd2: head_y <= (head_y >= MAX_Y)    ? MAX_Y    : (head_y + CELL); // DOWN
        2'd3: head_x <= (head_x >= MAX_X)    ? MAX_X    : (head_x + CELL); // RIGHT
      endcase
      // markera att vi har rört oss minst en gång
    moved_once <= 1'b1;
    end
  end

endmodule
 */
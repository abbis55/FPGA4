// snake_core.v — Verilog-2001-kompatibel "lite"-kärna
// Håller intern segmentlista, exponerar huvud + första kropp som portar.


module snake_core #(
  parameter integer CELL     = 10,
  parameter integer GRID_W   = 64,   // 640 / 10
  parameter integer GRID_H   = 48,   // 480 / 10
  parameter integer MAX_LEN  = 16
)(
  input  wire       clk_pix,
  input  wire       tick,            // spel-tick (t.ex. 5 Hz)
  input  wire       reset_n,         // aktiv låg
  input  wire [1:0] dir,             // 0=UP,1=LEFT,2=DOWN,3=RIGHT
  input  wire       eat_evt,         // väx vid äta
  output reg  [9:0] head_x,          // exponera huvudets x/y
  output reg  [8:0] head_y,
  output reg  [9:0] body1_x,         // exponera första kroppens x/y
  output reg  [8:0] body1_y,
  output reg  [7:0] length = 8'd3
);


  // Intern segmentlista (unpacked arrays är OK internt i Verilog-2001)
  reg [9:0] seg_x [0:MAX_LEN-1];
  reg [8:0] seg_y [0:MAX_LEN-1];


  // Gränser (innanför 10 px border)
  localparam [9:0] BORDER_X = 10'd10;
  localparam [8:0] BORDER_Y = 9'd10;
  localparam [9:0] MAX_X    = (GRID_W-2)*CELL; // 620
  localparam [8:0] MAX_Y    = (GRID_H-2)*CELL; // 460


  // Startposition (inte mitt)
  localparam [9:0] START_X0 = 10'd280;
  localparam [8:0] START_Y0 = 9'd240;


  integer i;


  // Init/reset + rörelse per tick
  always @(posedge clk_pix) begin
    if (!reset_n) begin
      length      <= 8'd3;
      seg_x[0]    <= START_X0;           seg_y[0]    <= START_Y0;
      seg_x[1]    <= START_X0 - CELL;    seg_y[1]    <= START_Y0;
      seg_x[2]    <= START_X0 - 2*CELL;  seg_y[2]    <= START_Y0;
      for (i = 3; i < MAX_LEN; i=i+1) begin
        seg_x[i]  <= START_X0 - 2*CELL;
        seg_y[i]  <= START_Y0;
      end
      head_x  <= START_X0;   head_y  <= START_Y0;
      body1_x <= START_X0 - CELL; body1_y <= START_Y0;
    end else if (tick) begin
      // 1) flytta kroppen (bakifrån)
      for (i = MAX_LEN-1; i > 0; i=i-1) begin
        if (i < length) begin
          seg_x[i] <= seg_x[i-1];
          seg_y[i] <= seg_y[i-1];
        end
      end
      // 2) flytta huvud
      case (dir)
        2'd0: seg_y[0] <= (seg_y[0] <= BORDER_Y) ? MAX_Y    : (seg_y[0] - CELL); // UP
        2'd1: seg_x[0] <= (seg_x[0] <= BORDER_X) ? MAX_X    : (seg_x[0] - CELL); // LEFT
        2'd2: seg_y[0] <= (seg_y[0] >= MAX_Y)    ? BORDER_Y : (seg_y[0] + CELL); // DOWN
        2'd3: seg_x[0] <= (seg_x[0] >= MAX_X)    ? BORDER_X : (seg_x[0] + CELL); // RIGHT
      endcase
      // 3) väx vid äta
      if (eat_evt && length < MAX_LEN)
        length <= length + 1'b1;


      // 4) uppdatera exporterade portar (huvud + första kropp)
      head_x  <= seg_x[0];  head_y  <= seg_y[0];
      body1_x <= (length > 1) ? seg_x[1] : seg_x[0];
      body1_y <= (length > 1) ? seg_y[1] : seg_y[0];
    end
  end


endmodule




// ===========================================================
// snake_core_grow.v — Kärna med växande kropp (Verilog-2001)
// Exponerar head_x/head_y/length + packade bussar för kroppen
// ===========================================================
module snake_core_grow #(
  parameter integer CELL    = 10,
  parameter integer GRID_W  = 64,   // 640/10
  parameter integer GRID_H  = 48,   // 480/10
  parameter integer MAX_LEN = 32
)(
  input  wire       clk_pix,
  input  wire       tick,
  input  wire       reset_n,       // aktiv låg
  input  wire [1:0] dir,           // 0=UP,1=LEFT,2=DOWN,3=RIGHT
  input  wire       eat_evt,       // 1-cykel-puls vid “ät”
  output reg  [9:0] head_x,
  output reg  [8:0] head_y,
  output reg  [7:0] length,

  // Packade bussar: [seg0][seg1]...[segN] (MSB=seg0)
  output wire [MAX_LEN*10-1:0] body_bus_x,
  output wire [MAX_LEN*9 -1:0] body_bus_y
);

  // Spelplanens gränser (10 px ram)
  localparam [9:0] BORDER_X = 10'd10;
  localparam [8:0] BORDER_Y = 9'd10;
  localparam [9:0] MAX_X    = (GRID_W-2)*CELL; // 620
  localparam [8:0] MAX_Y    = (GRID_H-2)*CELL; // 460

  // Start i mitten (justerat till 10x10-rutnät)
  localparam [9:0] START_X0 = 10'd370;
  localparam [8:0] START_Y0 = 9'd280;

  // Interna segmentlistor
  reg [9:0] seg_x [0:MAX_LEN-1];
  reg [8:0] seg_y [0:MAX_LEN-1];

  // lägg överst i deklarationerna
reg init_done = 1'b0;

  integer i;

  // Rörelse + väx
  always @(posedge clk_pix) begin
    if (!reset_n) begin
      length   <= 8'd2;               // huvud + 1 kropp
      seg_x[0] <= START_X0;
      seg_y[0] <= START_Y0;           // head
      seg_x[1] <= START_X0 - CELL;
      seg_y[1] <= START_Y0;           // body1 bakom
      for (i=2;i<MAX_LEN;i=i+1) begin
        seg_x[i] <= START_X0 - CELL;
        seg_y[i] <= START_Y0;
      end
      head_x <= START_X0;
      head_y <= START_Y0;
      init_done <= 1'b0;                       // <-- nollställ init-flagga
    end
    else if (!init_done) begin                 // <-- NY ENGÅNGS-INIT
    length   <= 8'd2;
    seg_x[0] <= START_X0;
    seg_y[0] <= START_Y0;
    seg_x[1] <= START_X0 - CELL;
    seg_y[1] <= START_Y0;
    head_x   <= START_X0;
    head_y <= START_Y0;
    init_done <= 1'b1;
  end
    else if (tick) begin
      // 1) skifta kroppen bakifrån
      for (i=MAX_LEN-1;i>0;i=i-1)
        if (i < length) begin
          seg_x[i] <= seg_x[i-1];
          seg_y[i] <= seg_y[i-1];
        end

      // 2) flytta huvud (kläm mot ram)
      case (dir)
        2'd0: seg_y[0] <= (seg_y[0] <= BORDER_Y) ? BORDER_Y : (seg_y[0] - CELL); // UP
        2'd1: seg_x[0] <= (seg_x[0] <= BORDER_X) ? BORDER_X : (seg_x[0] - CELL); // LEFT
        2'd2: seg_y[0] <= (seg_y[0] >= MAX_Y)    ? MAX_Y    : (seg_y[0] + CELL); // DOWN
        2'd3: seg_x[0] <= (seg_x[0] >= MAX_X)    ? MAX_X    : (seg_x[0] + CELL); // RIGHT
      endcase

        
        // 3) väx: duplicera svansen + öka length
if (eat_evt && (length < MAX_LEN)) begin
  // Duplicera SVANSENS gamla position så svansen "stannar" en tick
  seg_x[length] <= seg_x[length-1];
  seg_y[length] <= seg_y[length-1];
  length        <= length + 8'd1;
end

      // 4) exportera head
      head_x <= seg_x[0];
      head_y <= seg_y[0];
    end
  end

  // Packa ut bussarna: [seg0][seg1]...[segN] (MSB först)
  genvar gi;
  generate
    for (gi=0; gi<MAX_LEN; gi=gi+1) begin: PACK
      assign body_bus_x[(MAX_LEN-gi)*10-1 -: 10] = seg_x[gi];
      assign body_bus_y[(MAX_LEN-gi)*9 -1 -: 9 ] = seg_y[gi];
    end
  endgenerate

endmodule

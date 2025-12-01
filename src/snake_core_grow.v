

// ===========================================================
// snake_core_grow.v — Kärna utan tillväxt (fast längd = 2)
// Behåller gränssnittet (eat_evt-porten ignoreras)
// Exponerar head_x/head_y/length + packade bussar för kroppen
// ===========================================================
module snake_core_grow #(
  parameter integer CELL    = 10,
  parameter integer GRID_W  = 64,   // 640/10
  parameter integer GRID_H  = 48,   // 480/10


    parameter integer MAX_BODY = 32,                 // antal kroppar (exkl. huvud)
  parameter integer MAX_LEN  = MAX_BODY + 1        // total längd inkl. huvud


)(
  input  wire       clk_pix,
  input  wire       tick,
  input  wire       reset_n,       // aktiv låg
  input  wire [1:0] dir,           // 0=UP,1=LEFT,2=DOWN,3=RIGHT
  input  wire       eat_evt,     // 1-cykel-puls vid “ät” (IGNORERAS)
  output reg  [9:0] head_x,
  output reg  [8:0] head_y,
  output reg  [7:0] length,


  // Packade bussar: [seg0][seg1]...[segN] (MSB=seg0), seg0 = head
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
  // segment 0=head, 1..MAX_LEN-1 = kropp
  reg [9:0] seg_x [0:MAX_LEN-1];
  reg [8:0] seg_y [0:MAX_LEN-1];
  // nya register




reg       ate_latch;    // <-- fångar eat_evt tills nästa tick


  // Endast för engångs-init efter reset
  reg init_done = 1'b0;


  integer i;               // <-- behövs för for-looparna


    // fånga eat_evt mellan ticks
  always @(posedge clk_pix) begin
    if (!reset_n)      ate_latch <= 1'b0;
    else if (eat_evt)  ate_latch <= 1'b1;
    else if (tick)     ate_latch <= 1'b0; // nollställ efter att tick har hanterat den
  end






  always @(posedge clk_pix) begin
    if (!reset_n) begin
      length   <= 8'd3;          // start: head + 1 kropp
      seg_x[0] <= START_X0;
      seg_y[0] <= START_Y0;          // head
      seg_x[1] <= START_X0-CELL;
      seg_y[1] <= START_Y0;          // kropp 1
      for (i=2;i<MAX_LEN;i=i+1) begin
        seg_x[i] <= START_X0-CELL;
        seg_y[i] <= START_Y0;
      end
      head_x <= START_X0;
      head_y <= START_Y0;
      init_done <= 1'b0;


    end
    else if (!init_done) begin
      length   <= 8'd3;
      seg_x[0] <= START_X0;
      seg_y[0] <= START_Y0;
      seg_x[1] <= START_X0-CELL;
      seg_y[1] <= START_Y0;
      head_x   <= START_X0;
      head_y   <= START_Y0;
      init_done <= 1'b1;


    end else if (tick) begin
      // spara svansens GAMLA position innan skift
      reg [9:0] tail_old_x;
      reg [8:0] tail_old_y;
      tail_old_x = seg_x[length-1];
      tail_old_y = seg_y[length-1];


      // 1) skifta kroppen bakifrån (bara element < length)
      for (i=MAX_LEN-1; i>0; i=i-1)
        if (i < length) begin
          seg_x[i] <= seg_x[i-1];
          seg_y[i] <= seg_y[i-1];
        end


      // 2) flytta huvud (med kläm)
      case (dir)
        2'd0: seg_y[0] <= (seg_y[0] <= BORDER_Y) ? BORDER_Y : (seg_y[0] - CELL); // UP
        2'd1: seg_x[0] <= (seg_x[0] <= BORDER_X) ? BORDER_X : (seg_x[0] - CELL); // LEFT
        2'd2: seg_y[0] <= (seg_y[0] >= MAX_Y)    ? MAX_Y    : (seg_y[0] + CELL); // DOWN
        2'd3: seg_x[0] <= (seg_x[0] >= MAX_X)    ? MAX_X    : (seg_x[0] + CELL); // RIGHT
      endcase


      // 3) väx: duplicera SVANSENS gamla position
      if (ate_latch && (length < MAX_LEN)) begin
        seg_x[length] <= tail_old_x;
        seg_y[length] <= tail_old_y;
        length        <= length + 8'd1;
      end


      // 4) exportera head
      head_x <= seg_x[0];
      head_y <= seg_y[0];
    end
  end


  // packa bussarna: [seg0][seg1]...[segN] (MSB först)
  genvar gi;
  generate
    for (gi=0; gi<MAX_LEN; gi=gi+1) begin: PACK
      assign body_bus_x[(MAX_LEN-gi)*10-1 -: 10] = seg_x[gi];
      assign body_bus_y[(MAX_LEN-gi)*9 -1 -: 9 ] = seg_y[gi];
    end
  endgenerate


endmodule


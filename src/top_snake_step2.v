// =============================================================
// top_snake_step2.v — Snake med växande kropp + äpple (stabil ritning)
// =============================================================
module top_snake_step2 (
    input  wire       CLOCK_50,
    input  wire       BTN_UP_N,
    input  wire       BTN_LEFT_N,
    input  wire       BTN_DOWN_N,
    input  wire       BTN_RIGHT_N,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire       VGA_HS,
    output wire       VGA_VS
);




  // --- parametrar för top ---
  localparam integer CELL = 10;
  localparam integer GRID_W = 64;  // 640/10
  localparam integer GRID_H = 48;  // 480/10
  localparam integer MAX_BODY = 32;
  localparam integer MAX_LEN = MAX_BODY + 1;

  localparam [9:0] BORDER_X = 10;  // 10 px ram till vänster/höger
  localparam [8:0] BORDER_Y = 9'd10;  // 10 px ram upp/ner



  // === Pixelklocka ===
  wire clk_pix;
  clk_pixel u_clk (
      .clk50  (CLOCK_50),
      .clk_pix(clk_pix)
  );



  // === Reset ===
  wire reset_n;
  por_reset u_por (
      .clk(clk_pix),
      .reset_n(reset_n)
  );


  // === VGA-signal ===
  wire [9:0] x, y;
  wire hsync, vsync, disp;
  vga_640x480 u_vga (
      .clk_pix(clk_pix),
      .x(x),
      .y(y),
      .hsync(hsync),
      .vsync(vsync),
      .displayArea(disp)
  );
  assign VGA_HS = hsync;
  assign VGA_VS = vsync;


  // Bildrute-start (för latch)
  wire frame_start = (x == 10'd0) && (y == 10'd0);


  // === Speltick (ca 5 steg/s) ===
  wire tick;
  game_tick #(
      .STEP_HZ(5),
      .CLK_HZ (25_000_000)
  ) u_tick (
      .clk (clk_pix),
      .tick(tick)
  );

  wire eat_evt;  // ersätter gamla assign



  // === Snake core ===
  wire [9:0] head_x;
  wire [8:0] head_y;
  wire [7:0] snake_len;


  // === Apple ===
  wire [9:0] apple_x;
  wire [8:0] apple_y;


  collision #(
      .CELL(CELL)
  ) u_collision (
      .clk_pix(clk_pix),
      .reset_n(reset_n),
      .tick   (tick),
      .head_x (head_x),
      .head_y (head_y),
      .apple_x(apple_x),
      .apple_y(apple_y),
      .eat_evt(eat_evt)
  );



  // === Riktning ===
  wire [1:0] dir;
  input_controller_adv u_ctrl (
      .clk(clk_pix),
      .reset_n(reset_n),
      .up_n(BTN_UP_N),
      .left_n(BTN_LEFT_N),
      .down_n(BTN_DOWN_N),
      .right_n(BTN_RIGHT_N),
      .dir(dir)
  );




  // === Slumpgenerator ===
  wire [15:0] rnd;
  lfsr_random u_lfsr (
      .clk(clk_pix),
      .reset_n(reset_n),
      .rnd(rnd)
  );



  // === Snake core (med bussar) ===
  wire [MAX_LEN*10-1:0] body_bus_x;
  wire [MAX_LEN*9 -1:0] body_bus_y;

  // --- före instansen ---
  wire                  self_hit;
  reg                   game_over = 1'b0;


  // Latcha game_over på självkrock
  always @(posedge clk_pix) begin
    if (!reset_n) game_over <= 1'b0;
    else if (tick && self_hit) game_over <= 1'b1;
  end

  wire                  tick_run;  // deklaration
  assign tick_run = tick & ~game_over;  // definiera innan instansen

  snake_core_grow #(
      .CELL(CELL),
      .GRID_W(GRID_W),
      .GRID_H(GRID_H),
      .MAX_BODY(MAX_BODY),
      .MAX_LEN(MAX_LEN)
  ) u_snake (
      .clk_pix(clk_pix),
      .tick   (tick_run), // <--- använd gatad tick

      .reset_n(reset_n),
      .dir    (dir),
      .eat_evt(eat_evt),
      .head_x (head_x),
      .head_y (head_y),
      .length (snake_len), // <--- lägg till


      .body_bus_x(body_bus_x),
      .body_bus_y(body_bus_y),
      .self_hit  (self_hit)     // <--- NY


  );

// === moved_once: blir 1 efter första tick (krävs av apple_simple) ===
reg moved_once = 1'b0;
always @(posedge clk_pix) begin
  if (!reset_n) moved_once <= 1'b0;
  else if (tick) moved_once <= 1'b1;
end

  apple_simple u_apple (
      .clk_pix(clk_pix),
      .reset_n(reset_n),
      .eat_evt(eat_evt),
      .rnd(rnd),
      .moved_once(moved_once),
      .apple_x(apple_x),
      .apple_y(apple_y)
  );




  wire [3:0] score_tens, score_ones;

  score_counter u_score (
      .clk_pix(clk_pix),
      .reset_n(reset_n),
      .eat_evt(eat_evt),
      .tens   (score_tens),
      .ones   (score_ones)
  );

wire score_pix_on;  


  score_display #(
      .SCORE_X(16),  // flytta siffrorna med dessa två
      .SCORE_Y(16),
      .SCALE  (3)
  ) score_ui (
      .pix_x(x),
      .pix_y(y),
      .tens(score_tens),
      .ones(score_ones),
      .pixel_on(score_pix_on)
  );

wire [9:0] head_x_d, apple_x_d;
wire [8:0] head_y_d, apple_y_d;
wire [7:0] snake_len_d;
wire [MAX_LEN*10-1:0] body_bus_x_d;
wire [MAX_LEN*9 -1:0] body_bus_y_d;

frame_latch #(.MAX_LEN(MAX_LEN)) u_latch (
  .clk_pix(clk_pix), .frame_start(frame_start),
  .head_x(head_x), .head_y(head_y),
  .apple_x(apple_x), .apple_y(apple_y),
  .snake_len(snake_len),
  .body_bus_x(body_bus_x), .body_bus_y(body_bus_y),
  .head_x_d(head_x_d), .head_y_d(head_y_d),
  .apple_x_d(apple_x_d), .apple_y_d(apple_y_d),
  .snake_len_d(snake_len_d),
  .body_bus_x_d(body_bus_x_d), .body_bus_y_d(body_bus_y_d)
);


  wire head_px, body_px, apple_px, border_px;

  snake_render_segments #(
      .CELL    (CELL),
      .GRID_W  (GRID_W),
      .GRID_H  (GRID_H),
      .MAX_LEN (MAX_LEN),
      .BORDER_X(BORDER_X),
      .BORDER_Y(BORDER_Y)
  ) u_render (
      .disp(disp),
      .x   (x),
      .y   (y),

      .head_x_d   (head_x_d),
      .head_y_d   (head_y_d),
      .apple_x_d  (apple_x_d),
      .apple_y_d  (apple_y_d),
      .snake_len_d(snake_len_d),
      .body_bus_x_d(body_bus_x_d),
      .body_bus_y_d(body_bus_y_d),

      .head_px  (head_px),
      .body_px  (body_px),
      .apple_px (apple_px),
      .border_px(border_px)
  );


  // färger
  assign VGA_R = disp ? (score_pix_on ? 4'hF : border_px ? 4'hF : apple_px ? 4'hF : 4'h0) : 4'h0;

  assign VGA_G = disp ? ( score_pix_on ? 4'hF :
                        head_px      ? 4'hF :
                        body_px      ? 4'h8 :
                        border_px    ? 4'hF : 4'h0 ) : 4'h0;

  assign VGA_B = disp ? (score_pix_on ? 4'hF : border_px ? 4'hF : 4'h0) : 4'h0;


endmodule






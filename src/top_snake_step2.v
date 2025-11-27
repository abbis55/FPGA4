// =============================================================
// top_snake_step2.v — Snake med växande kropp + äpple (stabil ritning)
// =============================================================
module top_snake_step2(
  input  wire        CLOCK_50,
  input  wire        BTN_UP_N,
  input  wire        BTN_LEFT_N,
  input  wire        BTN_DOWN_N,
  input  wire        BTN_RIGHT_N,
  output wire [3:0]  VGA_R,
  output wire [3:0]  VGA_G,
  output wire [3:0]  VGA_B,
  output wire        VGA_HS,
  output wire        VGA_VS
);

  // --- parametrar för top ---
  localparam integer CELL     = 10;
  localparam integer GRID_W   = 64;   // 640/10
  localparam integer GRID_H   = 48;   // 480/10
  localparam integer MAX_LEN  = 32;

  // === Pixelklocka ===
  wire clk_pix;
  clk_pixel u_clk(.clk50(CLOCK_50), .clk_pix(clk_pix));

  // === Reset ===
  wire reset_n;
  por_reset u_por(.clk(clk_pix), .reset_n(reset_n));

  // === VGA-signal ===
  wire [9:0] x, y;
  wire hsync, vsync, disp;
  vga_640x480 u_vga(
    .clk_pix(clk_pix),
    .x(x), .y(y),
    .hsync(hsync), .vsync(vsync),
    .displayArea(disp)
  );
  assign VGA_HS = hsync;
  assign VGA_VS = vsync;

  // Bildrute-start (för latch)
  wire frame_start = (x == 10'd0) && (y == 10'd0);

  // === Speltick (ca 5 steg/s) ===
  wire tick;
  game_tick #(.STEP_HZ(5), .CLK_HZ(25_000_000)) u_tick(
    .clk(clk_pix),
    .tick(tick)
  );

  // === Riktning ===
  wire [1:0] dir;
  input_controller_adv u_ctrl(
    .clk(clk_pix),
    .up_n(BTN_UP_N), .left_n(BTN_LEFT_N),
    .down_n(BTN_DOWN_N), .right_n(BTN_RIGHT_N),
    .dir(dir)
  );

  // === Slumpgenerator ===
  wire [15:0] rnd;
  lfsr_random u_lfsr(
    .clk(clk_pix),
    .reset_n(reset_n),
    .rnd(rnd)
  );

  // === snake_core_grow: huvud + kropp (växer på eat_evt) ===
  wire [9:0] head_x;
  wire [8:0] head_y;
  wire [7:0] snake_len;
  wire [MAX_LEN*10-1:0] body_bus_x;
  wire [MAX_LEN*9 -1:0]  body_bus_y;

  // eat_evt kommer längre ner (kollision)
  wire eat_evt;

  snake_core_grow #(.CELL(CELL), .GRID_W(GRID_W), .GRID_H(GRID_H), .MAX_LEN(MAX_LEN)) u_snake(
    .clk_pix(clk_pix),
    .tick(tick),
    .reset_n(reset_n),
    .dir(dir),
    .eat_evt(eat_evt),
    .head_x(head_x),
    .head_y(head_y),
    .length(snake_len),
    .body_bus_x(body_bus_x),
    .body_bus_y(body_bus_y)
  );

  // === moved_once: blir 1 efter första tick (för apple_simple) ===
  reg moved_once = 1'b0;
  always @(posedge clk_pix) begin
    if (!reset_n)       moved_once <= 1'b0;
    else if (tick)      moved_once <= 1'b1;
  end

  // === Apple ===
  wire [9:0] apple_x;
  wire [8:0] apple_y;

  apple_simple u_apple(
    .clk_pix(clk_pix),
    .reset_n(reset_n),
    .eat_evt(eat_evt),
    .rnd(rnd),
    .moved_once(moved_once),
    .apple_x(apple_x),
    .apple_y(apple_y)
  );

  // === Kollision huvud vs äpple (edge-detekterad puls) ===
  wire collide_now =
       (head_x < (apple_x + CELL)) &&
       ((head_x + CELL) > apple_x) &&
       (head_y < (apple_y + CELL)) &&
       ((head_y + CELL) > apple_y);

  reg collide_now_d = 1'b0;
  reg eat_evt_r     = 1'b0;
  assign eat_evt = eat_evt_r;

  always @(posedge clk_pix) begin
    collide_now_d <= collide_now;
    eat_evt_r     <= collide_now & ~collide_now_d; // puls när kollision börjar
  end

  // === Latcha allt för stabil ritning per frame ===
  reg [9:0]  head_x_d, apple_x_d;
  reg [8:0]  head_y_d, apple_y_d;
  reg [7:0]  snake_len_d;
  reg [MAX_LEN*10-1:0] body_bus_x_d;
  reg [MAX_LEN*9 -1:0]  body_bus_y_d;

  always @(posedge clk_pix) if (frame_start) begin
    head_x_d     <= head_x;
    head_y_d     <= head_y;
    apple_x_d    <= apple_x;
    apple_y_d    <= apple_y;
    snake_len_d  <= snake_len;
    body_bus_x_d <= body_bus_x;
    body_bus_y_d <= body_bus_y;
  end





  // === Kropps-pixel: OR av träffar för segment 1..len-1 ===
integer k;
reg body_hit_cell;
always @* begin
  body_hit_cell = 1'b0;
  for (k = 1; k < MAX_LEN; k = k + 1) begin
    if (k < snake_len_d) begin
              // plocka slice för seg[k] (packad med seg0 som MSB)
        // X-slice:
        //   msb_x = (MAX_LEN-k)*10-1
        // Y-slice:
        //   msb_y = (MAX_LEN-k)*9 -1
      body_hit_cell = body_hit_cell |
        ( (x >= body_bus_x_d[(MAX_LEN-k)*10-1 -: 10]) &&
          (x <  body_bus_x_d[(MAX_LEN-k)*10-1 -: 10] + CELL) &&
          (y >= {1'b0, body_bus_y_d[(MAX_LEN-k)*9-1 -: 9]}) &&
          (y <  {1'b0, body_bus_y_d[(MAX_LEN-k)*9-1 -: 9]} + CELL) );
    end
  end
end

wire body_px = disp && body_hit_cell;


  // === Pixelmasker för huvud/äpple (från latched värden) ===
  wire [9:0] hy10 = {1'b0, head_y_d};
  wire [9:0] ay10 = {1'b0, apple_y_d};

  wire head_px  = disp &&
                  (x >= head_x_d) && (x < head_x_d + CELL) &&
                  (y >= hy10)     && (y < hy10     + CELL);

  wire apple_px = disp &&
                  (x >= apple_x_d) && (x < apple_x_d + CELL) &&
                  (y >= ay10)      && (y < ay10      + CELL);

  // === Färger: huvud = grön, kropp = svag grön, äpple = röd ===
  assign VGA_R = disp ? (apple_px ? 4'hF : 4'h0) : 4'h0;
  assign VGA_G = disp ? (head_px  ? 4'hF :
                         body_px  ? 4'h8 : 4'h0) : 4'h0;
  assign VGA_B = 4'h0;

endmodule

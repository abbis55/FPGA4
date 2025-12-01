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
 
  localparam [9:0] BORDER_X = 10;                   // 10 px ram till vänster/höger
  localparam [8:0] BORDER_Y = 9'd10;                // 10 px ram upp/ner
  localparam [9:0] MAX_X    = (GRID_W-2)*CELL;      // 620 vid CELL=10
  localparam [8:0] MAX_Y    = (GRID_H-2)*CELL;      // 460 vid CELL=10



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
    .reset_n(reset_n),
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




 // === Snake core ===
  wire [9:0] head_x;
  wire [8:0] head_y;
  wire [7:0] snake_len;






// === Snake core (med bussar) ===
localparam integer MAX_BODY = 32;
localparam integer MAX_LEN  = MAX_BODY + 1;






  // eat_evt kommer längre ner (kollision)
  wire eat_evt;


wire [MAX_LEN*10-1:0] body_bus_x;
wire [MAX_LEN*9 -1:0] body_bus_y;

// --- före instansen ---
wire self_hit;
reg  game_over = 1'b0;
wire tick_run;                  // deklaration



// Latcha game_over på självkrock
always @(posedge clk_pix) begin
  if (!reset_n)
    game_over <= 1'b0;
  else if (tick && self_hit)
    game_over <= 1'b1;
end

assign tick_run = tick & ~game_over;   // definiera innan instansen

 snake_core_grow #(.CELL(CELL), .GRID_W(GRID_W), .GRID_H(GRID_H),
  .MAX_BODY(MAX_BODY), .MAX_LEN(MAX_LEN)) u_snake(
    .clk_pix(clk_pix),
    .tick(tick_run),          // <--- använd gatad tick
    
    .reset_n(reset_n),
    .dir(dir),
    .eat_evt(eat_evt),
    .head_x(head_x),
    .head_y(head_y),
    .length(snake_len),          // <--- lägg till


  .body_bus_x(body_bus_x),
  .body_bus_y(body_bus_y),
  .self_hit(self_hit)       // <--- NY


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

wire score_pix_on;

score_display #(
  .SCORE_X(16),   // flytta siffrorna med dessa två
  .SCORE_Y(16),
  .SCALE  (3)
) score_ui (
  .pix_x(x),
  .pix_y(y),
  .tens (score_tens),
  .ones (score_ones),
  .pixel_on(score_pix_on)
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
      // var tidigare: eat_evt_r <= collide_now & ~collide_now_d;
  eat_evt_r     <= (collide_now & ~collide_now_d) & moved_once;  // <-- lägg till & moved_once
  end



// === Score som två BCD-siffror (0..99) ===
reg [3:0] score_ones = 4'd0;
reg [3:0] score_tens = 4'd0;

always @(posedge clk_pix) begin
  if (!reset_n) begin
    score_ones <= 4'd0;
    score_tens <= 4'd0;
  end else if (eat_evt_r) begin
    if (score_ones == 4'd9) begin
      score_ones <= 4'd0;
      if (score_tens == 4'd9)
        score_tens <= 4'd0;
      else
        score_tens <= score_tens + 4'd1;
    end else begin
      score_ones <= score_ones + 4'd1;
    end
  end
end


// === Latch per frame ===
reg [9:0]  head_x_d, apple_x_d;
reg [8:0]  head_y_d, apple_y_d;
reg [7:0]  snake_len_d = 8'd2;
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
// === Kroppen: OR av segment 1..len-1 ===
integer k;
reg body_hit_cell;
always @* begin
  body_hit_cell = 1'b0;
  for (k = 1; k < MAX_LEN; k = k + 1) begin
    if (k < snake_len_d) begin
      body_hit_cell = body_hit_cell |
        ( (x >= body_bus_x_d[(MAX_LEN-k)*10-1 -: 10]) &&
          (x <  body_bus_x_d[(MAX_LEN-k)*10-1 -: 10] + CELL) &&
          (y >= {1'b0, body_bus_y_d[(MAX_LEN-k)*9-1 -: 9]}) &&
          (y <  {1'b0, body_bus_y_d[(MAX_LEN-k)*9-1 -: 9]} + CELL) );
    end
  end
end


wire [9:0] hy10 = {1'b0, head_y_d};
wire [9:0] ay10 = {1'b0, apple_y_d};


wire head_px = disp &&
               (x >= head_x_d) && (x < head_x_d + CELL) &&
               (y >= hy10)     && (y < hy10 + CELL);


wire body_px = disp && body_hit_cell;


wire apple_px = disp &&
                (x >= apple_x_d) && (x < apple_x_d + CELL) &&
                (y >= ay10)      && (y < ay10 + CELL);

                // === Vit ram runt spelplanen ===
wire border_px =
    disp && (
        (x < BORDER_X) ||
        (x >= MAX_X + CELL) ||
        (y < BORDER_Y) ||
        (y >= MAX_Y + CELL)
    );



// färger
assign VGA_R = disp ? ( score_pix_on ? 4'hF :
                        border_px    ? 4'hF :
                        apple_px     ? 4'hF : 4'h0 ) : 4'h0;

assign VGA_G = disp ? ( score_pix_on ? 4'hF :
                        head_px      ? 4'hF :
                        body_px      ? 4'h8 :
                        border_px    ? 4'hF : 4'h0 ) : 4'h0;

assign VGA_B = disp ? ( score_pix_on ? 4'hF :
                        border_px    ? 4'hF : 4'h0 ) : 4'h0;


endmodule






// =============================================================
// apple_simple.v — robust äpple-spawn
//  - Ligger i mitten vid reset (init_done)
//  - Flyttar EN gång per eat_evt (1-cykel-puls i toppen)
//  - Samplar rnd en cykel före beräkning (arm) så vi slipper (10,10)-hörnet
// =============================================================
module apple_simple(
  input  wire        clk_pix,
  input  wire        reset_n,
  input  wire        eat_evt,      // 1-cykel-puls när ormen börjar nudda äpplet
  input  wire [15:0] rnd,          // LFSR-slump (tickar på clk_pix)
  input  wire        moved_once,   // blir 1 efter första orm-rörelsen
  output reg  [9:0]  apple_x,
  output reg  [8:0]  apple_y
);

  localparam integer CELL    = 10;
  localparam integer GRID_W  = 64;  // 640 / 10
  localparam integer GRID_H  = 48;  // 480 / 10
  localparam [9:0]  START_X0 = 10'd320;  // övre-vänster för 10x10-ruta i “mitten”
  localparam [8:0]  START_Y0 = 9'd240;

  // init_done: håll äpplet i mitten en cykel efter reset
  // arm/rnd_s: sample rnd en cykel, beräkna ny pos nästa cykel
  reg        init_done = 1'b0;
  reg        arm       = 1'b0;
  reg [15:0] rnd_s     = 16'h0000;

  reg [7:0] salt = 8'h00;

  always @(posedge clk_pix) begin
    if (!reset_n) begin
      apple_x   <= START_X0;
      apple_y   <= START_Y0;
      init_done <= 1'b0;
      arm       <= 1'b0;
      rnd_s     <= 16'h0000;

      salt      <= 8'h00;     // nollställ salt
    end
    else if (!init_done) begin
      // första aktiva cykeln efter reset: ligg kvar i mitten
      apple_x   <= START_X0;
      apple_y   <= START_Y0;
      init_done <= 1'b1;
      arm       <= 1'b0;
    end
    else if (eat_evt && moved_once && !arm) begin
      // 1) när vi “äter”: spara ett rnd-värde och armera en cykel
      rnd_s <= rnd;
      arm   <= 1'b1;
      salt  <= salt + 8'd37;  // ändra salt (primtal-ish steg, undviker mönster
    end
    else if (arm) begin
      // 2) nästa cykel: beräkna ny position från det samplade rnd_s
  apple_x <= (((rnd_s[9:0]  ^ {2'b00, salt})       % (GRID_W-2)) * CELL) + CELL;  // 10..620
  apple_y <= (((rnd_s[8:0]  ^ {1'b0,  salt[7:0]})  % (GRID_H-2)) * CELL) + CELL;  // 10..460

      arm     <= 1'b0;
    end
  end

endmodule

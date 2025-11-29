/*

module apple(
  input  wire        clk,
  input  wire        reset_n,   // kan vara kvar, men används inte
  input  wire [15:0] rnd,
  input  wire        start_evt,
  input  wire        eat_evt,
  output reg  [9:0]  apple_x = 10'd320,
  output reg  [8:0]  apple_y = 9'd240
);
  localparam integer CELL  = 10;
  localparam integer STEPS = 10;
  localparam integer DX    = CELL * STEPS;  // = 100

  always @(posedge clk) begin
    if (eat_evt) begin
      apple_x <= apple_x + DX;   // flytta höger vid kollision
    end
  end
endmodule
*/
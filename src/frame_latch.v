module frame_latch #(
  parameter integer MAX_LEN = 33
)(
  input  wire              clk_pix,
  input  wire              frame_start,
  input  wire [9:0]        head_x,
  input  wire [8:0]        head_y,
  input  wire [9:0]        apple_x,
  input  wire [8:0]        apple_y,
  input  wire [7:0]        snake_len,
  input  wire [MAX_LEN*10-1:0] body_bus_x,
  input  wire [MAX_LEN*9 -1:0] body_bus_y,

  output reg  [9:0]        head_x_d,
  output reg  [8:0]        head_y_d,
  output reg  [9:0]        apple_x_d,
  output reg  [8:0]        apple_y_d,
  output reg  [7:0]        snake_len_d,
  output reg  [MAX_LEN*10-1:0] body_bus_x_d,
  output reg  [MAX_LEN*9 -1:0] body_bus_y_d
);
  always @(posedge clk_pix) if (frame_start) begin
    head_x_d     <= head_x;
    head_y_d     <= head_y;
    apple_x_d    <= apple_x;
    apple_y_d    <= apple_y;
    snake_len_d  <= snake_len;
    body_bus_x_d <= body_bus_x;
    body_bus_y_d <= body_bus_y;
  end
endmodule

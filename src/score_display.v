module score_display #(
    parameter SCORE_X = 16,
    parameter SCORE_Y = 16,
    parameter SCALE   = 3
) (
    input  wire [9:0] pix_x,
    input  wire [8:0] pix_y,
    input  wire [3:0] tens,
    input  wire [3:0] ones,
    output reg        pixel_on
);

  // 5x7 font
  function automatic [0:0] digit_pixel(input [3:0] digit, input [2:0] row, input [2:0] col);
    reg [4:0] bits;
    begin
      case (digit)
        4'd0:
        case (row)
          0: bits = 5'b01110;
          1: bits = 5'b10001;
          2: bits = 5'b10011;
          3: bits = 5'b10101;
          4: bits = 5'b11001;
          5: bits = 5'b10001;
          6: bits = 5'b01110;
        endcase
        4'd1:
        case (row)
          0: bits = 5'b00100;
          1: bits = 5'b01100;
          2: bits = 5'b00100;
          3: bits = 5'b00100;
          4: bits = 5'b00100;
          5: bits = 5'b00100;
          6: bits = 5'b01110;
        endcase
        4'd2:
        case (row)
          0: bits = 5'b01110;
          1: bits = 5'b10001;
          2: bits = 5'b00001;
          3: bits = 5'b00110;
          4: bits = 5'b01000;
          5: bits = 5'b10000;
          6: bits = 5'b11111;
        endcase
        4'd3:
        case (row)
          0: bits = 5'b11110;
          1: bits = 5'b00001;
          2: bits = 5'b00001;
          3: bits = 5'b01110;
          4: bits = 5'b00001;
          5: bits = 5'b00001;
          6: bits = 5'b11110;
        endcase
        4'd4:
        case (row)
          0: bits = 5'b00010;
          1: bits = 5'b00110;
          2: bits = 5'b01010;
          3: bits = 5'b10010;
          4: bits = 5'b11111;
          5: bits = 5'b00010;
          6: bits = 5'b00010;
        endcase
        4'd5:
        case (row)
          0: bits = 5'b11111;
          1: bits = 5'b10000;
          2: bits = 5'b11110;
          3: bits = 5'b00001;
          4: bits = 5'b00001;
          5: bits = 5'b10001;
          6: bits = 5'b01110;
        endcase
        4'd6:
        case (row)
          0: bits = 5'b00110;
          1: bits = 5'b01000;
          2: bits = 5'b10000;
          3: bits = 5'b11110;
          4: bits = 5'b10001;
          5: bits = 5'b10001;
          6: bits = 5'b01110;
        endcase
        4'd7:
        case (row)
          0: bits = 5'b11111;
          1: bits = 5'b00001;
          2: bits = 5'b00010;
          3: bits = 5'b00100;
          4: bits = 5'b01000;
          5: bits = 5'b01000;
          6: bits = 5'b01000;
        endcase
        4'd8:
        case (row)
          0: bits = 5'b01110;
          1: bits = 5'b10001;
          2: bits = 5'b10001;
          3: bits = 5'b01110;
          4: bits = 5'b10001;
          5: bits = 5'b10001;
          6: bits = 5'b01110;
        endcase
        4'd9:
        case (row)
          0: bits = 5'b01110;
          1: bits = 5'b10001;
          2: bits = 5'b10001;
          3: bits = 5'b01111;
          4: bits = 5'b00001;
          5: bits = 5'b00010;
          6: bits = 5'b01100;
        endcase
        default: bits = 5'b00000;
      endcase
      digit_pixel = bits[4-col];  // MSB till vänster
    end
  endfunction

  localparam integer DIG_W = 5;
  localparam integer DIG_H = 7;
  localparam integer PITCH = (DIG_W * SCALE) + 4;

  always @* begin
    pixel_on = 1'b0;

    if (pix_x >= SCORE_X && pix_y >= SCORE_Y &&
            pix_x < SCORE_X + (DIG_W*SCALE*2 + 4) &&
            pix_y < SCORE_Y + (DIG_H*SCALE)) begin

      integer dx, dy;
      integer col, row;

      dx = pix_x - SCORE_X;
      dy = pix_y - SCORE_Y;

      // vänstra siffran (tio-tal)
      if (dx < DIG_W * SCALE) begin
        col = dx / SCALE;
        row = dy / SCALE;
        pixel_on = digit_pixel(tens, row[2:0], col[2:0]);
      end  // högra siffran (en-tal)
      else if (dx >= PITCH && dx < PITCH + DIG_W * SCALE) begin
        col = (dx - PITCH) / SCALE;
        row = dy / SCALE;
        pixel_on = digit_pixel(ones, row[2:0], col[2:0]);
      end
    end
  end
endmodule

module input_controller_adv(
  input  wire       clk,                 // clk_pix
  input  wire       up_n, left_n, down_n, right_n, // rå, aktiva-låga
  output reg  [1:0] dir = 2'd3          // 0=UP,1=LEFT,2=DOWN,3=RIGHT
);
  // Debounce
  wire up_d_n, left_d_n, down_d_n, right_d_n;
  debounce_n u0(.clk(clk), .in_n(up_n),    .out_n(up_d_n));
  debounce_n u1(.clk(clk), .in_n(left_n),  .out_n(left_d_n));
  debounce_n u2(.clk(clk), .in_n(down_n),  .out_n(down_d_n));
  debounce_n u3(.clk(clk), .in_n(right_n), .out_n(right_d_n));

  // Hjälp-funktion: är new_dir motsatt current_dir?
  function automatic is_opposite(input [1:0] newd, input [1:0] curd);
    begin
      case (curd)
        2'd0: is_opposite = (newd==2'd2); // U vs D
        2'd1: is_opposite = (newd==2'd3); // L vs R
        2'd2: is_opposite = (newd==2'd0); // D vs U
        2'd3: is_opposite = (newd==2'd1); // R vs L
      endcase
    end
  endfunction

  // Uppdatera riktning när en knapp är nedtryckt (aktiv-låg),
  // men blockera 180°-vändning.
  always @(posedge clk) begin
    if (!up_d_n   && !is_opposite(2'd0, dir)) dir <= 2'd0;
    else if (!left_d_n && !is_opposite(2'd1, dir)) dir <= 2'd1;
    else if (!down_d_n && !is_opposite(2'd2, dir)) dir <= 2'd2;
    else if (!right_d_n&& !is_opposite(2'd3, dir)) dir <= 2'd3;
  end
endmodule

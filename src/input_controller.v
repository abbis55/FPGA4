module input_controller (
    input  wire       clk,        // clk_pix
    input  wire       reset_n,    // aktiv-låg reset
    input  wire       up_n,
    left_n,
    down_n,
    right_n,  // rå, aktiva-låga
    output reg  [1:0] dir = 2'd3  // 0=UP,1=LEFT,2=DOWN,3=RIGHT
);
  // Debounce (aktiva-låga in, aktiva-låga ut)
  wire up_d_n, left_d_n, down_d_n, right_d_n;
  debounce_n u0 (
      .clk  (clk),
      .in_n (up_n),
      .out_n(up_d_n)
  );
  debounce_n u1 (
      .clk  (clk),
      .in_n (left_n),
      .out_n(left_d_n)
  );
  debounce_n u2 (
      .clk  (clk),
      .in_n (down_n),
      .out_n(down_d_n)
  );
  debounce_n u3 (
      .clk  (clk),
      .in_n (right_n),
      .out_n(right_d_n)
  );

  // --- 1) Vänta tills ALLA knappar är släppta efter reset ---
  // Kräver t.ex. ~10 ms stabil "alla släppta" innan vi släpper spärren
  localparam integer REL_BITS = 18;  // 2^18 / 25MHz ~ 10.5 ms
  reg [REL_BITS:0] rel_cnt = 0;
  wire all_released = up_d_n & left_d_n & down_d_n & right_d_n;
  wire wait_release = ~rel_cnt[REL_BITS];

  always @(posedge clk) begin
    if (!reset_n) begin
      rel_cnt <= 0;
    end else if (wait_release) begin
      rel_cnt <= all_released ? (rel_cnt + 1'b1) : 0;
    end
  end

  // --- 2) Edge-detektering (fallande kant, eftersom *_n är aktiv-låg) ---
  reg up_q = 1'b1, left_q = 1'b1, down_q = 1'b1, right_q = 1'b1;
  always @(posedge clk) begin
    if (!reset_n) begin
      up_q <= 1'b1;
      left_q <= 1'b1;
      down_q <= 1'b1;
      right_q <= 1'b1;
    end else begin
      up_q <= up_d_n;
      left_q <= left_d_n;
      down_q <= down_d_n;
      right_q <= right_d_n;
    end
  end

  wire up_p = up_q & ~up_d_n;  // 1 klocka när knapp går 1->0 (släpps->trycks)
  wire left_p = left_q & ~left_d_n;
  wire down_p = down_q & ~down_d_n;
  wire right_p = right_q & ~right_d_n;

  // Hjälp-funktion: blockera 180°-vändning
  function automatic is_opposite(input [1:0] newd, input [1:0] curd);
    begin
      case (curd)
        2'd0: is_opposite = (newd == 2'd2);  // U vs D
        2'd1: is_opposite = (newd == 2'd3);  // L vs R
        2'd2: is_opposite = (newd == 2'd0);  // D vs U
        2'd3: is_opposite = (newd == 2'd1);  // R vs L
      endcase
    end
  endfunction

  // --- Riktning ---
  always @(posedge clk) begin
    if (!reset_n) begin
      dir <= 2'd3;  // RIGHT vid reset
    end else if (wait_release) begin
      dir <= 2'd3;  // Håll RIGHT tills knappar varit släppta en stund
    end else begin
      // Uppdatera ENDAST på kant-puls, inte nivå
      if (up_p && !is_opposite(2'd0, dir)) dir <= 2'd0;
      else if (left_p && !is_opposite(2'd1, dir)) dir <= 2'd1;
      else if (down_p && !is_opposite(2'd2, dir)) dir <= 2'd2;
      else if (right_p && !is_opposite(2'd3, dir)) dir <= 2'd3;
    end
  end
endmodule

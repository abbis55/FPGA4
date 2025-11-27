`timescale 1ns/1ps

module tb_snake;
  reg CLOCK_50 = 0;
  reg BTN_UP_N = 1;
  reg BTN_LEFT_N = 1;
  reg BTN_DOWN_N = 1;
  reg BTN_RIGHT_N = 1;

  wire [3:0] VGA_R, VGA_G, VGA_B;
  wire VGA_HS, VGA_VS;

  // Klocka 50 MHz
  always #10 CLOCK_50 = ~CLOCK_50;  // 20 ns period = 50 MHz

  // Instans av din toppmodul
  top_snake_step2 dut (
    .CLOCK_50(CLOCK_50),
    .BTN_UP_N(BTN_UP_N),
    .BTN_LEFT_N(BTN_LEFT_N),
    .BTN_DOWN_N(BTN_DOWN_N),
    .BTN_RIGHT_N(BTN_RIGHT_N),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS)
  );

initial begin
  `ifdef DUMP
    $dumpfile("snake.vcd");
    $dumpvars(0, dut);
  `endif

  #20_000_000 $finish;  // 20 ms
end

endmodule

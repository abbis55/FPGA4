// =============================================================
// collision.v — Kollision huvud vs äpple + edge-detekterad eat-puls
// =============================================================
module collision #(
    parameter integer CELL = 10
)(
    input  wire        clk_pix,
    input  wire        reset_n,
    input  wire        tick,         // för moved_once
    input  wire [9:0]  head_x,
    input  wire [8:0]  head_y,
    input  wire [9:0]  apple_x,
    input  wire [8:0]  apple_y,
    output wire        eat_evt       // 1-cykels puls när nytt bett sker (efter första move)
);
    // blivit minst ett steg? (för att undvika startkrock-puls)
    reg moved_once = 1'b0;
    always @(posedge clk_pix) begin
        if (!reset_n)        moved_once <= 1'b0;
        else if (tick)       moved_once <= 1'b1;
    end

    // rektangel-kollision (huvud vs äpple)
    wire [9:0] hy10 = {1'b0, head_y};
    wire [9:0] ay10 = {1'b0, apple_y};

    wire collide_now =
         (head_x < (apple_x + CELL)) &&
         ((head_x + CELL) > apple_x) &&
         (hy10   < (ay10   + CELL)) &&
         ((hy10 + CELL) > ay10);

    // edge-detektera
    reg collide_now_d = 1'b0;
    reg eat_evt_r     = 1'b0;
    assign eat_evt    = eat_evt_r;

    always @(posedge clk_pix) begin
        if (!reset_n) begin
            collide_now_d <= 1'b0;
            eat_evt_r     <= 1'b0;
        end else begin
            collide_now_d <= collide_now;
            eat_evt_r     <= (collide_now & ~collide_now_d) & moved_once;
        end
    end
endmodule

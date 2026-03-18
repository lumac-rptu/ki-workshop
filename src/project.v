`default_nettype none

module tt_um_vga_example(
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);

    wire hsync;
    wire vsync;
    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    reg [9:0] fall_counter[0:7];
    reg [9:0] leaf_x[0:7];
    reg [9:0] leaf_y[0:7];

    reg start_fall;

    initial begin
        leaf_x[0] = 280; leaf_y[0] = 160;
        leaf_x[1] = 300; leaf_y[1] = 150;
        leaf_x[2] = 320; leaf_y[2] = 170;
        leaf_x[3] = 340; leaf_y[3] = 160;
        leaf_x[4] = 260; leaf_y[4] = 200;
        leaf_x[5] = 290; leaf_y[5] = 190;
        leaf_x[6] = 330; leaf_y[6] = 210;
        leaf_x[7] = 360; leaf_y[7] = 200;
    end

    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    assign uio_out = 0;
    assign uio_oe  = 0;

    wire _unused_ok = &{ena, uio_in};

    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    wire tree_stem = (pix_x > 300 && pix_x < 340) && (pix_y > 240 && pix_y < 380);

    // 🌳 Krone
    wire crown_top    = (pix_y >= 140 && pix_y < 180) && (pix_x > 280 && pix_x < 360);
    wire crown_mid    = (pix_y >= 180 && pix_y < 210) && (pix_x > 260 && pix_x < 380);
    wire crown_bottom = (pix_y >= 210 && pix_y < 240) && (pix_x > 240 && pix_x < 400);

    wire tree_crown = crown_top || crown_mid || crown_bottom;

    // Blätter
    wire leaf_falling_background = start_fall && (
        ((pix_x >= leaf_x[0] && pix_x < leaf_x[0] + 40) && (pix_y >= leaf_y[0] + fall_counter[0] && pix_y < leaf_y[0] + fall_counter[0] + 10)) ||
        ((pix_x >= leaf_x[2] && pix_x < leaf_x[2] + 40) && (pix_y >= leaf_y[2] + fall_counter[2] && pix_y < leaf_y[2] + fall_counter[2] + 10)) ||
        ((pix_x >= leaf_x[4] && pix_x < leaf_x[4] + 40) && (pix_y >= leaf_y[4] + fall_counter[4] && pix_y < leaf_y[4] + fall_counter[4] + 10)) ||
        ((pix_x >= leaf_x[6] && pix_x < leaf_x[6] + 40) && (pix_y >= leaf_y[6] + fall_counter[6] && pix_y < leaf_y[6] + fall_counter[6] + 10))
    );

    wire leaf_falling_foreground = start_fall && (
        ((pix_x >= leaf_x[1] && pix_x < leaf_x[1] + 40) && (pix_y >= leaf_y[1] + fall_counter[1] && pix_y < leaf_y[1] + fall_counter[1] + 10)) ||
        ((pix_x >= leaf_x[3] && pix_x < leaf_x[3] + 40) && (pix_y >= leaf_y[3] + fall_counter[3] && pix_y < leaf_y[3] + fall_counter[3] + 10)) ||
        ((pix_x >= leaf_x[5] && pix_x < leaf_x[5] + 40) && (pix_y >= leaf_y[5] + fall_counter[5] && pix_y < leaf_y[5] + fall_counter[5] + 10)) ||
        ((pix_x >= leaf_x[7] && pix_x < leaf_x[7] + 40) && (pix_y >= leaf_y[7] + fall_counter[7] && pix_y < leaf_y[7] + fall_counter[7] + 10))
    );

    // 🎨 Farben (alle Blätter jetzt einfarbig)
    assign R = video_active ? 
               (leaf_falling_foreground ? 2'b11 :
               (tree_crown ? 2'b11 :
               (leaf_falling_background ? 2'b11 : 
               (tree_stem ? 2'b01 : 2'b00)))) : 2'b00;

    assign G = video_active ? 
               (leaf_falling_foreground ? 2'b01 :
               (tree_crown ? 2'b01 :
               (leaf_falling_background ? 2'b01 : 
               (tree_stem ? 2'b01 : 2'b00)))) : 2'b00;

    assign B = video_active ? 
               (leaf_falling_foreground ? 2'b10 :
               (tree_crown ? 2'b10 :
               (leaf_falling_background ? 2'b10 : 
               (tree_stem ? 2'b00 : 2'b00)))) : 2'b00;

    // Animation
    integer i;
    always @(posedge vsync or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                fall_counter[i] <= 0;
            end
            start_fall <= 0;
        end else begin
            if (ui_in[0]) begin
                start_fall <= 1;
                for (i = 0; i < 8; i = i + 1) begin
                    fall_counter[i] <= 0;
                end
            end

            if (start_fall) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (leaf_y[i] + fall_counter[i] < 380)
                        fall_counter[i] <= fall_counter[i] + 1;
                end
            end
        end
    end

endmodule

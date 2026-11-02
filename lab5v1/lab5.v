module lab5 (
    input  wire clk,
    input  wire S1, S2,
    output wire X, Y,
    output reg  buzzer = 1'b1
);

reg [7:0]  x = 80, y = 60;
reg [9:0]  sx = 0, sy = 0;
reg [10:0] timer = 0;
reg [2:0]  phase = 0;
reg [3:0]  segment = 0;
reg [6:0]  t = 0;

reg s1a = 1, s1b = 1;
reg s2a = 1, s2b = 1;

reg [18:0] db1 = 0, db2 = 0;
reg k1 = 1, k2 = 1;
reg prev1 = 1, prev2 = 1;

reg [13:0] tone_count = 0;
reg [21:0] beep_count = 0;

function [31:0] shape;
    input [2:0] p;
    input [3:0] s;
    begin
        shape = {8'd80, 8'd60, 8'd80, 8'd60};
        case (p)
            0: case (s)
                0: shape = {8'd80,  8'd60,  8'd80,  8'd210};
                1: shape = {8'd80,  8'd210, 8'd130, 8'd210};
                2: shape = {8'd130, 8'd210, 8'd155, 8'd190};
                3: shape = {8'd155, 8'd190, 8'd155, 8'd160};
                4: shape = {8'd155, 8'd160, 8'd130, 8'd140};
                5: shape = {8'd130, 8'd140, 8'd80,  8'd140};
                6: shape = {8'd80,  8'd140, 8'd80,  8'd60};
            endcase
            1: case (s)
                0: shape = {8'd70,  8'd60,  8'd128, 8'd210};
                1: shape = {8'd128, 8'd210, 8'd186, 8'd60};
                2: shape = {8'd186, 8'd60,  8'd157, 8'd135};
                3: shape = {8'd157, 8'd135, 8'd99,  8'd135};
                4: shape = {8'd99,  8'd135, 8'd128, 8'd210};
                5: shape = {8'd128, 8'd210, 8'd70,  8'd60};
            endcase
            2: case (s)
                0: shape = {8'd85,  8'd210, 8'd85,  8'd90};
                1: shape = {8'd85,  8'd90,  8'd100, 8'd60};
                2: shape = {8'd100, 8'd60,  8'd150, 8'd60};
                3: shape = {8'd150, 8'd60,  8'd165, 8'd90};
                4: shape = {8'd165, 8'd90,  8'd165, 8'd210};
                5: shape = {8'd165, 8'd210, 8'd165, 8'd90};
                6: shape = {8'd165, 8'd90,  8'd150, 8'd60};
                7: shape = {8'd150, 8'd60,  8'd100, 8'd60};
                8: shape = {8'd100, 8'd60,  8'd85,  8'd90};
                9: shape = {8'd85,  8'd90,  8'd85,  8'd210};
            endcase
            3: case (s)
                0: shape = {8'd95,  8'd210, 8'd95,  8'd60};
                1: shape = {8'd95,  8'd60,  8'd165, 8'd60};
                2: shape = {8'd165, 8'd60,  8'd95,  8'd60};
                3: shape = {8'd95,  8'd60,  8'd95,  8'd210};
            endcase
            4: case (s)
                0: shape = {8'd128, 8'd55,  8'd92,  8'd95};
                1: shape = {8'd92,  8'd95,  8'd72,  8'd140};
                2: shape = {8'd72,  8'd140, 8'd88,  8'd180};
                3: shape = {8'd88,  8'd180, 8'd112, 8'd195};
                4: shape = {8'd112, 8'd195, 8'd128, 8'd175};
                5: shape = {8'd128, 8'd175, 8'd144, 8'd195};
                6: shape = {8'd144, 8'd195, 8'd168, 8'd180};
                7: shape = {8'd168, 8'd180, 8'd184, 8'd140};
                8: shape = {8'd184, 8'd140, 8'd164, 8'd95};
                9: shape = {8'd164, 8'd95,  8'd128, 8'd55};
            endcase
        endcase
    end
endfunction

reg [3:0] last_segment;

always @(*) begin
    case (phase)
        0: last_segment = 6;
        1: last_segment = 5;
        2: last_segment = 9;
        3: last_segment = 3;
        4: last_segment = 9;
        default: last_segment = 0;
    endcase
end

wire [31:0] v  = shape(phase, segment);
wire [7:0]  x0 = v[31:24];
wire [7:0]  y0 = v[23:16];
wire [7:0]  x1 = v[15:8];
wire [7:0]  y1 = v[7:0];

wire signed [10:0] dx = $signed({1'b0, x1}) - $signed({1'b0, x0});
wire signed [10:0] dy = $signed({1'b0, y1}) - $signed({1'b0, y0});

wire signed [20:0] ix = $signed({1'b0, x0}) + (dx * $signed({1'b0, t})) / 63;
wire signed [20:0] iy = $signed({1'b0, y0}) + (dy * $signed({1'b0, t})) / 63;

wire press1 = prev1 && !k1;
wire press2 = prev2 && !k2;

always @(posedge clk) begin
    s1a <= S1;  s1b <= s1a;
    s2a <= S2;  s2b <= s2a;

    if (s1b == k1)
        db1 <= 0;
    else if (db1 == 499999) begin
        db1 <= 0;
        k1  <= s1b;
    end else
        db1 <= db1 + 1'b1;

    if (s2b == k2)
        db2 <= 0;
    else if (db2 == 499999) begin
        db2 <= 0;
        k2  <= s2b;
    end else
        db2 <= db2 + 1'b1;

    prev1 <= k1;
    prev2 <= k2;

    sx <= {2'b00, sx[7:0]} + {2'b00, x};
    sy <= {2'b00, sy[7:0]} + {2'b00, y};

    if (press1 || press2) begin
        if (press1)
            phase <= (phase == 4) ? 3'd0 : phase + 1'b1;
        else
            phase <= (phase == 0) ? 3'd4 : phase - 1'b1;
        segment    <= 0;
        t          <= 0;
        timer      <= 0;
        beep_count <= 4000000;
        tone_count <= 0;
        buzzer     <= 1'b1;
    end else begin
        if (timer == 1388) begin
            timer <= 0;
            x <= ix[7:0];
            y <= iy[7:0];
            if (t == 63) begin
                t <= 0;
                segment <= (segment == last_segment) ? 4'd0 : segment + 1'b1;
            end else
                t <= t + 1'b1;
        end else
            timer <= timer + 1'b1;

        if (beep_count != 0) begin
            beep_count <= beep_count - 1'b1;
            if (tone_count == 12499) begin
                tone_count <= 0;
                buzzer     <= ~buzzer;
            end else
                tone_count <= tone_count + 1'b1;
        end else begin
            buzzer     <= 1'b1;
            tone_count <= 0;
        end
    end
end

assign X = sx[8];
assign Y = sy[8];

endmodule

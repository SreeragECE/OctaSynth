`timescale 1ns / 1ps

// keypad_music_octaves.v
// Adds dedicated octave up/down keys and supports octaves 4..7 for notes:
// C D E F G A B C(high) mapped to stable_key 1..8
// Octave up  -> mapped to key labeled 'A' on PmodKYPD (change via OCT_UP_KEY)
// Octave down-> mapped to key labeled 'B' on PmodKYPD (change via OCT_DOWN_KEY)

module keypad_music_improved_oct (
    input  wire clk,             // 100 MHz clock
    input  wire [3:0] col,       // keypad columns (active-low)
    output reg  [3:0] row,       // keypad rows (drive active-low)
    output wire audio_out1,
    output wire audio_out2,
    output reg  [15:0] led       // optional: leds[0..7] keys, [8..10] volume/octave
);

    // ------------------------------------------------------------------
    // Parameters / tuning
    // ------------------------------------------------------------------
    localparam integer CLK_FREQ = 100_000_000; // 100 MHz
    localparam integer DEBOUNCE_MS = 20;       // debounce time in milliseconds
    localparam integer DEBOUNCE_TICKS = (CLK_FREQ/1000) * DEBOUNCE_MS;

    // Keypad scan timing (~1 ms)
    localparam integer SCAN_TICKS = 100_000; // = 1 ms at 100 MHz

    // Octave limits
    localparam integer OCT_MIN = 4;
    localparam integer OCT_MAX = 6;

    // Dedicated key codes (change here if you prefer different physical keys)
    // These are the stable_key codes we will compare against.
    // By default we use the keys in the 4th column ("A","B"):
    // Typical mapping on PmodKYPD: rightmost column labels A (row0), B (row1)
    localparam [3:0] OCT_UP_KEY   = 4'hA; // 'A' key label -> octave up
    localparam [3:0] OCT_DOWN_KEY = 4'hB; // 'B' key label -> octave down

    // ------------------------------------------------------------------
    // Keypad scanner (4 rows)
    // ------------------------------------------------------------------
    reg [16:0] scan_cnt = 0; // 17 bits enough for 100k
    reg [1:0]  scan_row = 0;

    always @(posedge clk) begin
        if (scan_cnt >= SCAN_TICKS - 1) begin
            scan_cnt <= 0;
            scan_row <= scan_row + 1;
        end else begin
            scan_cnt <= scan_cnt + 1;
        end
    end

    always @(*) begin
        case (scan_row)
            2'd0: row = 4'b1110; // R0 -> keys: 1 2 3 A
            2'd1: row = 4'b1101; // R1 -> keys: 4 5 6 B
            2'd2: row = 4'b1011; // R2 -> keys: 7 8 9 C

            default: row = 4'b1111;
        endcase
    end

    // ------------------------------------------------------------------
    // Raw key detection (fast sample, will be debounced)
    // Map codes as follows (common keypad layout):
    // Row0: col0->'1' -> code 1, col1->'2' -> 2, col2->'3' -> 3, col3->'A' -> 10 (0xA)
    // Row1: col0->'4' -> 4, col1->'5' -> 5, col2->'6' -> 6, col3->'B' -> 11 (0xB)
    // Row2: col0->'7' -> 7, col1->'8' -> 8,
    // We will use codes 1..8 for the musical keys (C..C), and use A/B for octave controls.
    // ------------------------------------------------------------------
    reg [3:0] keycode_raw = 4'h0;

    always @(posedge clk) begin
        keycode_raw <= 4'd0;
        case (scan_row)
            2'd0: begin // Row0: 1,2,3,A
                if (col[0] == 1'b0) keycode_raw <= 4'h1; // '1'
                if (col[1] == 1'b0) keycode_raw <= 4'h2; // '2'
                if (col[2] == 1'b0) keycode_raw <= 4'h3; // '3'
                if (col[3] == 1'b0) keycode_raw <= 4'hA; // 'A' -> OCT UP
            end
            2'd1: begin // Row1: 4,5,6,B
                if (col[0] == 1'b0) keycode_raw <= 4'h4; // '4'
                if (col[1] == 1'b0) keycode_raw <= 4'h5; // '5'
                if (col[2] == 1'b0) keycode_raw <= 4'h6; // '6'
                if (col[3] == 1'b0) keycode_raw <= 4'hB; // 'B' -> OCT DOWN
            end
            2'd2: begin // Row2: 7,8,9,C
                if (col[0] == 1'b0) keycode_raw <= 4'h7; // '7'
                if (col[1] == 1'b0) keycode_raw <= 4'h8; // '8'
            end

            default: keycode_raw <= 4'd0;
        endcase
    end

    // ------------------------------------------------------------------
    // Debounce logic (stable_key holds the debounced keycode)
    // ------------------------------------------------------------------
    reg [3:0] stable_key = 4'd0;
    reg [21:0] debounce_cnt = 22'd0;
    reg [3:0] prev_key_raw = 4'd0;

    always @(posedge clk) begin
        if (keycode_raw != prev_key_raw) begin
            debounce_cnt <= 22'd0;
            prev_key_raw <= keycode_raw;
        end else begin
            if (debounce_cnt < DEBOUNCE_TICKS)
                debounce_cnt <= debounce_cnt + 1;
            else
                debounce_cnt <= debounce_cnt;
        end

        if (debounce_cnt >= DEBOUNCE_TICKS)
            stable_key <= keycode_raw;
    end

    // ------------------------------------------------------------------
    // Octave control
    // - support octaves 4..6 (default 4)
    // - octave changes on a short press of dedicated keys (OCT_UP_KEY / OCT_DOWN_KEY)
    // - to avoid repeating while key held, use an edge detection on stable_key
    // ------------------------------------------------------------------
    reg [2:0] octave = 3'd4; // store 4..7, 3 bits enough
    reg [3:0] prev_stable_key = 4'd0;

    always @(posedge clk) begin
        // detect rising edge of stable_key (i.e., a new stable press)
        if ((stable_key != 4'd0) && (stable_key != prev_stable_key)) begin
            // a new stable key press occurred
            if (stable_key == OCT_UP_KEY) begin
                if (octave < OCT_MAX) octave <= octave + 1;
            end else if (stable_key == OCT_DOWN_KEY) begin
                if (octave > OCT_MIN) octave <= octave - 1;
            end
        end
        // track previous stable_key (for edge detection)
        prev_stable_key <= stable_key;
    end

    // ------------------------------------------------------------------
    // Base dividers for octave 4 (LUT_SIZE = 128)
    // These are the same constants you had for C4..C5 (scaled for 128-sample LUT)
    // We'll store them in an array and shift according to octave.
    // Note order: 1->C,2->D,3->E,4->F,5->G,6->A,7->B,8->C(top)
    // ------------------------------------------------------------------
    localparam integer LUT_SIZE = 128;
    // Base dividers for octave 4 (these are the same numbers used earlier)
    localparam integer BASE_C4 = 16'd5963 * 2;  // C4
    localparam integer BASE_D4 = 16'd4476 * 2;  // D4
    localparam integer BASE_E4 = 16'd3571 * 2;  // E4
    localparam integer BASE_F4 = 16'd2981 * 2;  // F4
    localparam integer BASE_G4 = 16'd2658 * 2;  // G4
    localparam integer BASE_A4 = 16'd2373 * 2;  // A4
    localparam integer BASE_B4 = 16'd1991 * 2;  // B4
    localparam integer BASE_C5 = 16'd1786 * 2;  // C5 (top of octave 4->5)

    // put in an array for easy indexing
    reg [15:0] base_divider [0:7];
    initial begin
        base_divider[0] = BASE_C4;
        base_divider[1] = BASE_D4;
        base_divider[2] = BASE_E4;
        base_divider[3] = BASE_F4;
        base_divider[4] = BASE_G4;
        base_divider[5] = BASE_A4;
        base_divider[6] = BASE_B4;
        base_divider[7] = BASE_C5;
    end

    // ------------------------------------------------------------------
    // Choose divider from stable_key and octave
    // divider = base_divider[note_index] >> (octave)
    // (shifting right halves the divider per octave up: frequency doubles)
    // ------------------------------------------------------------------
    reg [15:0] divider;
    integer note_idx;
    integer shift;

    always @(*) begin
        // default silence
        divider = 16'hFFFF;
        // Only map notes when stable_key is in 1..8 (our musical keys)
        if ((stable_key >= 4'h1) && (stable_key <= 4'h8)) begin
            note_idx = stable_key - 1; // 1->0, 8->7
            shift = octave ;        // 0..3
            // perform shift safely; if shift>0, right shift; else use base
            if (shift >= 0)
                divider = base_divider[note_idx] >> shift;
            else
                divider = base_divider[note_idx] << (-shift); // not used since octave>=4
        end else begin
            divider = 16'hFFFF; // silence
        end
    end

    // ------------------------------------------------------------------
    // Sine LUT (128 samples, 8-bit unsigned centered at 128)
    // ------------------------------------------------------------------
    reg [7:0] sine_lut[0:127];
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            sine_lut[i] = 8'd128 + $rtoi(127.0 * $sin(6.283185307179586 * i / 128.0));
        end
    end

    // ------------------------------------------------------------------
    // Tone generation (increment rom_idx according to divider)
    // ------------------------------------------------------------------
    reg [31:0] tone_cnt = 32'd0;
    reg [6:0]  rom_idx = 7'd0;

    always @(posedge clk) begin
        if (divider == 16'hFFFF) begin
            tone_cnt <= 32'd0;
            rom_idx <= 7'd0;
        end else begin
            if (tone_cnt >= divider) begin
                tone_cnt <= 32'd0;
                rom_idx <= rom_idx + 1;
            end else begin
                tone_cnt <= tone_cnt + 1;
            end
        end
    end

    // raw sample (unsigned 0..255)
    wire [7:0] raw_sample = (divider == 16'hFFFF) ? 8'd128 : sine_lut[rom_idx];

    // final_sample (no volume scaling here - keep full scale)
    wire [7:0] final_sample = raw_sample;

    // ------------------------------------------------------------------
    // PWM DAC (8-bit)
    // ------------------------------------------------------------------
    reg [7:0] pwm_cnt = 8'd0;
    always @(posedge clk)
        pwm_cnt <= pwm_cnt + 1;

    assign audio_out1 = (pwm_cnt < final_sample);
    assign audio_out2 = audio_out1;

    // ------------------------------------------------------------------
    // LED indicator: show current octave in led[11:9] in binary, and key leds in [0..7]
    // ------------------------------------------------------------------
    integer j;
    always @(posedge clk) begin

        // clear
        led <= 16'd0;
        // key LEDs for 1..8
        if ((stable_key >= 4'h1) && (stable_key <= 4'h8)) begin
            led[stable_key - 1] <= 1'b1;
        end
        // show octave in binary on led[9..11] (3 bits)
        // octave is 4..7 -> subtract 4 to display 0..3
        led[9]  <= ( (octave ) & 1 ) ? 1'b1 : 1'b0;
        led[10] <= ( ((octave) >> 1) & 1 ) ? 1'b1 : 1'b0;
    end

endmodule
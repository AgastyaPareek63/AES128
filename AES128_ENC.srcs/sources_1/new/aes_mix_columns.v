`timescale 1ns / 1ps

module aes_mix_columns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    // Multiply by 2 in GF(2^8)

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    // Multiply by 3

    function [7:0] mul3;
        input [7:0] b;
        begin
            mul3 = xtime(b) ^ b;
        end
    endfunction

    // Input bytes
    // After ShiftRows, four consecutive bytes form one AES column.
    // Column 0 = b0  b1  b2  b3
    // Column 1 = b4  b5  b6  b7
    // Column 2 = b8  b9  b10 b11
    // Column 3 = b12 b13 b14 b15

    wire [7:0] b0 = state_in[127:120];
    wire [7:0] b1 = state_in[119:112];
    wire [7:0] b2 = state_in[111:104];
    wire [7:0] b3 = state_in[103:96];

    wire [7:0] b4 = state_in[95:88];
    wire [7:0] b5 = state_in[87:80];
    wire [7:0] b6 = state_in[79:72];
    wire [7:0] b7 = state_in[71:64];

    wire [7:0] b8 = state_in[63:56];
    wire [7:0] b9 = state_in[55:48];
    wire [7:0] b10 = state_in[47:40];
    wire [7:0] b11 = state_in[39:32];

    wire [7:0] b12 = state_in[31:24];
    wire [7:0] b13 = state_in[23:16];
    wire [7:0] b14 = state_in[15:8];
    wire [7:0] b15 = state_in[7:0];


    // COLUMN 0
    // b0, b1, b2, b3

    wire [7:0] c0_0 = xtime(b0) ^ mul3(b1) ^ b2 ^ b3;

    wire [7:0] c0_1 = b0 ^ xtime(b1) ^ mul3(b2) ^ b3;

    wire [7:0] c0_2 = b0 ^ b1 ^ xtime(b2) ^ mul3(b3);

    wire [7:0] c0_3 = mul3(b0) ^ b1 ^ b2 ^ xtime(b3);

    // COLUMN 1
    // b4, b5, b6, b7

    wire [7:0] c1_0 = xtime(b4) ^ mul3(b5) ^ b6 ^ b7;

    wire [7:0] c1_1 = b4 ^ xtime(b5) ^ mul3(b6) ^ b7;

    wire [7:0] c1_2 = b4 ^ b5 ^ xtime(b6) ^ mul3(b7);

    wire [7:0] c1_3 = mul3(b4) ^ b5 ^ b6 ^ xtime(b7);

    // COLUMN 2
    // b8, b9, b10, b11

    wire [7:0] c2_0 = xtime(b8) ^ mul3(b9) ^ b10 ^ b11;

    wire [7:0] c2_1 = b8 ^ xtime(b9) ^ mul3(b10) ^ b11;

    wire [7:0] c2_2 = b8 ^ b9 ^ xtime(b10) ^ mul3(b11);

    wire [7:0] c2_3 = mul3(b8) ^ b9 ^ b10 ^ xtime(b11);

    // COLUMN 3
    // b12, b13, b14, b15

    wire [7:0] c3_0 = xtime(b12) ^ mul3(b13) ^ b14 ^ b15;

    wire [7:0] c3_1 = b12 ^ xtime(b13) ^ mul3(b14) ^ b15;

    wire [7:0] c3_2 = b12 ^ b13 ^ xtime(b14) ^ mul3(b15);

    wire [7:0] c3_3 = mul3(b12) ^ b13 ^ b14 ^ xtime(b15);

    // Output

    assign state_out = {
        c0_0, c0_1, c0_2, c0_3,
        c1_0, c1_1, c1_2, c1_3,
        c2_0, c2_1, c2_2, c2_3,
        c3_0, c3_1, c3_2, c3_3
    };

endmodule
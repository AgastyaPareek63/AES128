`timescale 1ns / 1ps

module aes_final_round (
    input wire [127:0] state_in,
    input wire [127:0] round_key,
    output wire [127:0] state_out
);

    // Intermediate signals

    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;

    // Stage 1: SubBytes

    aes_sub_bytes u_sub_bytes (
        .state_in(state_in),
        .state_out(sub_bytes_out)
    );

    // Stage 2: ShiftRows

    aes_shift_rows u_shift_rows (
        .state_in(sub_bytes_out),
        .state_out(shift_rows_out)
    );

    // Stage 3: AddRoundKey
    // Final AES round does NOT contain MixColumns.

    aes_add_round_key u_add_round_key (
        .state_in(shift_rows_out),
        .round_key(round_key),
        .state_out(state_out)
    );

endmodule
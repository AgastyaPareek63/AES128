`timescale 1ns / 1ps

module aes128_encrypt (
    input  wire clk,
    input  wire rst,
    input  wire start,

    input  wire [127:0] plaintext,
    input  wire [127:0] key,

    output reg  [127:0] ciphertext,
    output wire busy,
    output reg done
);

    // Controller

    localparam IDLE = 3'd0;
    localparam KEY_EXPAND = 3'd1;
    localparam INITIAL = 3'd2;
    localparam ROUNDS = 3'd3;
    localparam FINAL = 3'd4;
    localparam COMPLETE = 3'd5;

    reg [2:0] state;
    reg [3:0] round_count;

    reg [127:0] plaintext_reg;

    wire [1407:0] round_keys;
    wire key_busy;
    wire key_done;

    reg key_start;

    // Sequential key expansion

    aes_key_expand u_key_expand (
        .clk(clk),
        .rst(rst),
        .start(key_start),
        .key(key),
        .round_keys(round_keys),
        .busy(key_busy),
        .done(key_done)
    );

    // Round key selection

    reg [127:0] selected_round_key;

    always @(*) begin
        case (round_count)
            4'd0:  selected_round_key = round_keys[1407:1280];
            4'd1:  selected_round_key = round_keys[1279:1152];
            4'd2:  selected_round_key = round_keys[1151:1024];
            4'd3:  selected_round_key = round_keys[1023:896];
            4'd4:  selected_round_key = round_keys[895:768];
            4'd5:  selected_round_key = round_keys[767:640];
            4'd6:  selected_round_key = round_keys[639:512];
            4'd7:  selected_round_key = round_keys[511:384];
            4'd8:  selected_round_key = round_keys[383:256];
            4'd9:  selected_round_key = round_keys[255:128];
            4'd10: selected_round_key = round_keys[127:0];
            default: selected_round_key = 128'h0;
        endcase
    end

    // AES datapath

    reg [127:0] state_reg;

    wire [127:0] initial_state;
    wire [127:0] normal_round_state;
    wire [127:0] final_round_state;

    aes_add_round_key u_initial_add_key (
        .state_in(plaintext_reg),
        .round_key(round_keys[1407:1280]),
        .state_out(initial_state)
    );

    aes_round u_round (
        .state_in(state_reg),
        .round_key(selected_round_key),
        .state_out(normal_round_state)
    );

    aes_final_round u_final_round (
        .state_in(state_reg),
        .round_key(round_keys[127:0]),
        .state_out(final_round_state)
    );

    // Encryption FSM

    assign busy = (state != IDLE) && (state != COMPLETE);

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            round_count <= 4'd0;
            plaintext_reg <= 128'h0;
            state_reg <= 128'h0;
            ciphertext <= 128'h0;
            done <= 1'b0;
            key_start <= 1'b0;
        end
        else begin
            done <= 1'b0;
            key_start <= 1'b0;

            case (state)

                IDLE: begin
                    if (start) begin
                        plaintext_reg <= plaintext;
                        key_start <= 1'b1;
                        round_count <= 4'd0;
                        state <= KEY_EXPAND;
                    end
                end

                KEY_EXPAND: begin
                    if (key_done) begin
                        state <= INITIAL;
                    end
                end

                INITIAL: begin
                    state_reg <= initial_state;
                    round_count <= 4'd1;
                    state <= ROUNDS;
                end

                ROUNDS: begin
                    if (round_count < 4'd10) begin
                        state_reg <= normal_round_state;
                        round_count <= round_count + 1'b1;
                    end
                    else begin
                        state <= FINAL;
                    end
                end

                FINAL: begin
                    state_reg <= final_round_state;
                    ciphertext <= final_round_state;
                    state <= COMPLETE;
                end

                COMPLETE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
`timescale 1ns / 1ps

module aes_control (
    input  wire clk,
    input  wire rst,
    input  wire start,

    output reg busy, // Indicates whether the controller is performing an encryption operation
    output reg done,

    output reg initial_add_key, // initial AddRoundKey operation should be selected
    output reg round_enable, // normal AES round should be performed
    output reg final_round_enable, // final AES round should be performed

    output reg [3:0] round_key_sel, // selects AES round key to be used
    output reg [3:0] round // tracks the round number as the FSM progresses
);

    localparam IDLE = 3'd0;
    localparam INITIAL_KEY = 3'd1;
    localparam NORMAL_ROUND = 3'd2;
    localparam FINAL_ROUND = 3'd3;
    localparam DONE_STATE = 3'd4;

    reg [2:0] state;

    // FSM + ROUND COUNTER

    always @(posedge clk) begin

        if (rst) begin

            state <= IDLE;
            round <= 4'd0;

        end
        else begin

            case (state)

                // IDLE

                IDLE: begin

                    round <= 4'd0;

                    if (start)
                        state <= INITIAL_KEY;

                end

                // INITIAL ADDROUNDKEY

                INITIAL_KEY: begin

                    round <= 4'd1;

                    state <= NORMAL_ROUND;

                end

                // NORMAL ROUNDS 1 → 9

                NORMAL_ROUND: begin

                    if (round == 4'd9) begin

                        state <= FINAL_ROUND;
                        round <= 4'd10;

                    end
                    else begin

                        round <= round + 1'b1; // If the counter is not 9, it increments by one

                    end

                end

                // FINAL ROUND

                FINAL_ROUND: begin

                    state <= DONE_STATE;

                end

                // DONE

                DONE_STATE: begin

                    state <= IDLE;
                    round <= 4'd0;

                end


                default: begin

                    state <= IDLE;
                    round <= 4'd0;

                end

            endcase

        end

    end

    // OUTPUT DECODE

    always @(*) begin

        // Defaults

        busy = 1'b0;
        done = 1'b0;
        initial_add_key = 1'b0;
        round_enable = 1'b0;
        final_round_enable = 1'b0;
        round_key_sel = 4'd0;


        case (state)

            // IDLE

            IDLE: begin

                busy = 1'b0;

            end

            // INITIAL ADDROUNDKEY

            INITIAL_KEY: begin

                busy = 1'b1; // encryption is in progress
                initial_add_key = 1'b1; // perform the initial AddRoundKey operation
                round_key_sel = 4'd0; // datapath selects the original AES key (round key 0)

            end

            // NORMAL ROUND

            NORMAL_ROUND: begin

                busy = 1'b1; // Encryption is still in progress
                round_enable = 1'b1; // perform a normal AES round.
                round_key_sel = round; // current round number selects the corresponding round key

            end

            // FINAL ROUND

            FINAL_ROUND: begin

                busy = 1'b1;
                final_round_enable = 1'b1; // instructed to perform the final round without MixColumns
                round_key_sel = 4'd10; // select round key 10

            end

            DONE_STATE: begin

                done = 1'b1; // complete
                busy = 1'b0;

            end

            default: begin

                busy = 1'b0;

            end

        endcase

    end

endmodule
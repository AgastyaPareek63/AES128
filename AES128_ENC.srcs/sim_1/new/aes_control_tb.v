`timescale 1ns / 1ps

module aes_control_tb;

    reg clk;
    reg rst;
    reg start;

    wire busy;
    wire done;

    wire initial_add_key;
    wire round_enable;
    wire final_round_enable;

    wire [3:0] round_key_sel;
    wire [3:0] round;

    integer errors;

    // DUT

    aes_control dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .busy(busy),
        .done(done),

        .initial_add_key(initial_add_key),
        .round_enable(round_enable),
        .final_round_enable(final_round_enable),

        .round_key_sel(round_key_sel),
        .round(round)
    );

    // CLOCK

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // TEST

    initial begin

        errors = 0;
        rst = 1'b1;
        start = 1'b0;

        $display("AES CONTROL FSM TEST");

        // Reset

        #12;

        rst = 1'b0;

        #2;

        if (busy !== 1'b0) begin

            $display("ERROR: FSM not idle after reset");

            errors = errors + 1;

        end


        // Start encryption

        start = 1'b1;

        #10;

        start = 1'b0;


        // Initial AddRoundKey

        #1;

        if (initial_add_key !== 1'b1 || round_key_sel  !== 4'd0) begin

            $display("ERROR: Initial AddRoundKey");
            $display("initial_add_key = %b", initial_add_key);
            $display("round_key_sel = %d", round_key_sel);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Initial AddRoundKey");

        end


        // Round 1

        #10;

        if (round_enable !== 1'b1 || round_key_sel !== 4'd1) begin

            $display("ERROR: Round 1");

            errors = errors + 1;

        end
        else begin

            $display("PASS: Round 1");

        end

        // Rounds 2 → 9

        repeat (8) begin

            #10;

        end


        if (round_enable !== 1'b1 || round_key_sel !== 4'd9) begin

            $display("ERROR: Round 9");
            $display("round_key_sel = %d", round_key_sel);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Round 9");

        end

        // Final Round

        #10;

        if (final_round_enable !== 1'b1 || round_key_sel !== 4'd10) begin

            $display("ERROR: Final Round");
            $display("round_key_sel = %d", round_key_sel);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Final Round");

        end

        #10;

        if (done !== 1'b1) begin

            $display("ERROR: DONE state");

            errors = errors + 1;

        end
        else begin

            $display("PASS: DONE");

        end

        // Final result

        if (errors == 0)
            $display("ALL AES CONTROL FSM TESTS PASSED");
        else
            $display("AES CONTROL FSM TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
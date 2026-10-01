`timescale 1ns / 1ps

module aes_final_round_tb;

    reg  [127:0] state_in;
    reg  [127:0] round_key;
    
    wire [127:0] state_out;

    integer errors;


    // DUT

    aes_final_round dut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    // Test

    initial begin

        errors = 0;

        $display("AES-128 FINAL ROUND TEST");

        // Input = output of AES Round 9

        state_in = 128'hbd6e7c3df2b5779e0b61216e8b10b689;


        // AES-128 Round 10 key

        round_key = 128'h13111d7fe3944a17f307a78b4d2b30c5;


        #10;

        // Expected ciphertext

        if (state_out !== 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin

            $display("ERROR: Final Round");
            $display("State = %h", state_in);
            $display("Round Key = %h", round_key);
            $display("Output = %h", state_out);

            $display("Expected = %h", 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Final Round");
            $display("State = %h", state_in);
            $display("Round Key = %h", round_key);
            $display("Output = %h", state_out);

        end

        // Final result

        if (errors == 0)
            $display("ALL FINAL ROUND TESTS PASSED");
        else
            $display("FINAL ROUND TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
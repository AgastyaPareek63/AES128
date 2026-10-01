`timescale 1ns / 1ps

module aes_add_round_key_tb;

    reg [127:0] state_in;
    reg [127:0] round_key;
    wire [127:0] state_out;

    integer errors;

    aes_add_round_key dut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    initial begin

        errors = 0;

        $display("AES-128 ADDROUNDKEY TEST");

        // Test 1: Standard AES initial AddRoundKey

        state_in = 128'h00112233445566778899aabbccddeeff;
        round_key = 128'h000102030405060708090a0b0c0d0e0f;

        #10;

        if (state_out !== 128'h00102030405060708090a0b0c0d0e0f0) begin

        $display("ERROR: Test 1");
        $display("State = %h", state_in);
        $display("Round Key = %h", round_key);
        $display("Output = %h", state_out);
        $display("Expected = %h", 128'h00102030405060708090a0b0c0d0e0f0);
    
        errors = errors + 1;
    
        end
        else begin

            $display("PASS: Test 1");
            $display("State = %h", state_in);
            $display("Round Key = %h", round_key);
            $display("Output = %h", state_out);

        end

        // Test 2: XOR with zero
        // Output should remain unchanged

        state_in = 128'h123456789abcdef00123456789abcdef;
        round_key = 128'h00000000000000000000000000000000;

        #10;

        if (state_out !== state_in) begin

            $display("ERROR: Test 2");
            $display("Output = %h", state_out);
            $display("Expected = %h", state_in);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Test 2");

        end

        // Test 3: Zero state XOR key
        // Output should equal the key

        state_in = 128'h00000000000000000000000000000000;
        round_key = 128'hfedcba98765432100123456789abcdef;

        #10;

        if (state_out !== round_key) begin

            $display("ERROR: Test 3");
            $display("Output = %h", state_out);
            $display("Expected = %h", round_key);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Test 3");

        end

        // Final result

        if (errors == 0)
            $display("ALL ADDROUNDKEY TESTS PASSED");
        else
            $display("ADDROUNDKEY TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
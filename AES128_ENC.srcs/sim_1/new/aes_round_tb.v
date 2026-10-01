`timescale 1ns / 1ps

module aes_round_tb;

    reg [127:0] state_in;
    reg [127:0] round_key;

    wire [127:0] state_out;

    integer errors;


    // DUT

    aes_round dut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    // Test

    initial begin

        errors = 0;
        $display("AES-128 ROUND TEST");
        
        // Input to Round 1
       
        state_in = 128'h00102030405060708090a0b0c0d0e0f0;

        round_key = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe;

        #10;


        // Expected Round 1 output

        if (state_out !== 128'h89d810e8855ace682d1843d8cb128fe4) begin

            $display("ERROR: AES Round 1");

            $display("State = %h", state_in);
            $display("Round Key = %h", round_key);
            $display("Output = %h", state_out);

            $display("Expected = %h", 128'h89d810e8855ace682d1843d8cb128fe4);

            errors = errors + 1;

        end
        else begin

            $display("PASS: AES Round 1");

            $display("State = %h", state_in);
            $display("Round Key = %h", round_key);
            $display("Output = %h", state_out);

        end

        // Final result


        if (errors == 0)
            $display("ALL AES ROUND TESTS PASSED");
        else
            $display("AES ROUND TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
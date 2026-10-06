`timescale 1ns / 1ps

module aes128_encrypt_tb;

    reg clk;
    reg rst;
    reg start;

    reg [127:0] plaintext;
    reg [127:0] key;

    wire [127:0] ciphertext;

    wire busy;
    wire done;

    integer errors;


    // DUT

    aes128_encrypt dut (

        .clk(clk),
        .rst(rst),
        .start(start),

        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext),

        .busy(busy),
        .done(done)

    );

    // CLOCK
    // 10 ns period

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // TEST

    initial begin

        errors = 0;

        rst = 1'b1;
        start = 1'b0;

        plaintext = 128'h00112233445566778899aabbccddeeff;
        key = 128'h000102030405060708090a0b0c0d0e0f;

        $display("AES-128 COMPLETE ENCRYPTION TEST");

        // Reset

        #12;

        rst = 1'b0;

        #3;

        // Start encryption

        start = 1'b1;

        #10;

        start = 1'b0;

        $display("Encryption started");

        // Wait for DONE

        wait (done == 1'b1);

        // Check ciphertext

        if (ciphertext !== 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin

            $display("ERROR: AES-128 encryption");
            $display("Plaintext = %h", plaintext);
            $display("Key = %h", key);
            $display("Ciphertext = %h", ciphertext);
            $display("Expected = %h", 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

            errors = errors + 1;

        end

        else begin

            $display("PASS: AES-128 encryption");
            $display("Plaintext = %h", plaintext);
            $display("Key = %h", key);
            $display("Ciphertext = %h", ciphertext);

        end

        // Check DONE

        if (done !== 1'b1) begin

            $display("ERROR: DONE not asserted");

            errors = errors + 1;

        end

        else begin

            $display("PASS: DONE asserted");

        end

        // Final result

        if (errors == 0)
            $display("ALL AES-128 ENCRYPTION TESTS PASSED");

        else
            $display("AES-128 ENCRYPTION TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
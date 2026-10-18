`timescale 1ns / 1ps

module aes_key_expand_tb;

    reg [127:0] key;
    wire [1407:0] round_keys;

    integer errors;

    aes_key_expand dut (
        .key(key),
        .round_keys(round_keys)
    );

    initial begin

        errors = 0;

        $display("AES-128 KEY EXPANSION TEST");
      
        // Standard AES-128 test key
        key = 128'h000102030405060708090a0b0c0d0e0f;

        #10;

        // Round Key 0

        if (round_keys[1407:1280] !== 128'h000102030405060708090a0b0c0d0e0f) begin

            $display("ERROR: K0");
            $display("Expected = 000102030405060708090a0b0c0d0e0f");
            $display("Got = %h", round_keys[1407:1280]);
            errors = errors + 1;

        end
        else
            $display("PASS: K0");


        // K1
        if (round_keys[1279:1152] !== 128'hd6aa74fdd2af72fadaa678f1d6ab76fe) begin

            $display("ERROR: K1");
            $display("Expected = d6aa74fdd2af72fadaa678f1d6ab76fe");
            $display("Got = %h", round_keys[1279:1152]);
            errors = errors + 1;

        end
        else
            $display("PASS: K1");


        // K2
        if (round_keys[1151:1024] !== 128'hb692cf0b643dbdf1be9bc5006830b3fe) begin

            $display("ERROR: K2");
            $display("Expected = b692cf0b643dbdf1be9bc5006830b3fe");
            $display("Got = %h", round_keys[1151:1024]);
            errors = errors + 1;

        end
        else
            $display("PASS: K2");


        // K3
        if (round_keys[1023:896] !== 128'hb6ff744ed2c2c9bf6c590cbf0469bf41) begin

            $display("ERROR: K3");
            $display("Expected = b6ff744ed2c2c9bf6c590cbf0469bf41");
            $display("Got = %h", round_keys[1023:896]);
            errors = errors + 1;

        end
        else
            $display("PASS: K3");


        // K4
        if (round_keys[895:768] !== 128'h47f7f7bc95353e03f96c32bcfd058dfd) begin

            $display("ERROR: K4");
            $display("Expected = 47f7f7bc95353e03f96c32bcfd058dfd");
            $display("Got = %h", round_keys[895:768]);
            errors = errors + 1;

        end
        else
            $display("PASS: K4");


        // K5
        if (round_keys[767:640] !== 128'h3caaa3e8a99f9deb50f3af57adf622aa) begin

            $display("ERROR: K5");
            $display("Expected = 3caaa3e8a99f9deb50f3af57adf622aa");
            $display("Got = %h", round_keys[767:640]);
            errors = errors + 1;

        end
        else
            $display("PASS: K5");


        // K6
        if (round_keys[639:512] !== 128'h5e390f7df7a69296a7553dc10aa31f6b) begin

            $display("ERROR: K6");
            $display("Expected = 5e390f7df7a69296a7553dc10aa31f6b");
            $display("Got = %h", round_keys[639:512]);
            errors = errors + 1;

        end
        else
            $display("PASS: K6");


        // K7
        if (round_keys[511:384] !== 128'h14f9701ae35fe28c440adf4d4ea9c026) begin

            $display("ERROR: K7");
            $display("Expected = 14f9701ae35fe28c440adf4d4ea9c026");
            $display("Got = %h", round_keys[511:384]);
            errors = errors + 1;

        end
        else
            $display("PASS: K7");


        // K8
        if (round_keys[383:256] !== 128'h47438735a41c65b9e016baf4aebf7ad2) begin

            $display("ERROR: K8");
            $display("Expected = 47438735a41c65b9e016baf4aebf7ad2");
            $display("Got = %h", round_keys[383:256]);
            errors = errors + 1;

        end
        else
            $display("PASS: K8");


        // K9
        if (round_keys[255:128] !== 128'h549932d1f08557681093ed9cbe2c974e) begin

            $display("ERROR: K9");
            $display("Expected = 549932d1f08557681093ed9cbe2c974e");
            $display("Got = %h", round_keys[255:128]);
            errors = errors + 1;

        end
        else
            $display("PASS: K9");


        // K10
        if (round_keys[127:0] !== 128'h13111d7fe3944a17f307a78b4d2b30c5) begin

            $display("ERROR: K10");
            $display("Expected = 13111d7fe3944a17f307a78b4d2b30c5");
            $display("Got = %h", round_keys[127:0]);
            errors = errors + 1;

        end
        else
            $display("PASS: K10");

        // Final result

        if (errors == 0)
            $display("ALL KEY EXPANSION TESTS PASSED");
        else
            $display("KEY EXPANSION TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
`timescale 1ns / 1ps

module aes_key_expand_tb;

    // =========================================================
    // INPUTS
    // =========================================================

    reg clk;
    reg rst;
    reg start;
    reg [127:0] key;

    // =========================================================
    // OUTPUTS
    // =========================================================

    wire [1407:0] round_keys;
    wire busy;
    wire done;

    integer errors;

    // =========================================================
    // DUT: AES-128 KEY EXPANSION
    // =========================================================

    aes_key_expand dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .key(key),
        .round_keys(round_keys),
        .busy(busy),
        .done(done)
    );

    // =========================================================
    // CLOCK GENERATION: 10 ns PERIOD
    // =========================================================

    always #5 clk = ~clk;

    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        clk    = 1'b0;
        rst    = 1'b1;
        start  = 1'b0;
        key    = 128'h000102030405060708090a0b0c0d0e0f;
        errors = 0;

        $display("========================================");
        $display("AES-128 KEY EXPANSION TEST");
        $display("========================================");

        // Apply reset
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Start key expansion
        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Wait for the key expansion to finish
        wait (done === 1'b1);
        #1;

        // =====================================================
        // ROUND KEY 0
        // =====================================================

        if (round_keys[1407:1280] !==
            128'h000102030405060708090a0b0c0d0e0f) begin

            $display("FAIL: K0");
            $display("Expected: %032h",
                     128'h000102030405060708090a0b0c0d0e0f);
            $display("Got     : %032h", round_keys[1407:1280]);
            errors = errors + 1;

        end else begin
            $display("PASS: K0");
        end

        // =====================================================
        // ROUND KEY 1
        // =====================================================

        if (round_keys[1279:1152] !==
            128'hd6aa74fdd2af72fadaa678f1d6ab76fe) begin

            $display("FAIL: K1");
            $display("Expected: %032h",
                     128'hd6aa74fdd2af72fadaa678f1d6ab76fe);
            $display("Got     : %032h", round_keys[1279:1152]);
            errors = errors + 1;

        end else begin
            $display("PASS: K1");
        end

        // =====================================================
        // ROUND KEY 2
        // =====================================================

        if (round_keys[1151:1024] !==
            128'hb692cf0b643dbdf1be9bc5006830b3fe) begin

            $display("FAIL: K2");
            $display("Expected: %032h",
                     128'hb692cf0b643dbdf1be9bc5006830b3fe);
            $display("Got     : %032h", round_keys[1151:1024]);
            errors = errors + 1;

        end else begin
            $display("PASS: K2");
        end

        // =====================================================
        // ROUND KEY 3
        // =====================================================

        if (round_keys[1023:896] !==
            128'hb6ff744ed2c2c9bf6c590cbf0469bf41) begin

            $display("FAIL: K3");
            $display("Expected: %032h",
                     128'hb6ff744ed2c2c9bf6c590cbf0469bf41);
            $display("Got     : %032h", round_keys[1023:896]);
            errors = errors + 1;

        end else begin
            $display("PASS: K3");
        end

        // =====================================================
        // ROUND KEY 4
        // =====================================================

        if (round_keys[895:768] !==
            128'h47f7f7bc95353e03f96c32bcfd058dfd) begin

            $display("FAIL: K4");
            $display("Expected: %032h",
                     128'h47f7f7bc95353e03f96c32bcfd058dfd);
            $display("Got     : %032h", round_keys[895:768]);
            errors = errors + 1;

        end else begin
            $display("PASS: K4");
        end

        // =====================================================
        // ROUND KEY 5
        // =====================================================

        if (round_keys[767:640] !==
            128'h3caaa3e8a99f9deb50f3af57adf622aa) begin

            $display("FAIL: K5");
            $display("Expected: %032h",
                     128'h3caaa3e8a99f9deb50f3af57adf622aa);
            $display("Got     : %032h", round_keys[767:640]);
            errors = errors + 1;

        end else begin
            $display("PASS: K5");
        end

        // =====================================================
        // ROUND KEY 6
        // =====================================================

        if (round_keys[639:512] !==
            128'h5e390f7df7a69296a7553dc10aa31f6b) begin

            $display("FAIL: K6");
            $display("Expected: %032h",
                     128'h5e390f7df7a69296a7553dc10aa31f6b);
            $display("Got     : %032h", round_keys[639:512]);
            errors = errors + 1;

        end else begin
            $display("PASS: K6");
        end

        // =====================================================
        // ROUND KEY 7
        // =====================================================

        if (round_keys[511:384] !==
            128'h14f9701ae35fe28c440adf4d4ea9c026) begin

            $display("FAIL: K7");
            $display("Expected: %032h",
                     128'h14f9701ae35fe28c440adf4d4ea9c026);
            $display("Got     : %032h", round_keys[511:384]);
            errors = errors + 1;

        end else begin
            $display("PASS: K7");
        end

        // =====================================================
        // ROUND KEY 8
        // =====================================================

        if (round_keys[383:256] !==
            128'h47438735a41c65b9e016baf4aebf7ad2) begin

            $display("FAIL: K8");
            $display("Expected: %032h",
                     128'h47438735a41c65b9e016baf4aebf7ad2);
            $display("Got     : %032h", round_keys[383:256]);
            errors = errors + 1;

        end else begin
            $display("PASS: K8");
        end

        // =====================================================
        // ROUND KEY 9
        // =====================================================

        if (round_keys[255:128] !==
            128'h549932d1f08557681093ed9cbe2c974e) begin

            $display("FAIL: K9");
            $display("Expected: %032h",
                     128'h549932d1f08557681093ed9cbe2c974e);
            $display("Got     : %032h", round_keys[255:128]);
            errors = errors + 1;

        end else begin
            $display("PASS: K9");
        end

        // =====================================================
        // ROUND KEY 10
        // =====================================================

        if (round_keys[127:0] !==
            128'h13111d7fe3944a17f307a78b4d2b30c5) begin

            $display("FAIL: K10");
            $display("Expected: %032h",
                     128'h13111d7fe3944a17f307a78b4d2b30c5);
            $display("Got     : %032h", round_keys[127:0]);
            errors = errors + 1;

        end else begin
            $display("PASS: K10");
        end

        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("----------------------------------------");

        if (errors == 0) begin
            $display("ALL KEY EXPANSION TESTS PASSED");
        end else begin
            $display("KEY EXPANSION TEST FAILED: %0d errors", errors);
        end

        $display("----------------------------------------");

        if (busy !== 1'b0) begin
            $display("ERROR: BUSY did not return to zero");
            errors = errors + 1;
        end

        $finish;

    end

    // =========================================================
    // TIMEOUT PROTECTION
    // =========================================================

    initial begin
        #10000;
        $display("ERROR: Simulation timed out");
        $finish;
    end

endmodule
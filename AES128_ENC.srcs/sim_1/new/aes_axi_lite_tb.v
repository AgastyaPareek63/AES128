`timescale 1ns / 1ps

module aes_axi_lite_tb;

    // =========================================================
    // AXI CLOCK AND RESET
    // =========================================================

    reg S_AXI_ACLK;
    reg S_AXI_ARESETN;

    // =========================================================
    // AXI WRITE ADDRESS CHANNEL
    // =========================================================

    reg  [5:0] S_AXI_AWADDR;
    reg        S_AXI_AWVALID;
    wire       S_AXI_AWREADY;

    // =========================================================
    // AXI WRITE DATA CHANNEL
    // =========================================================

    reg  [31:0] S_AXI_WDATA;
    reg  [3:0]  S_AXI_WSTRB;
    reg         S_AXI_WVALID;
    wire        S_AXI_WREADY;

    // =========================================================
    // AXI WRITE RESPONSE CHANNEL
    // =========================================================

    wire [1:0] S_AXI_BRESP;
    wire       S_AXI_BVALID;
    reg        S_AXI_BREADY;

    // =========================================================
    // AXI READ ADDRESS CHANNEL
    // =========================================================

    reg  [5:0] S_AXI_ARADDR;
    reg        S_AXI_ARVALID;
    wire       S_AXI_ARREADY;

    // =========================================================
    // AXI READ DATA CHANNEL
    // =========================================================

    wire [31:0] S_AXI_RDATA;
    wire [1:0]  S_AXI_RRESP;
    wire        S_AXI_RVALID;
    reg         S_AXI_RREADY;

    // =========================================================
    // AES INTERFACE
    // =========================================================

    wire [127:0] plaintext;
    wire [127:0] key;
    wire         start;

    reg [31:0] read_data;

    integer errors;

    // =========================================================
    // DUT: AXI4-LITE AES-128 ENCRYPTION WRAPPER
    // =========================================================

    aes_axi_lite dut (
        .S_AXI_ACLK   (S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),

        .S_AXI_AWADDR (S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),

        .S_AXI_WDATA  (S_AXI_WDATA),
        .S_AXI_WSTRB  (S_AXI_WSTRB),
        .S_AXI_WVALID (S_AXI_WVALID),
        .S_AXI_WREADY (S_AXI_WREADY),

        .S_AXI_BRESP  (S_AXI_BRESP),
        .S_AXI_BVALID (S_AXI_BVALID),
        .S_AXI_BREADY (S_AXI_BREADY),

        .S_AXI_ARADDR (S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),

        .S_AXI_RDATA  (S_AXI_RDATA),
        .S_AXI_RRESP  (S_AXI_RRESP),
        .S_AXI_RVALID (S_AXI_RVALID),
        .S_AXI_RREADY (S_AXI_RREADY),

        .plaintext(plaintext),
        .key      (key),
        .start    (start)
    );

    // =========================================================
    // CLOCK: 10 ns PERIOD
    // =========================================================

    initial begin
        S_AXI_ACLK = 1'b0;
        forever #5 S_AXI_ACLK = ~S_AXI_ACLK;
    end

    // =========================================================
    // AXI WRITE TASK
    // Handles AW and W handshakes independently.
    // =========================================================

    task axi_write;
        input [5:0]  address;
        input [31:0] data;

        integer timeout;
        reg aw_accepted;
        reg w_accepted;

        begin
            aw_accepted = 1'b0;
            w_accepted  = 1'b0;
            timeout     = 0;

            // Drive transaction away from the active clock edge.
            @(negedge S_AXI_ACLK);

            S_AXI_AWADDR  = address;
            S_AXI_AWVALID = 1'b1;

            S_AXI_WDATA  = data;
            S_AXI_WSTRB  = 4'b1111;
            S_AXI_WVALID = 1'b1;

            // Wait until both independent channels handshake.
            while ((!aw_accepted || !w_accepted) &&
                   (timeout < 100)) begin

                @(posedge S_AXI_ACLK);

                if (S_AXI_AWVALID && S_AXI_AWREADY)
                    aw_accepted = 1'b1;

                if (S_AXI_WVALID && S_AXI_WREADY)
                    w_accepted = 1'b1;

                timeout = timeout + 1;
            end

            @(negedge S_AXI_ACLK);

            S_AXI_AWVALID = 1'b0;
            S_AXI_WVALID  = 1'b0;

            if (!aw_accepted || !w_accepted) begin
                $display("FAIL: AXI write-channel timeout");
                $display("Address = %h, Data = %h", address, data);
                errors = errors + 1;
                disable axi_write;
            end

            // Wait for write response.
            timeout = 0;
            S_AXI_BREADY = 1'b1;

            while (!S_AXI_BVALID && timeout < 100) begin
                @(posedge S_AXI_ACLK);
                timeout = timeout + 1;
            end

            if (!S_AXI_BVALID) begin
                @(negedge S_AXI_ACLK);
                S_AXI_BREADY = 1'b0;

                $display("FAIL: AXI write-response timeout");
                $display("Address = %h", address);
                errors = errors + 1;
                disable axi_write;
            end

            // Check response before completing handshake.
            if (S_AXI_BRESP !== 2'b00) begin
                $display("FAIL: AXI write response");
                $display("Address = %h, BRESP = %b",
                         address, S_AXI_BRESP);
                errors = errors + 1;
            end

            @(posedge S_AXI_ACLK);
            @(negedge S_AXI_ACLK);

            S_AXI_BREADY = 1'b0;
        end
    endtask

    // =========================================================
    // AXI READ TASK
    // =========================================================

    task axi_read;
        input  [5:0]  address;
        output [31:0] data;

        integer timeout;
        reg address_accepted;

        begin
            address_accepted = 1'b0;
            timeout = 0;
            data = 32'h00000000;

            @(negedge S_AXI_ACLK);

            S_AXI_ARADDR  = address;
            S_AXI_ARVALID = 1'b1;

            // Wait for read-address handshake.
            while (!address_accepted && timeout < 100) begin
                @(posedge S_AXI_ACLK);

                if (S_AXI_ARVALID && S_AXI_ARREADY)
                    address_accepted = 1'b1;

                timeout = timeout + 1;
            end

            @(negedge S_AXI_ACLK);
            S_AXI_ARVALID = 1'b0;

            if (!address_accepted) begin
                $display("FAIL: AXI read-address timeout");
                $display("Address = %h", address);
                errors = errors + 1;
                disable axi_read;
            end

            // Wait for read response.
            timeout = 0;
            S_AXI_RREADY = 1'b1;

            while (!S_AXI_RVALID && timeout < 100) begin
                @(posedge S_AXI_ACLK);
                timeout = timeout + 1;
            end

            if (!S_AXI_RVALID) begin
                @(negedge S_AXI_ACLK);
                S_AXI_RREADY = 1'b0;

                $display("FAIL: AXI read-response timeout");
                $display("Address = %h", address);
                errors = errors + 1;
                disable axi_read;
            end

            // Capture and validate response.
            data = S_AXI_RDATA;

            if (S_AXI_RRESP !== 2'b00) begin
                $display("FAIL: AXI read response");
                $display("Address = %h, RRESP = %b",
                         address, S_AXI_RRESP);
                errors = errors + 1;
            end

            @(posedge S_AXI_ACLK);
            @(negedge S_AXI_ACLK);

            S_AXI_RREADY = 1'b0;
        end
    endtask

    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        errors = 0;

        S_AXI_ARESETN = 1'b0;

        S_AXI_AWADDR  = 6'h00;
        S_AXI_AWVALID = 1'b0;

        S_AXI_WDATA  = 32'h00000000;
        S_AXI_WSTRB  = 4'b0000;
        S_AXI_WVALID = 1'b0;

        S_AXI_BREADY = 1'b0;

        S_AXI_ARADDR  = 6'h00;
        S_AXI_ARVALID = 1'b0;

        S_AXI_RREADY = 1'b0;

        read_data = 32'h00000000;

        $display("========================================");
        $display("AXI4-LITE AES-128 TEST");
        $display("========================================");

        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        repeat (5) @(posedge S_AXI_ACLK);
        @(negedge S_AXI_ACLK);

        S_AXI_ARESETN = 1'b1;

        repeat (2) @(posedge S_AXI_ACLK);

        // -----------------------------------------------------
        // STEP 1: WRITE PLAINTEXT
        // -----------------------------------------------------

        $display("\nTEST 1: Writing plaintext");

        axi_write(6'h10, 32'h00112233);
        axi_write(6'h14, 32'h44556677);
        axi_write(6'h18, 32'h8899AABB);
        axi_write(6'h1C, 32'hCCDDEEFF);

        // -----------------------------------------------------
        // STEP 2: WRITE KEY
        // -----------------------------------------------------

        $display("\nTEST 2: Writing key");

        axi_write(6'h20, 32'h00010203);
        axi_write(6'h24, 32'h04050607);
        axi_write(6'h28, 32'h08090A0B);
        axi_write(6'h2C, 32'h0C0D0E0F);

        // -----------------------------------------------------
        // STEP 3: VERIFY INPUT REGISTERS
        // -----------------------------------------------------

        $display("\nTEST 3: Verifying inputs");

        if (plaintext !==
            128'h00112233445566778899AABBCCDDEEFF) begin

            $display("FAIL: Plaintext register mismatch");
            $display("Expected = %032h",
                     128'h00112233445566778899AABBCCDDEEFF);
            $display("Actual   = %032h", plaintext);

            errors = errors + 1;

        end else begin
            $display("PASS: Plaintext loaded correctly");
        end

        if (key !==
            128'h000102030405060708090A0B0C0D0E0F) begin

            $display("FAIL: Key register mismatch");
            $display("Expected = %032h",
                     128'h000102030405060708090A0B0C0D0E0F);
            $display("Actual   = %032h", key);

            errors = errors + 1;

        end else begin
            $display("PASS: Key loaded correctly");
        end

        // -----------------------------------------------------
        // STEP 4: START ENCRYPTION
        // -----------------------------------------------------

        $display("\nTEST 4: Starting AES encryption");

        axi_write(6'h00, 32'h00000001);

        // Start pulse should return low after its active cycle.
        @(negedge S_AXI_ACLK);

        if (start !== 1'b0) begin
            $display("FAIL: START did not return low");
            errors = errors + 1;
        end else begin
            $display("PASS: START pulse completed");
        end

        // -----------------------------------------------------
        // STEP 5: VERIFY BUSY
        // -----------------------------------------------------

        $display("\nTEST 5: Checking BUSY status");

        begin : busy_check
            integer timeout;
            reg busy_seen;

            timeout = 0;
            busy_seen = 1'b0;

            while ((timeout < 100) && !busy_seen) begin
                axi_read(6'h04, read_data);

                if (read_data[0] === 1'b1)
                    busy_seen = 1'b1;
                else
                    timeout = timeout + 1;
            end

            if (busy_seen) begin
                $display("PASS: BUSY asserted");
            end else begin
                $display("FAIL: BUSY was not observed");
                $display("Last STATUS = %08h", read_data);
                errors = errors + 1;
            end
        end

        // -----------------------------------------------------
        // STEP 6: WAIT FOR DONE
        // -----------------------------------------------------

        $display("\nTEST 6: Waiting for DONE");

        begin : done_check
            integer timeout;
            reg done_seen;

            timeout = 0;
            done_seen = 1'b0;

            while ((timeout < 100) && !done_seen) begin
                axi_read(6'h04, read_data);

                if (read_data[1] === 1'b1)
                    done_seen = 1'b1;
                else
                    timeout = timeout + 1;
            end

            if (done_seen) begin
                $display("PASS: DONE asserted");
            end else begin
                $display("FAIL: DONE timeout");
                $display("Last STATUS = %08h", read_data);
                errors = errors + 1;
            end
        end

        // -----------------------------------------------------
        // STEP 7: READ AND VERIFY CIPHERTEXT
        // -----------------------------------------------------

        $display("\nTEST 7: Verifying ciphertext");

        axi_read(6'h30, read_data);

        if (read_data !== 32'h69C4E0D8) begin
            $display("FAIL: Ciphertext word 0");
            $display("Expected = 69C4E0D8");
            $display("Actual   = %08h", read_data);
            errors = errors + 1;
        end else begin
            $display("PASS: Ciphertext word 0 = %08h", read_data);
        end

        axi_read(6'h34, read_data);

        if (read_data !== 32'h6A7B0430) begin
            $display("FAIL: Ciphertext word 1");
            $display("Expected = 6A7B0430");
            $display("Actual   = %08h", read_data);
            errors = errors + 1;
        end else begin
            $display("PASS: Ciphertext word 1 = %08h", read_data);
        end

        axi_read(6'h38, read_data);

        if (read_data !== 32'hD8CDB780) begin
            $display("FAIL: Ciphertext word 2");
            $display("Expected = D8CDB780");
            $display("Actual   = %08h", read_data);
            errors = errors + 1;
        end else begin
            $display("PASS: Ciphertext word 2 = %08h", read_data);
        end

        axi_read(6'h3C, read_data);

        if (read_data !== 32'h70B4C55A) begin
            $display("FAIL: Ciphertext word 3");
            $display("Expected = 70B4C55A");
            $display("Actual   = %08h", read_data);
            errors = errors + 1;
        end else begin
            $display("PASS: Ciphertext word 3 = %08h", read_data);
        end

        // -----------------------------------------------------
        // FINAL RESULT
        // -----------------------------------------------------

        $display("\n========================================");

        if (errors == 0) begin
            $display("AXI4-LITE AES-128 TEST PASSED");
            $display("Plaintext  = 00112233445566778899AABBCCDDEEFF");
            $display("Key        = 000102030405060708090A0B0C0D0E0F");
            $display("Ciphertext = 69C4E0D86A7B0430D8CDB78070B4C55A");
        end else begin
            $display("AXI4-LITE AES-128 TEST FAILED");
            $display("Total errors = %0d", errors);
        end

        $display("========================================");

        #20;
        $finish;
    end

    // =========================================================
    // GLOBAL TIMEOUT
    // =========================================================

    initial begin
        #20000;
        $display("FAIL: Global simulation timeout");
        $finish;
    end

endmodule
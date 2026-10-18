`timescale 1ns / 1ps

module aes_axi_lite_tb;

    // AXI CLOCK / RESET

    reg S_AXI_ACLK;
    reg S_AXI_ARESETN;

    // AXI WRITE ADDRESS CHANNEL

    reg [5:0] S_AXI_AWADDR;
    reg S_AXI_AWVALID;
    wire S_AXI_AWREADY;

    // AXI WRITE DATA CHANNEL

    reg [31:0] S_AXI_WDATA;
    reg [3:0]  S_AXI_WSTRB;
    reg S_AXI_WVALID;
    wire S_AXI_WREADY;

    // AXI WRITE RESPONSE CHANNEL

    wire [1:0] S_AXI_BRESP;
    wire S_AXI_BVALID;
    reg S_AXI_BREADY;

    // AXI READ ADDRESS CHANNEL

    reg [5:0] S_AXI_ARADDR;
    reg S_AXI_ARVALID;
    wire S_AXI_ARREADY;

    // AXI READ DATA CHANNEL

    wire [31:0] S_AXI_RDATA;
    wire [1:0] S_AXI_RRESP;
    wire S_AXI_RVALID;
    reg S_AXI_RREADY;

    // AES INTERFACE

    wire [127:0] plaintext;
    wire [127:0] key;
    wire start;

    reg [31:0] read_data;

    // DUT

    aes_axi_lite dut (

        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),

        // Write address
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),

        // Write data
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),

        // Write response
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),

        // Read address
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),

        // Read data
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY  (S_AXI_RREADY),

        // AES
        .plaintext(plaintext),
        .key(key),
        .start(start)
    );

    // CLOCK 10 ns period

    initial begin
        S_AXI_ACLK = 1'b0;
        forever #5 S_AXI_ACLK = ~S_AXI_ACLK;
    end

    // AXI WRITE TASK

    task axi_write;

        input [5:0] address;
        input [31:0] data;

        begin

            @(posedge S_AXI_ACLK);

            S_AXI_AWADDR <= address;
            S_AXI_AWVALID <= 1'b1;

            S_AXI_WDATA <= data;
            S_AXI_WSTRB <= 4'b1111;
            S_AXI_WVALID <= 1'b1;

            // Wait until both address and data are accepted
            wait (S_AXI_AWREADY && S_AXI_WREADY);

            @(posedge S_AXI_ACLK);

            S_AXI_AWVALID <= 1'b0;
            S_AXI_WVALID <= 1'b0;

            // Wait for write response
            wait (S_AXI_BVALID);

            if (S_AXI_BRESP != 2'b00) begin

                $display("ERROR: AXI write failed");
                $display("Address = %h", address);
                $display("Data = %h", data);

                $stop;

            end

            S_AXI_BREADY <= 1'b1;

            @(posedge S_AXI_ACLK);

            S_AXI_BREADY <= 1'b0;

        end

    endtask

    // AXI READ TASK

    task axi_read;

        input [5:0] address;
        output [31:0] data;

        begin

            @(posedge S_AXI_ACLK);

            S_AXI_ARADDR <= address;
            S_AXI_ARVALID <= 1'b1;

            // Wait for address acceptance
            wait (S_AXI_ARREADY);

            @(posedge S_AXI_ACLK);

            S_AXI_ARVALID <= 1'b0;

            // Wait for read response
            wait (S_AXI_RVALID);

            data = S_AXI_RDATA;

            if (S_AXI_RRESP != 2'b00) begin

                $display("ERROR: AXI read failed");
                $display("Address = %h", address);

                $stop;

            end

            S_AXI_RREADY <= 1'b1;

            @(posedge S_AXI_ACLK);

            S_AXI_RREADY <= 1'b0;

        end

    endtask

    // MAIN TEST

    initial begin

        // Initial values

        S_AXI_ARESETN = 1'b0;

        S_AXI_AWADDR = 6'h00;
        S_AXI_AWVALID = 1'b0;

        S_AXI_WDATA = 32'h00000000;
        S_AXI_WSTRB = 4'b0000;
        S_AXI_WVALID = 1'b0;

        S_AXI_BREADY = 1'b0;

        S_AXI_ARADDR = 6'h00;
        S_AXI_ARVALID = 1'b0;

        S_AXI_RREADY = 1'b0;

        read_data = 32'h00000000;

        // Reset

        repeat (5) @(posedge S_AXI_ACLK);

        S_AXI_ARESETN = 1'b1;

        $display(" AXI4-LITE -> AES-128 TEST START");

        // STEP 1: WRITE PLAINTEXT

        $display("Writing plaintext");

        axi_write(6'h10, 32'h00112233);
        axi_write(6'h14, 32'h44556677);
        axi_write(6'h18, 32'h8899AABB);
        axi_write(6'h1C, 32'hCCDDEEFF);

        // STEP 2: WRITE KEY

        $display("Writing key");

        axi_write(6'h20, 32'h00010203);
        axi_write(6'h24, 32'h04050607);
        axi_write(6'h28, 32'h08090A0B);
        axi_write(6'h2C, 32'h0C0D0E0F);

        #20;

        // STEP 3: VERIFY INPUTS

        if (plaintext !== 128'h00112233445566778899AABBCCDDEEFF) begin

            $display("FAIL: Plaintext incorrect");
            $display("Expected = 00112233445566778899AABBCCDDEEFF");
            $display("Actual = %h", plaintext);

            $stop;

        end
        else begin

            $display("PASS: Plaintext loaded");
            $display("%h", plaintext);

        end

        if (key !== 128'h000102030405060708090A0B0C0D0E0F) begin

            $display("FAIL: Key incorrect");
            $display("Expected = 000102030405060708090A0B0C0D0E0F");
            $display("Actual = %h", key);

            $stop;

        end
        else begin

            $display("PASS: Key loaded");
            $display("%h", key);

        end

        // STEP 4: START AES

        $display("Starting AES");
        axi_write(6'h00, 32'h00000001);

        // START should be a pulse
        @(posedge S_AXI_ACLK);

        if (start !== 1'b0) begin

            $display("WARNING: START still high");

        end

        $display("PASS: AES start command issued");

        // STEP 5: WAIT FOR BUSY

        $display("Waiting for AES BUSY");

        // Give AES a few clocks to enter its active state
        repeat (3)
            @(posedge S_AXI_ACLK);

        axi_read(6'h04, read_data);

        if (read_data[0] !== 1'b1) begin

            $display("WARNING: BUSY not observed");
            $display("STATUS = %h", read_data);

        end
        else begin

            $display("PASS: AES BUSY asserted");
            $display("STATUS = %h", read_data);

        end

        // STEP 6: POLL DONE

        $display("Waiting for AES DONE");

        begin : wait_for_done

            integer timeout;
            reg done_seen;

            timeout = 0;
            done_seen = 1'b0;

            while ((timeout < 100) && !done_seen) begin

                axi_read(6'h04, read_data);

                if (read_data[1] === 1'b1) begin

                    done_seen = 1'b1;

                end
                else begin

                    timeout = timeout + 1;

                end

            end

            if (!done_seen) begin

                $display("FAIL: AES DONE timeout");
                $display("Last STATUS = %h", read_data);

                $stop;

            end

        end

        $display("PASS: AES DONE asserted");

        // STEP 7: READ CIPHERTEXT WORD 0

        axi_read(6'h30, read_data);

        if (read_data !== 32'h69C4E0D8) begin

            $display("FAIL: Ciphertext word 0");
            $display("Expected = 69C4E0D8");
            $display("Actual = %h", read_data);

            $stop;

        end

        $display("PASS: Ciphertext[127:96] = %h", read_data);

        // STEP 8: READ CIPHERTEXT WORD 1

        axi_read(6'h34, read_data);

        if (read_data !== 32'h6A7B0430) begin

            $display("FAIL: Ciphertext word 1");
            $display("Expected = 6A7B0430");
            $display("Actual = %h", read_data);

            $stop;

        end

        $display("PASS: Ciphertext[95:64]  = %h", read_data);

        // STEP 9: READ CIPHERTEXT WORD 2

        axi_read(6'h38, read_data);

        if (read_data !== 32'hD8CDB780) begin

            $display("FAIL: Ciphertext word 2");
            $display("Expected = D8CDB780");
            $display("Actual = %h", read_data);

            $stop;

        end

        $display("PASS: Ciphertext[63:32] = %h", read_data);

        // STEP 10: READ CIPHERTEXT WORD 3

        axi_read(6'h3C, read_data);

        if (read_data !== 32'h70B4C55A) begin

            $display("FAIL: Ciphertext word 3");
            $display("Expected = 70B4C55A");
            $display("Actual = %h", read_data);

            $stop;

        end

        $display("PASS: Ciphertext[31:0] = %h", read_data);

        // FINAL RESULT

        $display(" AXI -> AES-128 TEST PASSED");

        $display("Plaintext = 00112233445566778899AABBCCDDEEFF");
        $display("Key = 000102030405060708090A0B0C0D0E0F");
        $display("Ciphertext = 69C4E0D86A7B0430D8CDB78070B4C55A");

        #20;

        $finish;

    end

endmodule
`timescale 1ns / 1ps

module aes_fifo_integration_tb;

    // CLOCKS

    reg wr_clk;
    reg rd_clk;

    // FIFO RESETS

    reg wr_rst;
    reg rd_rst;

    // FIFO WRITE SIDE

    reg wr_en;
    reg [127:0] din;

    wire full;
    wire almost_full;
    wire prog_full;


    // FIFO READ SIDE

    reg rd_en;

    wire [127:0] dout;

    wire empty;
    wire almost_empty;
    wire prog_empty;

    // ECC STATUS

    wire ecc_single_error;
    wire ecc_double_error;

    // AES

    reg aes_start;
    reg [127:0] aes_key;
    wire [127:0] ciphertext;

    wire aes_busy;
    wire aes_done;

    // TEST VARIABLES

    integer errors;

    // TEST DATA

    localparam [127:0] TEST_PLAINTEXT = 128'h00112233445566778899aabbccddeeff;

    localparam [127:0] TEST_KEY = 128'h000102030405060708090a0b0c0d0e0f;

    localparam [127:0] EXPECTED_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    // DUT

    aes_fifo_integration dut (

        // FIFO WRITE
        
        .wr_clk (wr_clk),
        .wr_rst(wr_rst),
        .wr_en(wr_en),
        .din(din),

        // FIFO READ

        .rd_clk(rd_clk),
        .rd_rst(rd_rst),
        .rd_en(rd_en),
        .dout(dout),

        // FIFO STATUS

        .full(full),
        .almost_full(almost_full),
        .prog_full(prog_full),

        .empty(empty),
        .almost_empty(almost_empty),
        .prog_empty(prog_empty),

        // ECC
        
        .ecc_single_error(ecc_single_error),
        .ecc_double_error(ecc_double_error),

        // AES

        .aes_start(aes_start),
        .aes_key(aes_key),

        .ciphertext(ciphertext),
        .aes_busy(aes_busy),
        .aes_done(aes_done)

    );

    // WRITE CLOCK
    // 10 ns period

    initial begin

        wr_clk = 1'b0;

        forever #5 wr_clk = ~wr_clk;

    end

    // READ CLOCK
    // 14 ns period

    initial begin

        rd_clk = 1'b0;

        forever #7 rd_clk = ~rd_clk;

    end

    // MAIN TEST

    initial begin

        errors = 0;

        // INITIAL VALUES

        wr_rst = 1'b1;
        rd_rst = 1'b1;

        wr_en = 1'b0;
        rd_en = 1'b0;

        din = 128'h0;

        aes_start = 1'b0;

        aes_key = TEST_KEY;


        $display("FIFO -> AES INTEGRATION TEST");

        // RESET

        $display("[TEST 1] Applying reset");

        #30;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        $display("PASS: Reset released");
        $display("");

        // WRITE AES PLAINTEXT INTO FIFO

        $display("[TEST 2] Writing plaintext into FIFO");

        // Change data/control away from write clock edge.

        @(negedge wr_clk);

        din = TEST_PLAINTEXT;
        wr_en = 1'b1;

        @(posedge wr_clk);

        #1;

        wr_en = 1'b0;
        din = 128'h0;

        $display("Plaintext written: = %h", TEST_PLAINTEXT);

        // WAIT FOR FIFO DATA TO CROSS CLOCK DOMAINS

        $display("[TEST 3] Waiting for FIFO data");

        wait (empty == 1'b0);

        $display("PASS: FIFO data available in read clock domain");

        // READ PLAINTEXT FROM FIFO

        $display("[TEST 4] Reading plaintext from FIFO");

        // Assert read enable on the falling edge, avoids a race with the FIFO's read-clock logic.

        @(negedge rd_clk);

        rd_en = 1'b1;


        // FIFO read occurs at the next rising edge.

        @(posedge rd_clk);

        #1;

        // VERIFY FIFO OUTPUT

        if (dout !== TEST_PLAINTEXT) begin

            $display("ERROR: FIFO output incorrect");

            $display("FIFO dout = %h", dout);
            $display("Expected = %h", TEST_PLAINTEXT);

            errors = errors + 1;

        end

        else begin

            $display("PASS: FIFO -> AES plaintext");

            $display("FIFO dout = %h", dout);

        end


        // Keep read enable asserted only for the read operation.

        @(negedge rd_clk);

        rd_en = 1'b0;

        // CHECK ECC STATUS

        $display("[TEST 5] Checking ECC status");

        if ((ecc_single_error !== 1'b0) ||(ecc_double_error !== 1'b0)) begin

            $display("ERROR: Unexpected ECC error");
            $display("Single error = %b",ecc_single_error);
            $display("Double error = %b",ecc_double_error);

            errors = errors + 1;

        end

        else begin

            $display("PASS: FIFO ECC status normal");

        end

        // WAIT FOR PLAINTEXT REGISTER TO BE STABLE

        $display("[TEST 6] Allowing FIFO -> AES buffer to settle");

        @(posedge rd_clk);

        #1;

        $display("PASS: FIFO -> AES buffer settling complete");
   
        // START AES ENCRYPTION

        $display("[TEST 7] Starting AES-128 encryption");

        @(negedge rd_clk);

        aes_start = 1'b1;

        @(posedge rd_clk);

        #1;

        aes_start = 1'b0;

        $display("AES encryption started");

        // WAIT FOR AES DONE

        $display("[TEST 8] Waiting for AES DONE");

        wait (aes_done == 1'b1);

        #1;

        $display("PASS: AES DONE asserted");

        // CHECK CIPHERTEXT

        $display("[TEST 9] Checking AES ciphertext");

        if (ciphertext !== EXPECTED_CIPHERTEXT) begin

            $display("ERROR: AES ciphertext incorrect");
            $display("Ciphertext = %h",ciphertext);
            $display("Expected = %h",EXPECTED_CIPHERTEXT);

            errors = errors + 1;

        end

        else begin

            $display("PASS: FIFO -> AES -> Ciphertext");
            $display("Ciphertext = %h",ciphertext);

        end

        $display("");

        // CHECK AES BUSY/DONE

        $display("[TEST 10] Checking AES control signals");

        if (aes_done !== 1'b1) begin

            $display("ERROR: AES DONE not asserted");

            errors = errors + 1;

        end

        else begin

            $display("PASS: AES DONE");

        end

        // AES is no longer busy once DONE is asserted.

        if (aes_busy !== 1'b0) begin

            $display("ERROR: AES BUSY still asserted at DONE");
            $display("aes_busy = %b", aes_busy);

            errors = errors + 1;

        end

        else begin

            $display("PASS: AES BUSY deasserted");

        end

        $display("");


        // FINAL RESULT

        if (errors == 0) begin

            $display("ALL FIFO -> AES INTEGRATION TESTS PASSED");

        end

        else begin

            $display("FIFO -> AES INTEGRATION TEST FAILED: %0d errors",errors);

        end

        #20;

        $finish;

    end

endmodule
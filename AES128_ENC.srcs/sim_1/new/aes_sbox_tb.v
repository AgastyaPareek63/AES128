`timescale 1ns / 1ps

module aes_sbox_tb;

    reg[7:0] sbox_in;
    wire [7:0] sbox_out;

    integer errors;

    aes_sbox dut (
        .sbox_in(sbox_in),
        .sbox_out(sbox_out)
    );

    task check_sbox;
        input [7:0] input_value;
        input [7:0] expected_value;
        begin
            sbox_in = input_value;
            #10;

            if (sbox_out !== expected_value) begin
                $display("ERROR: IN=%h OUT=%h EXPECTED=%h", input_value, sbox_out, expected_value);
                errors = errors + 1;
            end
            else begin
                $display("PASS: IN=%h OUT=%h", input_value, sbox_out);
            end
        end
    endtask

    initial begin

        errors = 0;
        sbox_in = 8'h00;

        #10;

        $display("AES-128 S-BOX TEST");

        // Known AES S-box values
        check_sbox(8'h00, 8'h63);
        check_sbox(8'h01, 8'h7c);
        check_sbox(8'h02, 8'h77);
        check_sbox(8'h03, 8'h7b);

        check_sbox(8'h09, 8'h01);
        check_sbox(8'h53, 8'hed);
        check_sbox(8'h7c, 8'h10);
        check_sbox(8'hff, 8'h16);

        check_sbox(8'h63, 8'hfb);
        check_sbox(8'hca, 8'h74);
        check_sbox(8'h7a, 8'hda);


        if (errors == 0)
            $display("ALL S-BOX TESTS PASSED");
        else
            $display("S-BOX TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule
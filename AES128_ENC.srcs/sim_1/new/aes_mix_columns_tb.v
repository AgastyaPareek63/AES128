`timescale 1ns / 1ps

module aes_mix_columns_tb;

    reg [127:0] state_in;
    wire [127:0] state_out;

    integer errors;

    aes_mix_columns dut (
        .state_in(state_in),
        .state_out(state_out)
    );

    initial begin

        errors = 0;

        $display("AES-128 MIXCOLUMNS TEST");

        // Test 1: Standard AES MixColumns example
        
        state_in = 128'hdb135345f20a225c01010101c6c6c6c6;

        #10;

        if (state_out !== 128'h8e4da1bc9fdc589d01010101c6c6c6c6) begin

            $display("ERROR: Test 1");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);
            $display("Expected = %h", 128'h8e4da1bc9fdc589d01010101c6c6c6c6);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Test 1");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);

        end

        // Test 2: All zeros

        state_in = 128'h00000000000000000000000000000000;

        #10;

        if (state_out !== 128'h00000000000000000000000000000000) begin

            $display("ERROR: Test 2");
            $display("Output = %h", state_out);
            $display("Expected = %h", 128'h00000000000000000000000000000000);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Test 2");

        end

        // Test 3: All FF

        state_in = 128'hffffffffffffffffffffffffffffffff;

        #10;

        if (state_out !== 128'hffffffffffffffffffffffffffffffff) begin

            $display("ERROR: Test 3");
            $display("Output = %h", state_out);
            $display("Expected = %h", 128'hffffffffffffffffffffffffffffffff);

            errors = errors + 1;

        end
        else begin

            $display("PASS: Test 3");

        end

        // Final result

        if (errors == 0)
            $display("ALL MIXCOLUMNS TESTS PASSED");
        else
            $display("MIXCOLUMNS TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
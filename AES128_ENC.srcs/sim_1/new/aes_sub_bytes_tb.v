`timescale 1ns / 1ps

module aes_sub_bytes_tb;

    reg [127:0] state_in;
    wire [127:0] state_out;

    integer errors;

    aes_sub_bytes dut (
        .state_in(state_in),
        .state_out(state_out)
    );

    initial begin

        errors = 0;

        $display("AES-128 SUBBYTES TEST");

        // Test 1: AES plaintext
        state_in = 128'h00112233445566778899aabbccddeeff;
        #10;

        if (state_out !== 128'h638293c31bfc33f5c4eeacea4bc12816) begin
            $display("ERROR: Test 1");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);
            $display("Expected = 638293c31bfc33f5c4eeacea4bc12816");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Test 1");
        end

        // Test 2: All zero bytes
        state_in = 128'h00000000000000000000000000000000;
        #10;

        if (state_out !== 128'h63636363636363636363636363636363) begin
            $display("ERROR: Test 2");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);
            $display("Expected = 63636363636363636363636363636363");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Test 2");
        end

        // Test 3: All FF bytes
        state_in = 128'hffffffffffffffffffffffffffffffff;
        #10;
        
        if (state_out !== 128'hffffffffffffffffffffffffffffffff) begin
            $display("ERROR: Test 3");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);
            $display("Expected = ffffffffffffffffffffffffffffffff");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Test 3");
        end 


        if (errors == 0)
        $display("ALL SHIFTROWS TESTS PASSED");
        else
        $display("SHIFTROWS TEST FAILED: %0d errors");
    
        $finish;

    end

endmodule
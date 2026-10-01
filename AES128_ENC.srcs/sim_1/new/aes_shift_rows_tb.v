`timescale 1ns / 1ps

module aes_shift_rows_tb;

    reg [127:0] state_in;
    wire [127:0] state_out;

    integer errors;

    aes_shift_rows dut (
        .state_in(state_in),
        .state_out(state_out)
    );

    initial begin

        errors = 0;
        $display("AES-128 SHIFTROWS TEST");


        state_in = 128'h638293c31bfc33f5c4eeacea4bc12816;

        #10;

        if (state_out !== 128'h63fcac161bee28c3c4c193f54b8233ea) begin

            $display("ERROR: Test 1");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);
            $display("Expected = 631bc44bfceec182ac28933316c3f5ea");

            errors = errors + 1;

        end
        else begin

            $display("PASS: Test 1");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);

        end

         //Test 2: All bytes identical.
      
        state_in = 128'h63636363636363636363636363636363;

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


         // Test 3: Sequential AES plaintext bytes
        state_in = 128'h00112233445566778899aabbccddeeff;
        #10;
        
        if (state_out !== 128'h0055aaff4499ee3388dd2277cc1166bb) begin
            $display("ERROR: Test 3");
            $display("Input = %h", state_in);
            $display("Output = %h", state_out);
            $display("Expected = 0055aaff4499ee3388dd2277cc1166bb");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Test 3");
        end
               
            end
    
endmodule
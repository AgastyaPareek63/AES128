`timescale 1ns / 1ps

module aes128_encrypt (

    input wire clk,
    input wire rst,
    input wire start,
    
    input wire [127:0] plaintext,
    input wire [127:0] key,
    
    output reg [127:0] ciphertext,
    
    output wire busy,
    output wire done
    
);

    wire initial_add_key;
    wire round_enable;
    wire final_round_enable;
    
    wire [3:0] round_key_sel;
    wire [3:0] round;
    
    aes_control u_control (
    
        .clk(clk),
        .rst(rst),
        .start(start),
        
        .busy(busy),
        .done(done),
        
        .initial_add_key(initial_add_key),
        .round_enable(round_enable),
        .final_round_enable(final_round_enable),
        
        .round_key_sel(round_key_sel),
        .round(round)
        
);

    wire [1407:0] round_keys;
    
    aes_key_expand u_key_expand (
    
        .key(key),
        .round_keys(round_keys)
    );
    
    reg [127:0] state_reg;
    
    reg [127:0] selected_round_key;
    
    always @(*) begin
    
        case(round_key_sel)
        
            4'd0: selected_round_key = round_keys[1407:1280];
            4'd1: selected_round_key = round_keys[1279:1152];
            4'd2: selected_round_key = round_keys[1151:1024];
            4'd3: selected_round_key = round_keys[1023:896];
            4'd4: selected_round_key = round_keys[895:768];
            4'd5: selected_round_key = round_keys[767:640];
            4'd6: selected_round_key = round_keys[639:512];
            4'd7: selected_round_key = round_keys[511:384];
            4'd8: selected_round_key = round_keys[383:256];
            4'd9: selected_round_key = round_keys[255:128];
            4'd10: selected_round_key = round_keys[127:0];   
            
        default: selected_round_key = 128'h0;
        
        endcase
        
     end
     
     wire [127:0] initial_state;
     
     aes_add_round_key u_initial_add_key (
     
        .state_in(plaintext),
        .round_key(selected_round_key),
        .state_out(initial_state)
        
     );
     
     wire [127:0] normal_round_state;
     
     aes_round u_round (
     
        .state_in(state_reg),
        .round_key(selected_round_key),
        .state_out(normal_round_state)
        
     );
     
     wire [127:0] final_round_state;


    aes_final_round u_final_round (
        .state_in(state_reg),
        .round_key(selected_round_key),
        .state_out(final_round_state)
    );
    
    always @(posedge clk) begin
    
        if(rst) begin
            
            state_reg <= 128'h0;
            ciphertext <= 128'h0;
        end
        
        else begin
        
            if(initial_add_key) begin
                
                state_reg <= initial_state;
            end
        
        else if (round_enable) begin
        
            state_reg <= normal_round_state;
        end
        
        else if (final_round_enable) begin
            
            state_reg <= final_round_state;
            ciphertext <= final_round_state;
        end
     end
 end
 
endmodule


    
        
        
     
        
                
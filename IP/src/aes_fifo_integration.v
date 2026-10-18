`timescale 1ns / 1ps

module aes_fifo_integration (

    // FIFO WRITE SIDE

    input wire wr_clk,
    input wire wr_rst,
    input wire wr_en,
    input wire [127:0] din,

    output wire full,
    output wire almost_full,
    output wire prog_full,

    // FIFO READ SIDE

    input wire rd_clk,
    input wire rd_rst,
    input wire rd_en,

    output wire [127:0] dout,
    output wire empty,
    output wire almost_empty,
    output wire prog_empty,

    // FIFO ECC STATUS

    output wire ecc_single_error,
    output wire ecc_double_error,

    // AES INTERFACE

    input wire aes_start,
    input wire [127:0] aes_key,

    output wire [127:0] ciphertext,
    output wire aes_busy,
    output wire aes_done

);

    //Existing reusable FIFO IP

    fifo_system #(
        .DATA_WIDTH(128),
        .PARITY_BITS(8),
        .DEPTH(16)
    ) u_fifo (

        .wr_clk(wr_clk),
        .wr_rst(wr_rst),
        .wr_en(wr_en),
        .din(din),

        .rd_clk(rd_clk),
        .rd_rst(rd_rst),
        .rd_en(rd_en),

        .dout(dout),
        .full(full),
        .empty(empty),

        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .prog_full(prog_full),
        .prog_empty(prog_empty),

        .ecc_single_error(ecc_single_error),
        .ecc_double_error(ecc_double_error)

    );

    // FIFO -> AES BUFFER
   
    reg [127:0] plaintext_reg;

    always @(posedge rd_clk) begin

        if (rd_rst) begin
            plaintext_reg <= 128'h0;
        end

        else begin

            if (rd_en && !empty)
                plaintext_reg <= dout;

        end

    end

    // AES-128 ENCRYPTION CORE

    aes128_encrypt u_aes (

        .clk (rd_clk),
        .rst(rd_rst),
        .start(aes_start),

        .plaintext(plaintext_reg),
        .key(aes_key),
        .ciphertext(ciphertext),

        .busy(aes_busy),
        .done(aes_done)

    );


endmodule
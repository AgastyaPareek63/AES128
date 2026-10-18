`timescale 1ns / 1ps

module aes_axi_lite #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)(
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    // AXI4-Lite WRITE ADDRESS CHANNEL

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire S_AXI_AWVALID,
    output reg S_AXI_AWREADY,

    // AXI4-Lite WRITE DATA CHANNEL

    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output reg S_AXI_WREADY,

    // AXI4-Lite WRITE RESPONSE CHANNEL

    output reg [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,

    // AXI4-Lite READ ADDRESS CHANNEL

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,

    // AXI4-Lite READ DATA CHANNEL

    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY,

    // AES INTERFACE

    output wire [127:0] plaintext,
    output wire [127:0] key,
    output wire start
);

    // REGISTER STORAGE

    // Plaintext:
    // plaintext_reg[0] = [127:96]
    // plaintext_reg[1] = [95:64]
    // plaintext_reg[2] = [63:32]
    // plaintext_reg[3] = [31:0]

    reg [31:0] plaintext_reg [0:3];

    // Key:
    // key_reg[0] = [127:96]
    // key_reg[1] = [95:64]
    // key_reg[2] = [63:32]
    // key_reg[3] = [31:0]
    //
    reg [31:0] key_reg [0:3];

    // Ciphertext:
    // ciphertext_reg[0] = [127:96]
    // ciphertext_reg[1] = [95:64]
    // ciphertext_reg[2] = [63:32]
    // ciphertext_reg[3] = [31:0]
    //
    reg [31:0] ciphertext_reg [0:3];

    // CONTROL / STATUS REGISTERS

    // One-clock AES start pulse
    reg start_pulse;

    // Sticky DONE bit
    reg done_reg;

    // AXI WRITE HOLDING REGISTERS

    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg;

    reg [C_S_AXI_DATA_WIDTH-1:0] wdata_reg;

    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_reg;

    reg awaddr_valid;
    reg wdata_valid;

    // AES CORE SIGNALS

    wire [127:0] aes_ciphertext;
    wire aes_busy;
    wire aes_done;

    integer i;

    // 128-BIT PLAINTEXT BUS

    assign plaintext = {
        plaintext_reg[0],
        plaintext_reg[1],
        plaintext_reg[2],
        plaintext_reg[3]
    };

    // 128-BIT KEY BUS

    assign key = {
        key_reg[0],
        key_reg[1],
        key_reg[2],
        key_reg[3]
    };

    // AES START OUTPUT

    assign start = start_pulse;

    // AES-128 ENCRYPTION CORE

    aes128_encrypt aes_core (

        .clk(S_AXI_ACLK),
        .rst(~S_AXI_ARESETN),

        .start(start_pulse),

        .plaintext(plaintext),
        .key(key),

        .ciphertext(aes_ciphertext),

        .busy(aes_busy),
        .done(aes_done)

    );

    // AXI4-LITE WRITE CHANNEL

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            // AXI signals

            S_AXI_AWREADY <= 1'b1;
            S_AXI_WREADY <= 1'b1;

            S_AXI_BRESP <= 2'b00;
            S_AXI_BVALID <= 1'b0;

            // AXI holding registers

            awaddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};

            wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};

            wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};

            awaddr_valid <= 1'b0;
            wdata_valid <= 1'b0;

            // Control

            start_pulse <= 1'b0;
            done_reg <= 1'b0;

            // Data registers

            for (i = 0; i < 4; i = i + 1) begin

                plaintext_reg[i] <= 32'h00000000;
                key_reg[i] <= 32'h00000000;
                ciphertext_reg[i] <= 32'h00000000;

            end

        end
        else begin

            // START DEFAULT
            // START is a one-clock pulse.

            start_pulse <= 1'b0;

            // CAPTURE WRITE ADDRESS

            if (S_AXI_AWVALID && S_AXI_AWREADY) begin

                awaddr_reg <= S_AXI_AWADDR;
                awaddr_valid <= 1'b1;
                S_AXI_AWREADY <= 1'b0;

            end

            // CAPTURE WRITE DATA

            if (S_AXI_WVALID && S_AXI_WREADY) begin

                wdata_reg <= S_AXI_WDATA;
                wstrb_reg <= S_AXI_WSTRB;
                wdata_valid <= 1'b1;

                S_AXI_WREADY <= 1'b0;

            end

            // EXECUTE WRITE
            //
            // AXI address and AXI data can arrive independently.
            // The write executes only after both are captured.

            if (awaddr_valid && wdata_valid) begin

                case (awaddr_reg)

                    // CONTROL REGISTER
                    // bit 0x00 = START

                    6'h00: begin

                        if (wstrb_reg[0] && wdata_reg[0]) begin

                            // Generate one-clock start pulse
                            start_pulse <= 1'b1;

                            // New encryption transaction clears previous DONE
                            done_reg <= 1'b0;

                        end

                    end

                    // PLAINTEXT [127:96]
                    // 0x10

                    6'h10: begin

                        if (wstrb_reg[0])
                            plaintext_reg[0][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            plaintext_reg[0][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            plaintext_reg[0][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            plaintext_reg[0][31:24] <= wdata_reg[31:24];

                    end

                    // PLAINTEXT [95:64]
                    // 0x14

                    6'h14: begin

                        if (wstrb_reg[0])
                            plaintext_reg[1][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            plaintext_reg[1][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            plaintext_reg[1][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            plaintext_reg[1][31:24] <= wdata_reg[31:24];

                    end

                    // PLAINTEXT [63:32]
                    // 0x18

                    6'h18: begin

                        if (wstrb_reg[0])
                            plaintext_reg[2][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            plaintext_reg[2][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            plaintext_reg[2][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            plaintext_reg[2][31:24] <= wdata_reg[31:24];

                    end

                    // PLAINTEXT [31:0]
                    // 0x1C

                    6'h1C: begin

                        if (wstrb_reg[0])
                            plaintext_reg[3][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            plaintext_reg[3][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            plaintext_reg[3][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            plaintext_reg[3][31:24] <= wdata_reg[31:24];

                    end

                    // KEY [127:96]
                    // 0x20

                    6'h20: begin

                        if (wstrb_reg[0])
                            key_reg[0][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            key_reg[0][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            key_reg[0][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            key_reg[0][31:24] <= wdata_reg[31:24];

                    end

                    // KEY [95:64]
                    // 0x24

                    6'h24: begin

                        if (wstrb_reg[0])
                            key_reg[1][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            key_reg[1][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            key_reg[1][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            key_reg[1][31:24] <= wdata_reg[31:24];

                    end

                    // KEY [63:32]
                    // 0x28

                    6'h28: begin

                        if (wstrb_reg[0])
                            key_reg[2][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            key_reg[2][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            key_reg[2][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            key_reg[2][31:24] <= wdata_reg[31:24];

                    end

                    // KEY [31:0]
                    // 0x2C

                    6'h2C: begin

                        if (wstrb_reg[0])
                            key_reg[3][7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            key_reg[3][15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            key_reg[3][23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            key_reg[3][31:24] <= wdata_reg[31:24];

                    end

                    // Undefined write address

                    default: begin

                    end

                endcase

                // Clear captured transaction

                awaddr_valid <= 1'b0;
                wdata_valid <= 1'b0;

                // Ready for next transaction
                S_AXI_AWREADY <= 1'b1;
                S_AXI_WREADY <= 1'b1;

                // Successful AXI response
                S_AXI_BRESP <= 2'b00;
                S_AXI_BVALID <= 1'b1;

            end

            // WRITE RESPONSE HANDSHAKE

            if (S_AXI_BVALID && S_AXI_BREADY) begin

                S_AXI_BVALID <= 1'b0;

            end

            // AES COMPLETION

            if (aes_done) begin

                // Sticky DONE
                done_reg <= 1'b1;

                // Capture 128-bit ciphertext
                ciphertext_reg[0] <= aes_ciphertext[127:96];

                ciphertext_reg[1] <= aes_ciphertext[95:64];

                ciphertext_reg[2] <= aes_ciphertext[63:32];

                ciphertext_reg[3] <= aes_ciphertext[31:0];

            end

        end

    end

    // AXI4-LITE READ CHANNEL

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            S_AXI_ARREADY <= 1'b1;

            S_AXI_RDATA <= 32'h00000000;

            S_AXI_RRESP <= 2'b00;

            S_AXI_RVALID <= 1'b0;

        end
        else begin

            // COMPLETE PREVIOUS READ

            if (S_AXI_RVALID && S_AXI_RREADY) begin

                S_AXI_RVALID <= 1'b0;

                S_AXI_ARREADY <= 1'b1;

            end

            // ACCEPT READ ADDRESS

            if (S_AXI_ARVALID && S_AXI_ARREADY) begin

                case (S_AXI_ARADDR)

                    // CONTROL
                    // bit 0x00 = current START pulse

                    6'h00: begin

                        S_AXI_RDATA <= {31'b0,start_pulse};

                    end

                    // STATUS
                    // 0x04
                    // bit 0 = BUSY
                    // bit 1 = DONE

                    6'h04: begin

                        S_AXI_RDATA <= {30'b0, done_reg, aes_busy};

                    end

                    // PLAINTEXT

                    6'h10: begin
                        S_AXI_RDATA <= plaintext_reg[0];
                    end

                    6'h14: begin
                        S_AXI_RDATA <= plaintext_reg[1];
                    end

                    6'h18: begin
                        S_AXI_RDATA <= plaintext_reg[2];
                    end

                    6'h1C: begin
                        S_AXI_RDATA <= plaintext_reg[3];
                    end

                    // KEY

                    6'h20: begin
                        S_AXI_RDATA <= key_reg[0];
                    end

                    6'h24: begin
                        S_AXI_RDATA <= key_reg[1];
                    end

                    6'h28: begin
                        S_AXI_RDATA <= key_reg[2];
                    end

                    6'h2C: begin
                        S_AXI_RDATA <= key_reg[3];
                    end

                    // CIPHERTEXT

                    6'h30: begin
                        S_AXI_RDATA <= ciphertext_reg[0];
                    end

                    6'h34: begin
                        S_AXI_RDATA <= ciphertext_reg[1];
                    end

                    6'h38: begin
                        S_AXI_RDATA <= ciphertext_reg[2];
                    end

                    6'h3C: begin
                        S_AXI_RDATA <= ciphertext_reg[3];
                    end

                    // Undefined read address

                    default: begin

                        S_AXI_RDATA <= 32'h00000000;

                    end

                endcase

                // Successful AXI read
                S_AXI_RRESP <= 2'b00;
                S_AXI_RVALID <= 1'b1;

                // Do not accept another address until current read response is accepted
                S_AXI_ARREADY <= 1'b0;

            end

        end

    end

endmodule
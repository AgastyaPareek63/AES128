`timescale 1ns / 1ps

module aes_axi_fifo #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)(
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    // AXI4-Lite WRITE ADDRESS

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire S_AXI_AWVALID,
    output reg S_AXI_AWREADY,

    // AXI4-Lite WRITE DATA

    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output reg S_AXI_WREADY,

    // AXI4-Lite WRITE RESPONSE

    output reg [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,

    // AXI4-Lite READ ADDRESS

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,

    // AXI4-Lite READ DATA

    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // AXI REGISTERS

    reg [31:0] plaintext_reg [0:3];
    reg [31:0] key_reg [0:3];

    reg [31:0] ciphertext_reg [0:3];

    // AXI WRITE HOLDING REGISTERS

    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg;

    reg [C_S_AXI_DATA_WIDTH-1:0] wdata_reg;

    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_reg;

    reg awaddr_valid;
    reg wdata_valid;

    // CONTROL

    reg start_pulse;

    // STATUS

    reg done_reg;

    // FIFO CONTROL

    reg fifo_wr_en;
    reg fifo_rd_en;

    wire [127:0] fifo_din;
    wire [127:0] fifo_dout;

    wire fifo_full;
    wire fifo_empty;

    wire fifo_almost_full;
    wire fifo_almost_empty;
    wire fifo_prog_full;
    wire fifo_prog_empty;

    wire fifo_ecc_single_error;
    wire fifo_ecc_double_error;

    // AES CONTROL

    reg aes_start;

    wire [127:0] aes_ciphertext;
    wire aes_busy;
    wire aes_done;

    // FIFO -> AES CONTROL FSM

    localparam FIFO_IDLE = 3'd0;
    localparam FIFO_WRITE = 3'd1;
    localparam FIFO_WAIT_DATA = 3'd2;
    localparam FIFO_READ = 3'd3;
    localparam FIFO_AES_WAIT = 3'd4;
    localparam FIFO_DONE = 3'd5;

    reg [2:0] fifo_state;

    // FIFO / AES CLOCK DOMAIN
    // AXI clock is used for both sides in this integration.
    // 128-BIT PLAINTEXT

    assign fifo_din = {
        plaintext_reg[0],
        plaintext_reg[1],
        plaintext_reg[2],
        plaintext_reg[3]
    };

    // FIFO -> AES INTEGRATION

    aes_fifo_integration u_aes_fifo_integration (

        .wr_clk(S_AXI_ACLK),
        .wr_rst(~S_AXI_ARESETN),
        .wr_en(fifo_wr_en),
        .din(fifo_din),

        .full(fifo_full),
        .almost_full(fifo_almost_full),
        .prog_full(fifo_prog_full),

        .rd_clk(S_AXI_ACLK),
        .rd_rst(~S_AXI_ARESETN),
        .rd_en(fifo_rd_en),

        .dout(fifo_dout),
        .empty(fifo_empty),
        .almost_empty(fifo_almost_empty),
        .prog_empty(fifo_prog_empty),

        .ecc_single_error(fifo_ecc_single_error),
        .ecc_double_error(fifo_ecc_double_error),

        .aes_start(aes_start),
        .aes_key({
            key_reg[0],
            key_reg[1],
            key_reg[2],
            key_reg[3]
        }),

        .ciphertext(aes_ciphertext),
        .aes_busy(aes_busy),
        .aes_done(aes_done)
    );

    // AXI WRITE + FIFO/AES CONTROL

    integer i;

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            // AXI

            S_AXI_AWREADY <= 1'b1;
            S_AXI_WREADY <= 1'b1;

            S_AXI_BRESP <= 2'b00;
            S_AXI_BVALID <= 1'b0;

            awaddr_reg <= 6'h00;
            wdata_reg <= 32'h00000000;
            wstrb_reg <= 4'h0;

            awaddr_valid <= 1'b0;
            wdata_valid <= 1'b0;

            // Control

            start_pulse <= 1'b0;

            // FIFO

            fifo_wr_en <= 1'b0;
            fifo_rd_en <= 1'b0;
            fifo_state <= FIFO_IDLE;

            // AES

            aes_start <= 1'b0;

            // Status

            done_reg <= 1'b0;

            // Registers

            for (i = 0; i < 4; i = i + 1) begin

                plaintext_reg[i] <= 32'h00000000;
                key_reg[i] <= 32'h00000000;
                ciphertext_reg[i] <= 32'h00000000;

            end

        end
        else begin

            // DEFAULT 1-CYCLE PULSES

            start_pulse <= 1'b0;
            fifo_wr_en <= 1'b0;
            fifo_rd_en <= 1'b0;
            aes_start <= 1'b0;

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

            // EXECUTE AXI WRITE

            if (awaddr_valid && wdata_valid) begin

                case (awaddr_reg)

                    // CONTROL
                    // 0x00
                    // bit 0 = START

                    6'h00: begin

                        if (wstrb_reg[0] && wdata_reg[0]) begin

                            start_pulse <= 1'b1;
                            done_reg <= 1'b0;

                        end

                    end

                    // PLAINTEXT WORD 0

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

                    // PLAINTEXT WORD 1

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

                    // PLAINTEXT WORD 2

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

                    // PLAINTEXT WORD 3

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

                    // KEY WORD 0

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

                    // KEY WORD 1

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

                    // KEY WORD 2

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

                    // KEY WORD 3

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

                    default: begin
                    end

                endcase

                // Complete AXI write

                awaddr_valid <= 1'b0;
                wdata_valid <= 1'b0;

                S_AXI_AWREADY <= 1'b1;
                S_AXI_WREADY <= 1'b1;

                S_AXI_BRESP <= 2'b00;
                S_AXI_BVALID <= 1'b1;

            end

            // WRITE RESPONSE

            if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end

            // FIFO/AES SEQUENCER

            case (fifo_state)

                // IDLE

                FIFO_IDLE: begin

                    if (start_pulse) begin

                        fifo_state <= FIFO_WRITE;

                    end

                end

                // WRITE PLAINTEXT INTO FIFO

                FIFO_WRITE: begin

                    if (!fifo_full) begin

                        fifo_wr_en <= 1'b1;

                        fifo_state <= FIFO_WAIT_DATA;

                    end

                end

                // WAIT UNTIL FIFO DATA IS AVAILABLE

                FIFO_WAIT_DATA: begin

                    if (!fifo_empty) begin

                        fifo_state <= FIFO_READ;

                    end

                end

                // READ FIFO

                FIFO_READ: begin

                    if (!fifo_empty) begin

                        fifo_rd_en <= 1'b1;

                        fifo_state <= FIFO_AES_WAIT;

                    end

                end

                // WAIT FOR FIFO DATA TO REACH AES

                FIFO_AES_WAIT: begin

                    // The existing aes_fifo_integration contains the FIFO -> plaintext register settling logic.

                    aes_start <= 1'b1;
                    fifo_state <= FIFO_DONE;

                end

                // WAIT FOR AES COMPLETION

                FIFO_DONE: begin

                    if (aes_done) begin

                        ciphertext_reg[0] <= aes_ciphertext[127:96];

                        ciphertext_reg[1] <= aes_ciphertext[95:64];

                        ciphertext_reg[2] <= aes_ciphertext[63:32];

                        ciphertext_reg[3] <= aes_ciphertext[31:0];

                        done_reg <= 1'b1;

                        fifo_state <= FIFO_IDLE;

                    end

                end

                default: begin

                    fifo_state <= FIFO_IDLE;

                end

            endcase

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

            // Complete current read

            if (S_AXI_RVALID && S_AXI_RREADY) begin

                S_AXI_RVALID <= 1'b0;
                S_AXI_ARREADY <= 1'b1;

            end

            // Accept read address

            if (S_AXI_ARVALID && S_AXI_ARREADY) begin

                case (S_AXI_ARADDR)

                    // CONTROL

                    6'h00: begin

                        S_AXI_RDATA <= { 31'b0,start_pulse};

                    end

                    // STATUS
                    // bit 0 = AES BUSY
                    // bit 1 = AES DONE
                    // bit 2 = FIFO EMPTY
                    // bit 3 = FIFO FULL
                    // bit 4 = ECC SINGLE ERROR
                    // bit 5 = ECC DOUBLE ERROR

                    6'h04: begin

                        S_AXI_RDATA <= {
                            26'b0,
                            fifo_ecc_double_error,
                            fifo_ecc_single_error,
                            fifo_full,
                            fifo_empty,
                            done_reg,
                            aes_busy
                        };

                    end

                    // PLAINTEXT

                    6'h10:
                        S_AXI_RDATA <= plaintext_reg[0];

                    6'h14:
                        S_AXI_RDATA <= plaintext_reg[1];

                    6'h18:
                        S_AXI_RDATA <= plaintext_reg[2];

                    6'h1C:
                        S_AXI_RDATA <= plaintext_reg[3];

                    // KEY

                    6'h20:
                        S_AXI_RDATA <= key_reg[0];

                    6'h24:
                        S_AXI_RDATA <= key_reg[1];

                    6'h28:
                        S_AXI_RDATA <= key_reg[2];

                    6'h2C:
                        S_AXI_RDATA <= key_reg[3];

                    // CIPHERTEXT

                    6'h30:
                        S_AXI_RDATA <= ciphertext_reg[0];

                    6'h34:
                        S_AXI_RDATA <= ciphertext_reg[1];

                    6'h38:
                        S_AXI_RDATA <= ciphertext_reg[2];

                    6'h3C:
                        S_AXI_RDATA <= ciphertext_reg[3];

                    default:
                        S_AXI_RDATA <= 32'h00000000;

                endcase

                S_AXI_RRESP <= 2'b00;
                S_AXI_RVALID <= 1'b1;
                S_AXI_ARREADY <= 1'b0;

            end

        end

    end

endmodule